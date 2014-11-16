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

generic module DataSynchronizationP(process_t process) @safe() {
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
nx_uint16_t data_sequence;
nx_uint16_t data_crc;

task void schedule_send() {
	call Param.get(SEND_DELAY, &send_delay, sizeof(send_delay));
	call Timer.startOneShot(send_delay / 2 + (call Random.rand16() % send_delay) + 1);
}

task void send_msg() {
	nx_struct fennec_network_data *data_msg;
	dbg("DataSynchronization", "[%d] DataSynchronizationP send_data_sync_msg()", process);

	data_msg = call SubAMSend.getPayload(&packet, call FennecData.getNxDataLen() + 4);
   
	if (data_msg == NULL) {
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] DataSynchronizationP Got NULL ptr\n", process);
#endif
#endif
		signal SubAMSend.sendDone(&packet, FAIL);
		return;
	}

	data_msg->sequence = data_sequence;
	data_msg->crc = data_crc;
	call FennecData.load(data_msg->data);

	if (call SubAMSend.send(BROADCAST, &packet, sizeof(nx_struct fennec_network_data)) != SUCCESS) {
		dbg("DataSynchronization", "[%d] DataSynchronizationP send_data_sync_msg() - FAIL", process);
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {
		dbg("DataSynchronization", "[%d] DataSynchronizationP send_data_sync_msg() - SUCCESS", process);
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] DataSynchronizationP Send DataSync\n", process);
#endif
#endif
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
	data_sequence = 0;
	data_crc = 0;
	dbg("DataSynchronization", "[%d] DataSynchronizationP SplitControl.start()", process);
	post schedule_send();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("DataSynchronization", "[%d] DataSynchronizationP SplitControl.stop()", process);
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct fennec_network_data *data_msg = (nx_struct fennec_network_data*) payload;
	dbg("DataSynchronization", "[%d] DataSynchronizationP SubReceive.receive(0x%1x, 0x%1x, %d)",
		process, msg, payload, len);

	call Timer.stop();

	if (data_msg->crc == data_crc) {
		if (data_msg->sequence < data_sequence) {
			resend(0);
		}
		if (data_msg->sequence > data_sequence) {
			data_sequence = data_msg->sequence;
		} 
		return msg;
	}

	if (data_msg->sequence > data_sequence) {
		uint8_t i;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] DataSynchronizationP Syncing...\n", process);
#endif
#endif
		for (i = 0; i < call FennecData.getNumOfGlobals(); i++) {	
			call FennecData.update(data_msg->data, i);
		}
		data_sequence = data_msg->sequence;
		data_crc = call FennecData.getDataCrc();
		return msg;
	}

	if (data_msg->sequence < data_sequence) {
		resend(0);
		return msg;
	}

	/* conflict */
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] DataSynchronizationP Solving Conflict...\n", process);
#endif
#endif
	data_sequence += (call Random.rand16() % DATA_CONFLICT_RAND_OFFSET) + 1; 
	resend(1);
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

event void Param.updated(uint8_t var_id) {
}

event void FennecData.updated(uint8_t global_id) {
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] DataSynchronizationP  - Data updated...\n", process);
#endif
#endif
	data_sequence++;
	data_crc = call FennecData.getDataCrc();
	resend(1);
}

event void FennecData.resend() {
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] DataSynchronizationP  - resend request\n", process);
#endif
#endif
	resend(0);
}


}
