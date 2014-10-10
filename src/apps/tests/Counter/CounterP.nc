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
uses interface Timer<TMilli>;

uses interface SerialDbgs;
}

implementation {

uint16_t delay;
uint16_t delay_scale;
uint16_t src;
uint16_t dest;

message_t packet;
uint16_t seqno;

command error_t SplitControl.start() {
	uint32_t send_delay;

	call Param.get(SRC, &src, sizeof(src));
	call Param.get(DELAY, &delay, sizeof(delay));
	call Param.get(DELAY_SCALE, &delay_scale, sizeof(delay_scale));

	send_delay = delay;
	send_delay *= delay_scale;

	seqno = 0;

	if ((src == BROADCAST) || (src == TOS_NODE_ID)) {
		call Timer.startPeriodic(send_delay);
	}

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Counter start()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
#endif
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Counter stop()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

task void sendMessage() {
	error_t e;
	CounterMsg* msg = (CounterMsg*)call SubAMSend.getPayload(&packet,
							sizeof(CounterMsg));
	if (msg == NULL) {
		return;
	}

	msg->source = TOS_NODE_ID;
	msg->seqno = seqno;

	call Param.get(DEST, &dest, sizeof(dest));
	e = call SubAMSend.send(dest, &packet, sizeof(CounterMsg));
	if (e != SUCCESS) {
		signal SubAMSend.sendDone(&packet, e);
	}
}

event void Timer.fired() {
	seqno++;
	//printf("fired %u\n", seqno);
	post sendMessage();
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	call Leds.set(seqno);
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Counter SendDone Error: %d  Seqno: %d  Dest: %d\n", process, error, seqno, dest);
#else
	call Param.get(DEST, &dest, sizeof(dest));
	call SerialDbgs.dbgs(DBGS_SEND_DATA, error, seqno, dest);
#endif
#endif
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	CounterMsg* cm = (CounterMsg*)payload;
	call Leds.set(cm->seqno);
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Application Counter Receive Len: %d  Seqno: %d  Source: %d\n", process, len, cm->seqno, cm->source);
#else
	call SerialDbgs.dbgs(DBGS_RECEIVE_DATA, len, cm->seqno, cm->source);
#endif
#endif
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id) {

}

}
