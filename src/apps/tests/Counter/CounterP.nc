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
  * Counter Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include <Timer.h>
#include "Counter.h"

generic module CounterP(process_t process) {
provides interface SplitControl;

uses interface CounterParams;

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
uses interface Timer<TMilli>;

uses interface SerialDbgs;

}

implementation {

/**
 Available Parameters:
	uint16_t delay,
	uint16_t delay_scale,
	uint16_t src,
	uint16_t dest
*/


message_t packet;
bool sendBusy = FALSE;
uint16_t seqno;

command error_t SplitControl.start() {
	uint32_t send_delay = call CounterParams.get_delay() * 
		call CounterParams.get_delay_scale();

	seqno = 0;
	sendBusy = FALSE;

	if ((call CounterParams.get_src() == BROADCAST) || 
	(call CounterParams.get_src() == TOS_NODE_ID)) {
		call Timer.startPeriodic(send_delay);
	}

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, 0, 0);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

void sendMessage() {
	CounterMsg* msg = (CounterMsg*)call SubAMSend.getPayload(&packet,
							sizeof(CounterMsg));
	if (msg == NULL) {
		return;
	}

	msg->source = TOS_NODE_ID;
	msg->seqno = seqno;

	if (call SubAMSend.send(call CounterParams.get_dest(), &packet, 
					sizeof(CounterMsg)) != SUCCESS) {
	} else {
		sendBusy = TRUE;
		call Leds.set(seqno);
	}
	call SerialDbgs.dbgs(DBGS_SEND_DATA, seqno, call CounterParams.get_dest());
}

event void Timer.fired() {
	if (!sendBusy) {
		dbg("Application", "[%d] Counter Timer.fired()", process);
		sendMessage();
	}
	seqno++;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	sendBusy = FALSE;
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	CounterMsg* cm = (CounterMsg*)payload;
	call Leds.set(cm->seqno);
	call SerialDbgs.dbgs(DBGS_RECEIVE_DATA, cm->seqno, cm->source);
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

}
