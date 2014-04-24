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
  * Fennec Fox SerialDbgs Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */

#include <Fennec.h>
#include "SerialDbgs.h"

generic module SerialDbgsP(uint8_t id) @safe() {
provides interface SerialDbgs;
uses interface Boot;
uses interface Leds;
#ifdef __DBGS__
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
uses interface Packet as SerialPacket;
uses interface SplitControl as SerialSplitControl;
#endif
}

implementation {

#ifdef __DBGS__
nx_struct debug_msg *dmsg = NULL;
message_t packet;
nx_struct debug_msg queue[DBGS_QUEUE_LEN];
norace uint8_t head = 0;
norace uint8_t tail = 0;
norace uint8_t size = 0;
norace bool busy = FALSE;

task void sendMessage() {
	if (size == 0) {
		return;
	}

	if (busy == TRUE) {
		return;
	}

	if (dmsg == NULL) {
		dmsg = (nx_struct debug_msg*) call SerialAMSend.getPayload(&packet,
                        sizeof(nx_struct debug_msg));
		return;
	}

	busy = TRUE;

	dmsg->version = queue[head].version;
	dmsg->id = queue[head].version;
	dmsg->dbg = queue[head].dbg;
	dmsg->d0 = queue[head].d0;
	dmsg->d1 = queue[head].d1;
	dmsg->d2 = queue[head].d2;
	if (call SerialAMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(nx_struct debug_msg)) != SUCCESS) {
		signal SerialAMSend.sendDone(&packet, FAIL);
	}
}

#endif

event void Boot.booted() {
#ifdef __DBGS__
	dmsg = (nx_struct debug_msg*) call SerialAMSend.getPayload(&packet,
                        sizeof(nx_struct debug_msg));
	call SerialSplitControl.start();
#endif
}

command void SerialDbgs.dbgs(uint8_t dbg, uint16_t d0, uint16_t d1, uint16_t d2) {
#ifdef __DBGS__
	if (size >= DBGS_QUEUE_LEN) {
		return;
	}

	if (dmsg == NULL) {
		dmsg = (nx_struct debug_msg*) call SerialAMSend.getPayload(&packet,
                        sizeof(nx_struct debug_msg));
		return;
	}

	queue[tail].version = SERIAL_DBG_VERSION;
	queue[tail].id = id;
	queue[tail].dbg = dbg;
	queue[tail].d0 = d0;
	queue[tail].d1 = d1;
	queue[tail].d2 = d2;
	tail++;
	if (tail == DBGS_QUEUE_LEN) tail = 0;
	size++;
	post sendMessage();
#endif
}

#ifdef __DBGS__

event void SerialSplitControl.startDone(error_t error) {
	dmsg = (nx_struct debug_msg*) call SerialAMSend.getPayload(&packet,
                        sizeof(uint32_t));
}

event void SerialSplitControl.stopDone(error_t error) {
}

event void SerialAMSend.sendDone(message_t* bufPtr, error_t error) {
	if (size != 0) {
		head++;
		if (head == DBGS_QUEUE_LEN) head = 0;
		size--;
	}
	busy = FALSE;
	post sendMessage();

}
#endif

}

