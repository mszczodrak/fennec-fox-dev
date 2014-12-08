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
#include "noSignal.h"

generic module noSignalP(process_t process) {
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

uses interface Event;
uses interface Timer<TMilli>;

uses interface SerialDbgs;
}

implementation {

uint16_t delay;
uint16_t delay_scale;
uint16_t src;
uint32_t max_signal_delay = 0;

command error_t SplitControl.start() {
	call Param.get(SRC, &src, sizeof(src));
	call Param.get(DELAY, &delay, sizeof(delay));
	call Param.get(DELAY_SCALE, &delay_scale, sizeof(delay_scale));
	max_signal_delay = delay;
	max_signal_delay *= delay_scale;

#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Event noSignal start()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_MGMT_START, 0, 0, 0);
#endif
#endif
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();

#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Event noSignal stop()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_STATUS_UPDATE, 0, 0, 0);
#endif
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void Timer.fired() {
#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
        printf("[%u] Event noSignal fired()\n", process);
#else
	call SerialDbgs.dbgs(DBGS_TIMER_FIRED, 0, 0, 0);
#endif
#endif
	call Event.report(process, TRUE);
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}
	
event void Param.updated(uint8_t var_id, bool conflict) {	
	if ((src != BROADCAST) && (src != TOS_NODE_ID)) {
		return;
	}

	switch(var_id) {
	case INPUT:
		call Timer.startOneShot(max_signal_delay);
#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] Event noSignal busy\n", process);
#else
		call SerialDbgs.dbgs(DBGS_BUSY, 0, 0, 0);
#endif
#endif
		break;
	default:
		break;
	}
}

}
