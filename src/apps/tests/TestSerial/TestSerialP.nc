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
  * Serial Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

#include <Fennec.h>
#include "TestSerial.h"

generic module TestSerialP(process_t process) {
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
uses interface Timer<TMilli> as Timer;

/* Serial Interfaces */
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
uses interface Packet as SerialPacket;
uses interface Receive as SerialReceive;
uses interface SplitControl as SerialSplitControl;
}

implementation {

message_t packet;
bool busy_serial = FALSE;
void *serial_data;
bool on;
uint32_t seq = 0;

uint8_t led=1;
uint16_t delay=1024;

command error_t SplitControl.start() {
	on = 0;
	busy_serial = FALSE;
	seq = 0;
	dbg("Application", "TestSerial SplitControl.start()");
	call Param.get(DELAY, &delay, sizeof(delay));
	call Param.get(LED, &led, sizeof(led));
	call Timer.startPeriodic(delay);
	call SerialSplitControl.start();
        signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
        call Timer.stop();
	dbg("Application", "TestSerial SplitControl.start()");
	//call SerialSplitControl.stop();
        signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void Timer.fired() {
	uint32_t* p = (uint32_t*) call SerialAMSend.getPayload(&packet,
                        sizeof(uint32_t));

	dbg("Application", "TestSerial Timer.fired() - sending seqquence %d", seq);

	*p = seq++;

	/* Send message over the serial and check if serial started without error */
        if (call SerialAMSend.send(BROADCAST, &packet, sizeof(uint32_t)) != SUCCESS) {
                signal SerialAMSend.sendDone(&packet, FAIL);
        } else {
        	on ? call Leds.set(0) : call Leds.set(led) ;
	        on = !on;
                busy_serial = TRUE;
        }
}


event void SubAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SerialSplitControl.startDone(error_t error) {
	dbg("Application", "TestSerial SerialSplitControl.startDone(%d)", error);
}

event void SerialSplitControl.stopDone(error_t error) {
	dbg("Application", "TestSerial SerialSplitControl.stopDone(%d)", error);
}

event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
        return msg;
}

event void SerialAMSend.sendDone(message_t *msg, error_t error) {
        busy_serial = FALSE;
}


}
