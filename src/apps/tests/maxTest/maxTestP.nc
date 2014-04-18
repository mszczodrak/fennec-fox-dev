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

uses interface maxTestParams;

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

uint32_t max_value = 0;
message_t packet;
bool send_busy = FALSE;

task void send_msg() {
	nx_struct maxMsg *out_msg = (nx_struct maxMsg*)
		call SubAMSend.getPayload(&packet, sizeof(nx_struct maxMsg));

	if (out_msg == NULL) {
		return;
	}

	out_msg->max_value = max_value;
	
	if (call SubAMSend.send(BROADCAST, &packet, 
			sizeof(nx_struct maxMsg)) != SUCCESS) {
		dbg("Application", "maxTest send_msg() - cannot send");
	} else {
//		dbg("Application", "maxTest send_msg() - max_value %d", max_value);
		send_busy = TRUE;
		call Leds.set(max_value);
	}
}


command error_t SplitControl.start() {
	dbg("Application", "maxTest SplitControl.start()");
	max_value = call maxTestParams.get_val();
	dbg("Application", "maxTest SplitControl.start() max_value is %d", max_value);

	send_busy = FALSE;

	if (call maxTestParams.get_delay() > 0) {
		call Timer.startPeriodic(call maxTestParams.get_delay());
	}

	dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, (uint16_t) (max_value >> 16), 
							(uint16_t) (max_value & 0x0000FFFFuL) );

	signal SplitControl.startDone(SUCCESS);
	post send_msg();
	return SUCCESS;
}


command error_t SplitControl.stop() {
	dbg("Application", "maxTest SplitControl.start()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


event void SubAMSend.sendDone(message_t *msg, error_t error) {
	send_busy = FALSE;
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct maxMsg *in_msg = (nx_struct maxMsg*) payload;
	if (in_msg->max_value > max_value) {
		max_value = in_msg->max_value;
		dbg("Application", "maxTest SubReceive.receive() - got new max: %d", max_value);
		post send_msg();
		dbgs(F_APPLICATION, S_RECEIVING, 0, (uint16_t) (max_value >> 16), 
							(uint16_t) (max_value & 0x0000FFFFuL) );
	}

	if (in_msg->max_value < max_value) {
		post send_msg();
	}

	return msg;
}


event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	if (call maxTestParams.get_val() != 0) {
		max_value = call Random.rand32();
	}
	dbg("Application", "maxTest Timer.fired() max_value is %d", max_value);
	dbgs(F_APPLICATION, S_INIT, 0, (uint16_t) (max_value >> 16), 
							(uint16_t) (max_value & 0x0000FFFFuL) );
	if (!send_busy) {
		post send_msg();
	}
}

}
