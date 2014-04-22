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
#include "DebugMsg.h"

module SerialDbgsP @safe() {
#ifdef __DBGS__
uses interface AMSend;
#endif
}

implementation {

#ifdef __DBGS__
message_t packet;
norace struct debug_msg *dmsg = NULL;
bool busy = FALSE;

event void AMSend.sendDone(message_t* bufPtr, error_t error) {
	busy = FALSE;
}

#endif
void dbgs(process_t process, uint8_t layer, uint8_t dbg_state, uint16_t d0, uint16_t d1) @C() {
#ifdef __DBGS__
	if (busy) {
		return;
	}

	if (dmsg == NULL) {
		dmsg = (struct debug_msg*) call AMSend.getPayload(&packet, sizeof(struct debug_msg));
	}

	busy = TRUE;

	dmsg->process = process;
	dmsg->layer = layer;
	dmsg->state = dbg_state;
	dmsg->d0 = d0;
	dmsg->d1 = d1;

	if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(struct debug_msg)) != SUCCESS) {
		signal AMSend.sendDone(&packet, FAIL);
	}
#endif
}

}

