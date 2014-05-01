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

module SerialDbgsP @safe() {
provides interface SerialDbgs[uint8_t id];
uses interface Leds;
#ifdef __DBGS__
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
#endif
}

implementation {

#ifdef __DBGS__

message_t queue[DBGS_QUEUE_LEN];
norace uint8_t head = 0;
norace uint8_t tail = 0;
norace uint8_t size = 0;

task void sendMessage() {

	if (size == 0 ) {
		return;
	}

#ifdef FENNEC_TOS_PRINTF
	printf("%d %d %d %d %d %d\n", queue[head].version, queue[head].version,
		queue[head].dbg, queue[head].d0, queue[head].d1, queue[head].d2);
	printfflush();

	signal SerialAMSend.sendDone(&packet, SUCCESS);
#else
	switch(call SerialAMSend.send(AM_BROADCAST_ADDR, &queue[head], sizeof(nx_struct debug_msg))) {
		case EBUSY:
		case SUCCESS:
			break;

		default:
			signal SerialAMSend.sendDone(&queue[head], FAIL);
	}
#endif
}

#endif

command void SerialDbgs.dbgs[uint8_t id](uint8_t dbg, uint16_t d0, uint16_t d1, uint16_t d2) {

#ifdef TOSSIM 
	dbg("SerialDbgs", "%d %d %d %d %d %d\n", SERIAL_DBG_VERSION, id, dbg, d0, d1, d2);
#endif

#ifdef __DBGS__
	nx_struct debug_msg *dmsg = (nx_struct debug_msg*) call SerialAMSend.getPayload(&queue[tail],
		sizeof(nx_struct debug_msg));

	if (size >= DBGS_QUEUE_LEN || dmsg == NULL) {
		return;
	}

	dmsg->version = SERIAL_DBG_VERSION;
	dmsg->id = id;
	dmsg->dbg = dbg;
	dmsg->d0 = d0;
	dmsg->d1 = d1;
	dmsg->d2 = d2;

	atomic {
		tail++;
		if (tail == DBGS_QUEUE_LEN) tail = 0;
		size++;
	}

	post sendMessage();
#endif
}

#ifdef __DBGS__

event void SerialAMSend.sendDone(message_t* bufPtr, error_t error) {
	atomic {
		if (size > 0) {
			head++;
			if (head == DBGS_QUEUE_LEN) head = 0;
			size--;
		}
	}

	post sendMessage();
}

#endif

}

