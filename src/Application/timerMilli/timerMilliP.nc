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
#include "timerMilli.h"

generic module timerMilliP() {
provides interface SplitControl;

uses interface timerMilliParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Timer<TMilli>;
provides interface Event;
}

implementation {

/** Available Parameters
	uint32_t delay = 1000,
	uint16_t src = 0
*/


command error_t SplitControl.start() {
	dbg("Application", "timerMilli SplitControl.start()");
	dbg("Application", "timerMilli src: %d", call timerMilliParams.get_src());

	if ((call timerMilliParams.get_src() == BROADCAST) || 
		(call timerMilliParams.get_src() == TOS_NODE_ID)) {
		dbg("Application", "timerMilli will fire in %d ms", call timerMilliParams.get_delay());
		call Timer.startOneShot(call timerMilliParams.get_delay());

	}
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	dbg("Application", "timerMilli SplitControl.stop()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


event void Timer.fired() {
	dbg("Application", "timerMilli signal Event.occured(TRUE)");
	signal Event.occured(TRUE);
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

}
