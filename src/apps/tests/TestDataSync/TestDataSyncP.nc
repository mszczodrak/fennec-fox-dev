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
  * TestDataSync Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include <Timer.h>
#include "TestDataSync.h"

generic module TestDataSyncP(process_t process) {
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
uses interface Random;

uses interface SerialDbgs;

}

implementation {

uint32_t update_delay;

command error_t SplitControl.start() {
	call Param.get(UPDATE_DELAY, &update_delay, sizeof(update_delay));

	#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	#endif
	call Timer.startPeriodic((call Random.rand16() * TOS_NODE_ID) % update_delay);

#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

task void updateData() {
	uint8_t v = call Random.rand16() % 5;	
	uint16_t d = call Random.rand16();

	switch(v) {
	case 1:
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSync set var ID %u (var %u) to %u\n", process, VAL1, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL1, v, d);
#endif
#endif
		call Param.set(VAL1, &d, sizeof(d));
		break;

	case 2:
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSync set var ID %u (var %u) to %u\n", process, VAL2, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL2, v, d);
#endif
#endif
		call Param.set(VAL2, &d, sizeof(d));
		break;

	case 3:
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSync set var ID %u (var %u) to %u\n", process, VAL3, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL3, v, d);
#endif
#endif
		call Param.set(VAL3, &d, sizeof(d));
		break;

	case 4:
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSync set var ID %u (var %u) to %u\n", process, VAL4, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL4, v, d);
#endif
#endif
		call Param.set(VAL4, &d, sizeof(d));
		break;

	default:
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSync set var ID %u (var %u) to %u\n", process, VAL5, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL5, v, d);
#endif
#endif
		call Param.set(VAL5, &d, sizeof(d));
		break;
	}
}

event void Timer.fired() {
	uint32_t rand_delay = call Random.rand32() % update_delay;
	post updateData();
	call Timer.startPeriodic(update_delay / 2 + rand_delay);
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id) {
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] TestDataSync get var %u update\n", process, var_id);
#else
	call SerialDbgs.dbgs(DBGS_NEW_REMOTE_PAYLOAD, var_id, var_id, var_id);
#endif
#endif
}

}
