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
  * Fennec Fox timer event application module
  *
  * @author: Marcin K Szczodrak
  */


#include <Fennec.h>
#include "timerCalMilli.h"

generic module timerCalMilliP(process_t process) {
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

uses interface Event;
uses interface Timer<TMilli>;
}

implementation {

uint32_t delay;
uint16_t src;

float skew = 0;
uint32_t localAverage = 0;
int32_t offsetAverage = 0;

void local2Global(uint32_t *time) {
        *time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
}

void global2Local(uint32_t *time) {
        uint32_t approxLocalTime = *time - offsetAverage;
        *time = approxLocalTime - (int32_t)(skew * (int32_t)(approxLocalTime - localAverage));
}

command error_t SplitControl.start() {
	call Param.get(DELAY, &delay, sizeof(delay));
	call Param.get(SRC, &src, sizeof(src));

	call Param.get(SKEW, &skew, sizeof(skew));
	call Param.get(LOCALAVERAGE, &localAverage, sizeof(localAverage));
	call Param.get(OFFSETAVERAGE, &offsetAverage, sizeof(offsetAverage));

	dbg("Application", "[%d] timerCalMilli SplitControl.start()", process);
	dbg("Application", "[%d] timerCalMilli src: %d", process, src);

	printf("Timer orig delay is %lu\n", delay);

	if ((src == BROADCAST) || (src == TOS_NODE_ID)) {
//		uint32_t now = call Timer.getNow();
//		uint32_t now2 = now;
//		uint32_t now3;
//		uint32_t now4;
//		local2Global(&now2);
//		now3 = now2;
//		now3 += delay;
//		now4 = now3;
//		global2Local(&now4);
//		delay = now4 - now;
//		printf("Timer %lu  %lu  %lu  %lu  %lu\n", now, now2, now3, now4, delay);
		call Timer.startOneShot(delay);
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] TimerMilli sleeps for %lu\n", process, delay);
#endif
	}
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	dbg("Application", "[%d] timerCalMilli SplitControl.stop()", process);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


event void Timer.fired() {
	dbg("Application", "[%d] timerCalMilli call Event.report(%d, TRUE)", process, process);
	call Event.report(process, TRUE);
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] TimerMilli woke up\n", process);
#endif
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id) {

}

}
