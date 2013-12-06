/*
 *  UARTBridge application module for Fennec Fox platform.
 *
 *  Copyright (C) 2013 Marcin Szczodrak
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
 * Application: UARTBridge Application Module
 * Author: Marcin Szczodrak
 * Date: 10/01/2013
 * Last Modified: 10/09/2013
 */

#include <Fennec.h>
#include "UARTBridgeApp.h"

module UARTBridgeAppP {
provides interface Mgmt;

uses interface UARTBridgeAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Leds;

/* Serial Interfaces */
uses interface AMSend as SerialAMSend;
uses interface AMPacket as SerialAMPacket;
uses interface Packet as SerialPacket;
uses interface Receive as SerialReceive;
uses interface SplitControl as SerialSplitControl;

/* Serial Queue */
uses interface Queue<msg_queue_t> as SerialQueue;

}

implementation {

message_t packet;
bool busy_serial = FALSE;
void *serial_data;

task void send_serial_message() {

	msg_queue_t *sm;

	/* Check if there is anything to send */
		if (call SerialQueue.empty()) {
		return;
	}

	if (busy_serial == TRUE) {
		call Leds.led0On();
		return;
	}

	sm = call SerialQueue.headptr();

	if (call SerialAMSend.send(BROADCAST, &packet, sm->len) != SUCCESS) {
		call Leds.led0On();
		signal SerialAMSend.sendDone(&packet, FAIL);
	} else {
		busy_serial = TRUE;
	}
}


command error_t Mgmt.start() {
	dbg("Application", "UARTBridgeApp Mgmt.start()");
	call SerialSplitControl.start();
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("Application", "UARTBridgeApp Mgmt.start()");
	call SerialSplitControl.stop();
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	call SerialQueue.dequeue();
	busy_serial = FALSE;
	post send_serial_message();
}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	msg_queue_t sm;

	/* Check if there is anything to send */
	if (call SerialQueue.empty()) {
		return msg;
	}

	sm.len = len;
	memcpy(&sm.data, payload, len);

	call SerialQueue.enqueue(sm);

	post send_serial_message();

	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SerialSplitControl.startDone(error_t error) {
	if (error != SUCCESS) {
		call Leds.led0On();
	}
	serial_data = (void*) call SerialAMSend.getPayload(&packet, 
			BRIDGE_MAX_PAYLOAD_SIZE);
	if (serial_data == NULL) {
		call Leds.led0On();
	}
	signal Mgmt.startDone(SUCCESS);
}

event void SerialSplitControl.stopDone(error_t error) {
	if (error != SUCCESS) {
		call Leds.led0On();
	}
	signal Mgmt.stopDone(SUCCESS);
}

event message_t* SerialReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SerialAMSend.sendDone(message_t *msg, error_t error) {
}


}
