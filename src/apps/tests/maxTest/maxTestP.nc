/*
 * Copyright (c) 2013, Columbia University.
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
  * maxTest Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include "maxTest.h"

generic module maxTestP(process_t process) {
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

uses interface Random;
uses interface Leds;
uses interface Timer<TMilli>;
}

implementation {

message_t packet;
bool send_busy = FALSE;
uint32_t val;
uint32_t delay;

task void send_msg() {
	nx_struct maxMsg *out_msg = (nx_struct maxMsg*)
		call SubAMSend.getPayload(&packet, sizeof(nx_struct maxMsg));

	if (out_msg == NULL) {
		return;
	}

	out_msg->max_value = val;
	
	if (call SubAMSend.send(BROADCAST, &packet, 
			sizeof(nx_struct maxMsg)) != SUCCESS) {
	} else {
		send_busy = TRUE;
	}
}


command error_t SplitControl.start() {
	call Param.get(VAL, &val, sizeof(val));
	call Param.get(DELAY, &delay, sizeof(delay));

	send_busy = FALSE;

	if (delay > 0) {
		call Timer.startPeriodic(delay);
	}

	signal SplitControl.startDone(SUCCESS);
	post send_msg();
	return SUCCESS;
}


command error_t SplitControl.stop() {
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


event void SubAMSend.sendDone(message_t *msg, error_t error) {
	send_busy = FALSE;
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct maxMsg *in_msg = (nx_struct maxMsg*) payload;
	if (in_msg->max_value > val) {
		val = in_msg->max_value;
		post send_msg();
	}

	if (in_msg->max_value < val) {
		post send_msg();
	}

	return msg;
}


event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	call Param.get(VAL, &val, sizeof(val));
	if (val != 0) {
		val = call Random.rand32();
	}
	if (!send_busy) {
		post send_msg();
	}
}

}
