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

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Leds;
uses interface Timer<TMilli>;

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
	dbgs(process, F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0, 0);
	dbg("Application", "[%d] Counter SplitControl.start()", process);

	dbg("Application", "[%d] Counter starting delay: %d", process, send_delay);
	dbg("Application", "[%d] Counter starting src: %d  dest: %d", process,
		call CounterParams.get_src(), call CounterParams.get_dest());
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
	dbg("Application", "[%d] Counter SplitControl.stop()", process);
	dbgs(process, F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0, 0);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

void sendMessage() {
	CounterMsg* msg = (CounterMsg*)call NetworkAMSend.getPayload(&packet,
							sizeof(CounterMsg));
	if (msg == NULL) {
		return;
	}

	msg->source = TOS_NODE_ID;
	msg->seqno = seqno;


	if (call NetworkAMSend.send(call CounterParams.get_dest(), &packet, 
					sizeof(CounterMsg)) != SUCCESS) {
		dbgs(process, F_APPLICATION, S_ERROR, DBGS_SEND_DATA, seqno,
					call CounterParams.get_dest(), sizeof(CounterMsg));
		dbg("Application", "[%d] Counter sendMessage() seqno: %d source: %d - FAILED", 
					process, msg->seqno, msg->source); 
	} else {
		sendBusy = TRUE;
		dbgs(process, F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno,
					call CounterParams.get_dest(), sizeof(CounterMsg));
		dbg("Application", "[%d] Counter call NetworkAMSend.send(%d, 0x%1x, %d)",
					process, 
					call CounterParams.get_dest(), &packet,
					sizeof(CounterMsg));
		call Leds.set(seqno);
	}
}

event void Timer.fired() {
	if (!sendBusy) {
		printf("sending seq: %d\n", seqno);
		dbg("Application", "[%d] Counter Timer.fired()", process);
		sendMessage();
	}
	seqno++;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	//CounterMsg* cm = (CounterMsg*)call NetworkAMSend.getPayload(msg,
	//						sizeof(CounterMsg));
	dbg("Application", "[%d] Counter event NetworkAMSend.sendDone(0x%1x, %d)",
				process, msg, error);
	sendBusy = FALSE;
}


event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	CounterMsg* cm = (CounterMsg*)payload;

	dbg("Application", "[%d] Counter event NetworkReceive.receive(0x%1x, 0x%1x, %d)",
				process,  msg, payload, len); 
	dbg("Application", "[%d] Counter receive seqno: %d source: %d", 
				process, cm->seqno, cm->source); 

	call Leds.set(cm->seqno);
	dbgs(process, F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, cm->seqno, cm->source, len);
	printf("receive %d %d\n", cm->seqno, cm->source);
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

}
