/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox Data Synchronizarion Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include <Fennec.h>
#include "hashing.h"

#define DATA_CONFLICT_RAND_OFFSET	10

generic module BEDSP(process_t process) @safe() {
provides interface SplitControl;

uses interface Param;
uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;
uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;

uses interface FennecData;
uses interface Random; 
uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

uint16_t send_delay;
message_t packet;
nx_uint8_t data_sequence;
nx_uint16_t data_crc;
nx_struct BEDS_data *data_msg = NULL;

#define MAX_HIST_VARS	20
nx_uint8_t var_hist[MAX_HIST_VARS];

nx_struct BEDS_data received_copy;

task void schedule_send() {
	call Param.get(SEND_DELAY, &send_delay, sizeof(send_delay));
	call Timer.startOneShot(send_delay / 2 + (call Random.rand16() % send_delay) + 1);
}

task void send_msg() {
	data_msg = call SubAMSend.getPayload(&packet, call FennecData.getNxDataLen() + 4);
   
	if (data_msg == NULL) {
		signal SubAMSend.sendDone(&packet, FAIL);
		return;
	}

	data_msg->sequence = data_sequence;
	data_msg->data_crc = data_crc;

	call FennecData.load(data_msg->data);
	memcpy(data_msg->var_hist, &var_hist, call FennecData.getNumOfGlobals());
	data_msg->packet_crc = (nx_uint16_t) crc16(0, (uint8_t*) data_msg,
                sizeof(nx_struct BEDS_data) -
                sizeof(((nx_struct BEDS_data *)0)->packet_crc));

	if (call SubAMSend.send(BROADCAST, &packet, sizeof(nx_struct BEDS_data))  != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	}
}

void resend(bool immediate) {
	if (immediate) {
		call Timer.stop();
		post send_msg();
	} else {
		post schedule_send();
	}
}

command error_t SplitControl.start() {
	uint8_t i;
	for (i = 0; i < MAX_HIST_VARS; i++) {
		var_hist[i] = 0;
	}
	data_sequence = 0;
	data_crc = 0;
	post schedule_send();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}



task void process_receive() {
	nx_struct BEDS_data *in_data_msg = &received_copy;
	uint8_t i;

	for (i = 0; i < call FennecData.getNumOfGlobals(); i++) {	
		if (((in_data_msg->var_hist[i] >= var_hist[i]) && ((in_data_msg->var_hist[i] - var_hist[i]) < BEDS_WRAPPER)) || 
				/* wrap around */
			((var_hist[i] >= in_data_msg->var_hist[i]) && ((var_hist[i] - in_data_msg->var_hist[i]) > BEDS_WRAPPER))) {

			if (call FennecData.matchData(in_data_msg->data, i) != SUCCESS) {
				if (var_hist[i] == in_data_msg->var_hist[i]) {
					/* conflict: same sequence but different data */
					var_hist[i] += (call Random.rand16() % BEDS_RANDOM_INCREASE);
					if (((var_hist[i] > data_sequence) && (var_hist[i] - data_sequence) < BEDS_WRAPPER) ||
							/* wrap around */ 
						((data_sequence > var_hist[i]) && ((data_sequence - var_hist[i]) > BEDS_WRAPPER))) {
						data_sequence = var_hist[i];
					}
					call FennecData.update(in_data_msg->data, i, TRUE);
				} else {
					var_hist[i] = in_data_msg->var_hist[i];
					call FennecData.update(in_data_msg->data, i, FALSE);
				}
			} else {
				var_hist[i] = in_data_msg->var_hist[i];
			}
		}
	}

	if (((in_data_msg->sequence > data_sequence) && (in_data_msg->sequence - data_sequence) < BEDS_WRAPPER) ||
				/* wrap around */ 
		((data_sequence > in_data_msg->sequence) && ((data_sequence - in_data_msg->sequence) > BEDS_WRAPPER))) {
		data_sequence = in_data_msg->sequence;
	}

	data_crc = call FennecData.getDataCrc();
	resend(1);
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct BEDS_data *in_beds = (nx_struct BEDS_data*) payload;
	call Timer.stop();

	if (in_beds->data_crc == data_crc) {
		return msg;
	}

	if (in_beds->packet_crc != (nx_uint16_t) crc16(0, (uint8_t*) in_beds,
		sizeof(nx_struct BEDS_data) - sizeof(((nx_struct BEDS_data *)0)->packet_crc)) ) {
		return msg;
	}

	memcpy(&received_copy, payload, sizeof(nx_struct BEDS_data));
	post process_receive();
	return msg;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
}

event void Timer.fired() {
	post send_msg();
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id, bool conflict) {
}

event void FennecData.updated(uint8_t global_id, uint8_t var_index) {
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
#endif
#endif
	data_sequence++;
	var_hist[var_index] = data_sequence;
	data_crc = call FennecData.getDataCrc();
	resend(1);
}

event void FennecData.resend() {
	resend(0);
}


}
