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
  * TestDataRandom Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include <Timer.h>
#include "TestDataRandom.h"

generic module TestDataRandomP(process_t process) {
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
uint16_t mote1;
uint16_t mote2;
uint16_t val1 = 0;
uint16_t val2 = 0;

void printfRecord() {
#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("[ %u %u ]\n", val1, val2); 
#else
	call SerialDbgs.dbgs(DBGS_NEW_REMOTE_PAYLOAD, process, val1, val2);
#endif
#endif
} 


command error_t SplitControl.start() {
	call Param.get(UPDATE_DELAY, &update_delay, sizeof(update_delay));
	call Param.get(MOTE1, &mote1, sizeof(mote1));
	call Param.get(MOTE2, &mote2, sizeof(mote2));
	call Param.get(VAL1, &val1, sizeof(val1));
	call Param.get(VAL2, &val2, sizeof(val2));

	if ((mote1 == TOS_NODE_ID) || (mote2 == TOS_NODE_ID)) {
		call Timer.startOneShot(update_delay);
	}

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

event void Timer.fired() {
	val1 = call Random.rand16();

#ifdef __DBGS__APPLICATION__
#if defined(FENNEC_TOS_PRINTF) || defined(FENNEC_COOJA_PRINTF)
	printf("Start with %u\n", val1);
#else
	call SerialDbgs.dbgs(DBGS_NEW_LOCAL_PAYLOAD, process, val1, val1);
#endif
#endif
	call Param.set(VAL1, &val1, sizeof(val1));
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
}


event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Param.updated(uint8_t var_id, bool conflict) {
	uint16_t temp;
	call Param.get(var_id, &temp, sizeof(temp));

	if (var_id == VAL1) {
		if (temp != val1) {
			/* move val1 to val2 */
//			if ((val1 != 0) && (val1 != val2)) {
//				val2 = val1;
//				call Param.set(VAL2, &val2, sizeof(val2));
//			}

			val1 = temp;
			printfRecord();
			return;
		}
	}

//	if (var_id == VAL2) {
//		if (temp != val2) {
//			val2 = temp;
//			printfRecord();
//			return;
//		}
//	}

}

}
