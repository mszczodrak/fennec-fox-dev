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
  * TestMax Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include <Timer.h>
#include "TestMax.h"

generic module TestMaxP(process_t process) {
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
uses interface Timer<TMilli> as ExpireTimer;
uses interface Timer<TMilli> as SenseTimer;
uses interface Random;

uses interface SerialDbgs;

}

implementation {

uint32_t sense_delay;
uint32_t expire_delay;
uint32_t max_val;

task void updateData();

command error_t SplitControl.start() {
	max_val = 0;
	call Param.get(SENSE_DELAY, &sense_delay, sizeof(sense_delay));
	call Param.get(EXPIRE_DELAY, &expire_delay, sizeof(expire_delay));

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("sense delay is %lu and expire delay is %lu\n", 
			sense_delay, expire_delay);
#endif
	call SenseTimer.startOneShot(sense_delay);

#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_START, process, 0, 0);
#endif
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call SenseTimer.stop();
	call ExpireTimer.stop();
#ifdef __DBGS__APPLICATION__
	call SerialDbgs.dbgs(DBGS_MGMT_STOP, process, 0, 0);
#endif
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SenseTimer.fired() {
	uint16_t rand_delay = call Random.rand16() % sense_delay;

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Application fired\n");
#endif

	post updateData();
	call SenseTimer.startOneShot(sense_delay / 2 + rand_delay);
}

event void ExpireTimer.fired() {
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Node [%d] Expired!\n", TOS_NODE_ID);
#endif
}

void checkMaxData(uint32_t v) {
	if ( (! call ExpireTimer.isRunning()) || (max_val < v) ) {
		#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("Node [%d] set MAX_SENSE %lu < %lu\n", 
					TOS_NODE_ID, max_val, v);
		#endif

		call ExpireTimer.startOneShot(expire_delay);
		max_val = v;
		call Param.set(MAX_SENSED, &max_val, sizeof(max_val));
	} else {
		#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
			printf("Node [%d] pass ... %lu >= %lu\n", 
					TOS_NODE_ID, max_val, v);
		#endif
	}
}

task void updateData() {
	checkMaxData(call Random.rand32());
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
	uint32_t temp;
	call Param.get(MAX_SENSED, &temp, sizeof(temp));

#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Application var %d updated to %lu\n", var_id, temp);
#endif
	checkMaxData(temp);
}

}
