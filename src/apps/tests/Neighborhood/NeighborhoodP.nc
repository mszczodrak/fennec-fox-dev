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
  * Fennec Fox Neighborhood Application module
  *
  * @author: Marcin K Szczodrak
  * @updated: 05/22/2011
  */


#include <Fennec.h>
#include "Neighborhood.h"

generic module NeighborhoodP(process_t process) {
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

uses interface Leds;
uses interface Random;
uses interface Timer<TMilli> as SendTimer;
uses interface Timer<TMilli> as TestTimer;

uses interface SerialDbgs;
}

implementation {

message_t packet;

bool busy;
uint16_t seqno;

uint8_t min_size;
uint8_t radio_tx_power;
uint16_t tx_delay;

uint8_t neighborhood_in;	/* how many can I hear */
uint8_t neighborhood_out;	/* how many can hear me */

message_metadata_t* getMetadata(message_t *msg) {
	return (message_metadata_t*)msg->metadata;
}

task void reset_led_timer() {
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));
	call TestTimer.startOneShot(2 * tx_delay);
}

task void send_timer() {
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));
	call SendTimer.startOneShot( (call Random.rand16() % tx_delay) + 
			(tx_delay / 2) + 1);
}

void start_new_radio_tx_test() {
	busy = FALSE;
	seqno = 0;
	post send_timer();
}

command error_t SplitControl.start() {
	call Param.get(MIN_SIZE, &min_size, sizeof(min_size));
	call Param.get(RADIO_TX_POWER, &radio_tx_power, sizeof(radio_tx_power));
	call Param.get(TX_DELAY, &tx_delay, sizeof(tx_delay));

	start_new_radio_tx_test();
	
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	//int8_t rssi = (int8_t) call SubPacketRSSI.get(msg);

#ifdef FENNEC_TOS_PRINTF
	//int8_t lqi = (int8_t) call SubPacketLinkQuality.get(msg);
#endif

#ifdef __DBGS__APPLICATION__
	NeighborhoodMsg *m = (NeighborhoodMsg*) payload;
	call SerialDbgs.dbgs(DBGS_RECEIVE_BEACON, call SubAMPacket.source(msg),
		//call SubPacketRSSI.get(msg), call SubPacketLinkQuality.get(msg));
		call SubPacketRSSI.get(msg), m->seq);
#endif

	signal TestTimer.fired();

	call Leds.led0On();


	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SendTimer.fired() {
	NeighborhoodMsg *msg = (NeighborhoodMsg*) call SubAMSend.getPayload(&packet,
							sizeof(NeighborhoodMsg));
	if (msg != NULL && !busy) {
		busy = TRUE;
		call Param.get(RADIO_TX_POWER, &radio_tx_power, sizeof(radio_tx_power));
		msg->src = TOS_NODE_ID;
		msg->tx = radio_tx_power;
		msg->seq = ++seqno;
		call SubAMSend.send(BROADCAST, &packet, sizeof(NeighborhoodMsg));
	}

	post send_timer();
}

event void TestTimer.fired() {
	post reset_led_timer();
}

event void Param.updated(uint8_t var_id) {

}

}
