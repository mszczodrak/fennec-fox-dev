/*
 *  TestSerial application module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Application: TestSerial Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "TestSerialApp.h"

module TestSerialAppP {
provides interface SplitControl;

uses interface TestSerialAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

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


command error_t SplitControl.start() {
	on = 0;
	busy_serial = FALSE;
	seq = 0;
	dbg("Application", "TestSerialApp SplitControl.start()");
	call Timer.startPeriodic(call TestSerialAppParams.get_delay());
	call SerialSplitControl.start();
        signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
        call Timer.stop();
        call Leds.set(0);
	dbg("Application", "TestSerialApp SplitControl.start()");
	//call SerialSplitControl.stop();
        signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void Timer.fired() {
	uint32_t* p = (uint32_t*) call SerialAMSend.getPayload(&packet,
                        sizeof(uint32_t));

	dbg("Application", "TestSerialApp Timer.fired() - sending seqquence %d", seq);

	*p = seq++;

	/* Send message over the serial and check if serial started without error */
        if (call SerialAMSend.send(BROADCAST, &packet, sizeof(uint32_t)) != SUCCESS) {
                signal SerialAMSend.sendDone(&packet, FAIL);
        } else {
        	on ? call Leds.set(0) : call Leds.set(call TestSerialAppParams.get_led()) ;
	        on = !on;
                busy_serial = TRUE;
        }
}


event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SerialSplitControl.startDone(error_t error) {
	dbg("Application", "TestSerialApp SerialSplitControl.startDone(%d)", error);
}

event void SerialSplitControl.stopDone(error_t error) {
	dbg("Application", "TestSerialApp SerialSplitControl.stopDone(%d)", error);
}

event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
        return msg;
}

event void SerialAMSend.sendDone(message_t *msg, error_t error) {
        busy_serial = FALSE;
}


}
