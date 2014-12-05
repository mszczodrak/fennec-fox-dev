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
#include "networkMin.h"

generic module networkMinP(process_t process) {
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

uint16_t local;
uint16_t global;
uint32_t delay;
uint16_t threshold = 0;

task void new_local() {
	call Param.get(LOCAL, &local, sizeof(local));
#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Event networkMin local %u\n", process, local);
#else
//	call SerialDbgs.dbgs(DBGS_BUSY, max_event_count, threshold, event_counter);
#endif
#endif

	if (local > global) {
		global = local;
		call Param.set(GLOBAL, &global, sizeof(global));

#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] Event networkMin local -> global %u\n", process, global);
#else
//		call SerialDbgs.dbgs(DBGS_BUSY, max_event_count, threshold, event_counter);
#endif
#endif
	}

	if (global > threshold) {
		call Timer.startOneShot(delay);
	}

}

task void new_global() {
	uint16_t tmp_global;
	call Param.get(GLOBAL, &tmp_global, sizeof(tmp_global));

	if (tmp_global < local) {
		global = local;
		call Param.set(GLOBAL, &global, sizeof(global));
	} else {
		global = tmp_global;
#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
		printf("[%u] Event networkMin global %u\n", process, global);
#else
//		call SerialDbgs.dbgs(DBGS_BUSY, max_event_count, threshold, event_counter);
#endif
#endif
	}

	if (global > threshold) {
		call Timer.startOneShot(delay);
	}

}

command error_t SplitControl.start() {
	call Param.get(LOCAL, &local, sizeof(local));
	call Param.get(GLOBAL, &global, sizeof(global));
	call Param.get(DELAY, &delay, sizeof(delay));
	call Param.get(THRESHOLD, &threshold, sizeof(threshold));

#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Event networkMin start()\n", process);
#else
	//call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
#endif

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();

#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] Event networkMin stop()\n", process);
//	printf("[%u] Event networkMin max_event is %d  threshold is %d\n", process, max_event_count, threshold);
#else
//	call SerialDbgs.dbgs(DBGS_STATUS_UPDATE, src, max_event_count, threshold);
#endif
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void Timer.fired() {
#ifdef __DBGS__EVENT__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
        printf("[%u] Event networkMin fired()\n", process);
#else
//	call SerialDbgs.dbgs(DBGS_TIMER_FIRED, src, (uint16_t)(delay >> 16), (uint16_t)delay);
#endif
#endif

	if (global > threshold) {

	} else {

	}

//	call Event.report(process, TRUE);
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}
	
event void Param.updated(uint8_t var_id, bool conflict) {	
	switch(var_id) {
	case LOCAL:
		post new_local();
		break;

	case GLOBAL:
		post new_global();
		break;

	default:
		break;
	}
}

}
