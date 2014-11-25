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
  * TestDataSyncSem Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include <Timer.h>
#include "TestDataSyncSem.h"

generic module TestDataSyncSemP(process_t process) {
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
uint32_t next_delay;

uint16_t lvar1;
uint16_t lvar2;
uint16_t lvar3;
uint16_t lvar4;
uint16_t lvar5;

void reset_vars() {
	lvar1 = 0;
	lvar2 = 0;
	lvar3 = 0;
	lvar4 = 0;
	lvar5 = 0;
}

command error_t SplitControl.start() {
	call Param.get(UPDATE_DELAY, &update_delay, sizeof(update_delay));
	next_delay = call Random.rand32();
	next_delay *= TOS_NODE_ID;
	next_delay %= update_delay;
	reset_vars();

	call Timer.startPeriodic(next_delay);

#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	reset_vars();
#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif

	call Param.set(VAL1, &lvar1, sizeof(lvar1));
	call Param.set(VAL1, &lvar2, sizeof(lvar2));
	call Param.set(VAL1, &lvar3, sizeof(lvar3));
	call Param.set(VAL1, &lvar4, sizeof(lvar4));
	call Param.set(VAL1, &lvar5, sizeof(lvar5));

	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

task void updateData() {
	uint8_t v = call Random.rand16() % 5;	
	uint16_t d = call Random.rand16();

	switch(v) {
	case 1:
		if (d < lvar1) {
			printf("skip1 small %u < %u\n", d, lvar1);
			break;
		}
		lvar1 = d;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSyncSem  SET  var ID %u (var %u) to %u\n", process, VAL1, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL1, v, d);
#endif
#endif
		call Param.set(VAL1, &d, sizeof(d));
		break;

	case 2:
		if (d < lvar2) {
			printf("skip2 small %u < %u\n", d, lvar2);
			break;
		}
		lvar2 = d;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSyncSem  SET  var ID %u (var %u) to %u\n", process, VAL2, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL2, v, d);
#endif
#endif
		call Param.set(VAL2, &d, sizeof(d));
		break;

	case 3:
		if (d < lvar3) {
			printf("skip3 small %u < %u\n", d, lvar3);
			break;
		}
		lvar3 = d;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSyncSem  SET  var ID %u (var %u) to %u\n", process, VAL3, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL3, v, d);
#endif
#endif
		call Param.set(VAL3, &d, sizeof(d));
		break;

	case 4:
		if (d < lvar4) {
			printf("skip4 small %u < %u\n", d, lvar4);
			break;
		}
		lvar4 = d;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSyncSem  SET  var ID %u (var %u) to %u\n", process, VAL4, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL4, v, d);
#endif
#endif
		call Param.set(VAL4, &d, sizeof(d));
		break;

	default:
		if (d < lvar5) {
			printf("skip5 small %u < %u\n", d, lvar5);
			break;
		}
		lvar5 = d;
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("[%u] TestDataSyncSem  SET  var ID %u (var %u) to %u\n", process, VAL5, v, d);
#else
			call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, VAL5, v, d);
#endif
#endif
		call Param.set(VAL5, &d, sizeof(d));
		break;
	}
}

event void Timer.fired() {
	post updateData();

	next_delay = call Random.rand32();
	next_delay *= TOS_NODE_ID;
	next_delay %= update_delay;
	next_delay += (update_delay / 2);
	call Timer.startPeriodic(next_delay);
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
	uint8_t v = 0;
	uint16_t d;

	if (! call Timer.isRunning()) {
		return;
	}

	call Param.get(var_id, &d, sizeof(d));
	switch(var_id) {
	case VAL1:
		v = 0;
		if (d < lvar1) {
			call Param.set(VAL1, &lvar1, sizeof(lvar1));
			return;
		}
		lvar1 = d;
		break;

	case VAL2:
		v = 1;
		if (d < lvar2) {
			call Param.set(VAL2, &lvar2, sizeof(lvar2));
			return;
		}
		lvar2 = d;
		break;

	case VAL3:
		v = 2;
		if (d < lvar3) {
			call Param.set(VAL3, &lvar3, sizeof(lvar3));
			return;
		}
		lvar3 = d;
		break;


	case VAL4:
		v = 4;
		if (d < lvar4) {
			call Param.set(VAL4, &lvar4, sizeof(lvar4));
			return;
		}
		lvar4 = d;
		break;

	case VAL5:
		v = 5;
		if (d < lvar5) {
			call Param.set(VAL5, &lvar5, sizeof(lvar5));
			return;
		}
		lvar5 = d;
		break;
	}

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[%u] TestDataSyncSem get var ID %u (var %u) to %u\n", process, var_id, v, d);
#else
	call SerialDbgs.dbgs(DBGS_NEW_REMOTE_PAYLOAD, var_id, v, d);
#endif
#endif
}

}
