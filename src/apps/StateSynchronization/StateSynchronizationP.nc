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
  * Fennec Fox State Synchronizarion Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


#include <Fennec.h>
#include "hashing.h"

generic module StateSynchronizationP(process_t process) @safe() {
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

uses interface FennecState;
uses interface Random;

uses interface SerialDbgs;

uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

uint16_t send_delay;
message_t packet;

task void schedule_send() {
	call Param.get(SEND_DELAY, &send_delay, sizeof(send_delay));
	call Timer.startOneShot((call Random.rand16() % send_delay) + 1);
}

task void send_msg() {
	nx_struct fennec_network_state *state_msg;

	state_msg = (nx_struct fennec_network_state*) 
	call SubAMSend.getPayload(&packet, sizeof(nx_struct fennec_network_state));
   
	if (state_msg == NULL) {
		signal SubAMSend.sendDone(&packet, FAIL);
		return;
	}

	state_msg->seq = (nx_uint16_t) call FennecState.getStateSeq();
	state_msg->state_id = (nx_uint16_t) call FennecState.getStateId();
	state_msg->crc = (nx_uint16_t) crc16(0, (uint8_t*) state_msg, 
		sizeof(nx_struct fennec_network_state) - 
		sizeof(((nx_struct fennec_network_state *)0)->crc));

#ifdef __DBGS__APPLICATION__
#ifdef __DBGS__STATE_SYNC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] Application StateSynchronization send_msg() [%u %u %u]\n", process,
		state_msg->seq, state_msg->state_id, state_msg->crc);
#else

#endif
#endif
#endif

	if (call SubAMSend.send(BROADCAST, &packet, sizeof(nx_struct fennec_network_state)) != SUCCESS) {
		signal SubAMSend.sendDone(&packet, FAIL);
	} else {

	}
}

event void FennecState.resend() {
	post send_msg();
}

command error_t SplitControl.start() {
	dbg("StateSynchronization", "[%d] StateSynchronizationP SplitControl.start()", process);

#ifdef __DBGS__APPLICATION__
#ifdef __DBGS__STATE_SYNC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application StateSynchronization start()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
#endif
#endif
	//post schedule_send();
	post send_msg();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("StateSynchronization", "[%d] StateSynchronizationP SplitControl.stop()", process);
	call Timer.stop();

#ifdef __DBGS__APPLICATION__
#ifdef __DBGS__STATE_SYNC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application StateSynchronization stop()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
#endif
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct fennec_network_state *state_msg = (nx_struct fennec_network_state*) payload;
	dbg("StateSynchronization", "[%d] StateSynchronizationP SubReceive.receive(0x%1x, 0x%1x, %d)",
		process, msg, payload, len);

	if (state_msg->crc != (nx_uint16_t) crc16(0, (uint8_t*) state_msg, 
		len - sizeof(((nx_struct fennec_network_state *)0)->crc)) ) {

#ifdef __DBGS__APPLICATION__
#ifdef __DBGS__STATE_SYNC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] Application StateSynchronization receive() - drop\n", process);
#else
#endif
#endif
#endif
		return msg;
	}

#ifdef __DBGS__APPLICATION__
#ifdef __DBGS__STATE_SYNC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application StateSynchronization receive()\n", process);
#else
#endif
#endif
#endif

	call FennecState.setStateAndSeq(state_msg->state_id, state_msg->seq);
	return msg;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
#ifdef __DBGS__APPLICATION__
#ifdef __DBGS__STATE_SYNC__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application StateSynchronization sendDone(%d)\n", process, error);
#else
//	call SerialDbgs.dbgs(DBGS_SEND_DATA, error, seqno, dest);
#endif
#endif
#endif
	call FennecState.resendDone(error);
}

event void Timer.fired() {
	post send_msg();
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct fennec_network_state *state_msg = (nx_struct fennec_network_state*) payload;
	call FennecState.setStateAndSeq(state_msg->state_id, state_msg->seq);
	return msg;
}

event void Param.updated(uint8_t var_id, bool conflict) {

}

}
