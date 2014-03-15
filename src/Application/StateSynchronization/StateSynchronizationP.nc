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

generic module StateSynchronizationP(process_t process) @safe() {
provides interface SplitControl;

uses interface StateSynchronizationParams;
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Fennec;
uses interface FennecState;

uses interface Random;
uses interface Timer<TMilli> as Timer;
uses interface Leds;
}

implementation {

message_t packet;

task void schedule_send_msg() {
	call Timer.startOneShot(call Random.rand16() % 
		call StateSynchronizationParams.get_send_delay() + 1);
}

task void send_msg() {
	nx_struct fennec_network_state *state_msg;
	dbg("StateSynchronization", "[%d] StateSynchronizationP send_state_sync_msg()", process);

	state_msg = (nx_struct fennec_network_state*) 
	call NetworkAMSend.getPayload(&packet, sizeof(nx_struct fennec_network_state));
   
	if (state_msg == NULL) {
		post schedule_send_msg();
		return;
	}

	state_msg->seq = (nx_uint16_t) call Fennec.getStateSeq();
	state_msg->state_id = (nx_uint8_t) call Fennec.getStateId();

	if (call NetworkAMSend.send(BROADCAST, &packet, sizeof(nx_struct fennec_network_state)) != SUCCESS) {
		post schedule_send_msg();
		dbg("StateSynchronization", "[%d] StateSynchronizationP send_state_sync_msg() - FAIL", process);
	} else {
		dbg("StateSynchronization", "[%d] StateSynchronizationP send_state_sync_msg() - SUCCESS", process);
	}
}


async event void FennecState.resend() {
	post send_msg();
}

command error_t SplitControl.start() {
	dbg("StateSynchronization", "[%d] StateSynchronizationP SplitControl.start()", process);
	post send_msg();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("StateSynchronization", "[%d] StateSynchronizationP SplitControl.stop()", process);
	call Timer.stop();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct fennec_network_state *state_msg = (nx_struct fennec_network_state*) payload;
	dbg("StateSynchronization", "[%d] StateSynchronizationP NetworkReceive.receive(0x%1x, 0x%1x, %d)",
		process, msg, payload, len);

	call Fennec.setStateAndSeq(state_msg->state_id, state_msg->seq);
	return msg;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
}

event void Timer.fired() {
	dbg("StateSynchronization", "[%d] StateSynchronizationP Timer.fired()", process);
	post send_msg();
}


event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct fennec_network_state *state_msg = (nx_struct fennec_network_state*) payload;
	call Fennec.setStateAndSeq(state_msg->state_id, state_msg->seq);
	return msg;
}

}
