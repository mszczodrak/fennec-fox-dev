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
uses interface Timer<TMilli> as SendTimer;
uses interface Timer<TMilli> as LedTimer;
}

implementation {

message_t packet;
bool busy;

message_metadata_t* getMetadata(message_t *msg) {
	return (message_metadata_t*)msg->metadata;
}

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

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	busy = FALSE;
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	int8_t rssi = (int8_t) call SubPacketRSSI.get(msg);
	int16_t rssi_calib = (rssi * call RssiParams.get_rssi_scale()) + 
				call RssiParams.get_rssi_offset();
#ifdef FENNEC_TOS_PRINTF
	int8_t lqi = (int8_t) call SubPacketLinkQuality.get(msg);
	printf("RSSI: %d  LQI: %d\n", rssi, lqi);
	printfflush();
#endif

	signal LedTimer.fired();

	call Leds.led0On();

	if ( rssi_calib  > call RssiParams.get_threshold_1() ) {
		call Leds.led1On();
	}

	if ( rssi_calib  > call RssiParams.get_threshold_2() ) {
		call Leds.led2On();
	}

	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SendTimer.fired() {
	if (!busy) {
		busy = TRUE;
		call SubAMSend.send(BROADCAST, &packet, 40);
	}
}

event void LedTimer.fired() {
	call Leds.set(0);
	post reset_led_timer();
}

}
