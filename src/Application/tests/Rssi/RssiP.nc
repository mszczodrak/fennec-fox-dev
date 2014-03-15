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
  * Fennec Fox Rssi Application module
  *
  * @author: Marcin K Szczodrak
  * @updated: 05/22/2011
  */


#include <Fennec.h>
#include "Rssi.h"

generic module RssiP(process_t process) {
provides interface SplitControl;

uses interface RssiParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Leds;
uses interface Timer<TMilli> as SendTimer;
uses interface Timer<TMilli> as LedTimer;
}

implementation {

message_t packet;
bool busy;

task void reset_led_timer() {
	call LedTimer.startOneShot(2 * call RssiParams.get_tx_delay());
}

command error_t SplitControl.start() {
	dbg("Application", "Rssi SplitControl.start()");
	call SendTimer.startPeriodic(call RssiParams.get_tx_delay());
	busy = FALSE;
	post reset_led_timer();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Application", "Rssi SplitControl.start()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
#ifdef FENNEC_TOS_PRINTF
	printf("%d %u %u\n", (int8_t)getMetadata(msg)->rssi, getMetadata(msg)->lqi, getMetadata(msg)->crc);
	printfflush();
#endif

	signal LedTimer.fired();

	call Leds.led0On();

	if ( ((int8_t)getMetadata(msg)->rssi) > call RssiParams.get_threshold_1() ) {
		call Leds.led1On();
	}

	if ( ((int8_t)getMetadata(msg)->rssi) > call RssiParams.get_threshold_2() ) {
		call Leds.led2On();
	}

	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SendTimer.fired() {
	if (!busy) {
		busy = TRUE;
		call NetworkAMSend.send(BROADCAST, &packet, 40);
	}
}

event void LedTimer.fired() {
	call Leds.set(0);
	post reset_led_timer();
}

}
