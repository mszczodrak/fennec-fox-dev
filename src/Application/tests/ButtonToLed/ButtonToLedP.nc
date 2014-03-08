/*
 * Copyright (c) 2014, Columbia University.
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
  * Fennec Fox ButtonToLed test application 
  *
  * @author: Marcin K Szczodrak
  * @updated: 03/07/2014
  */

#include <Fennec.h>
#include "ButtonToLed.h"

generic module ButtonToLedP() {
provides interface SplitControl;

uses interface ButtonToLedParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Leds;
uses interface Timer<TMilli>;
uses interface Get<button_state_t>;
uses interface Notify<button_state_t>;

}

implementation {

uint8_t counter;
message_t packet;

task void send_message() {

	ButtonToLedMsg *msg = (ButtonToLedMsg*)call NetworkAMSend.getPayload(&packet,
							sizeof(ButtonToLedMsg));

	if (msg == NULL) {
		return;
	}

	msg->counter = counter;

	if (call NetworkAMSend.send(BROADCAST, &packet, 
				sizeof(ButtonToLedMsg)) != SUCCESS) {
                dbgs(F_APPLICATION, S_ERROR, DBGS_SEND_DATA, counter, counter);
                dbg("Application", "ButtonToLed sendMessage() counter: %d - FAILED",
                                        		msg->counter);
        } else {
                dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, counter, counter);
                dbg("Application", "ButtonToLed call NetworkAMSend.send(%d, 0x%1x, %d)",
                                        BROADCAST, &packet, sizeof(ButtonToLedMsg));
                call Leds.set(counter);
        }
	counter = 0;
}

command error_t SplitControl.start() {
	dbg("Application", "ButtonToLed SplitControl.start()");
	counter++;
	call Notify.enable();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Application", "ButtonToLed SplitControl.start()");
	call Notify.disable();
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	ButtonToLedMsg* c = (ButtonToLedMsg*)payload;
	call Leds.set(c->counter);
	dbg("Application", "ButtonToLed event NetworkReceive.receive(0x%1x, 0x%1x, %d)", msg, payload, len);
	dbg("Application", "ButtonToLed receive counter: %d", c->counter);
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	post send_message();
}

event void Notify.notify( button_state_t state ) {
	if ( state == BUTTON_PRESSED ) {
		counter++;
		call Timer.startOneShot(BUTTON_WAIT_TIME);
	}
//	} else if ( state == BUTTON_RELEASED ) {
//		call Leds.led2Off();
//	}
}

}
