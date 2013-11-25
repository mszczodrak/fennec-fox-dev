/*
 *  maxTest application module for Fennec Fox platform.
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
 * Application: maxTest Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "maxTestApp.h"

module maxTestAppP {
provides interface Mgmt;

uses interface maxTestAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Random;
uses interface Leds;
uses interface Timer<TMilli>;
}

implementation {

uint32_t max_value = 0;
message_t packet;
bool send_busy = FALSE;

task void send_msg() {
	nx_struct maxMsg *out_msg = (nx_struct maxMsg*)
		call NetworkAMSend.getPayload(&packet, sizeof(nx_struct maxMsg));

	if (out_msg == NULL) {
		return;
	}

	out_msg->max_value = max_value;
	
	if (call NetworkAMSend.send(BROADCAST, &packet, 
			sizeof(nx_struct maxMsg)) != SUCCESS) {
		dbg("Application", "maxTestApp send_msg() - cannot send");
	} else {
//		dbg("Application", "maxTestApp send_msg() - max_value %d", max_value);
		send_busy = TRUE;
		call Leds.set(max_value);
	}
}


command error_t Mgmt.start() {
	dbg("Application", "maxTestApp Mgmt.start()");
	max_value = call maxTestAppParams.get_val();
	if (max_value == 0) {
		max_value = call Random.rand32();
	}
	dbg("Application", "maxTestApp Mgmt.start() max_value is %d", max_value);

	send_busy = FALSE;

	if (call maxTestAppParams.get_delay() > 0) {
		call Timer.startPeriodic(call maxTestAppParams.get_delay());
	}

	dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, (uint16_t) (max_value >> 16), 
							(uint16_t) (max_value & 0x0000FFFFuL) );

	signal Mgmt.startDone(SUCCESS);
	post send_msg();
	return SUCCESS;
}


command error_t Mgmt.stop() {
	dbg("Application", "maxTestApp Mgmt.start()");
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}


event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	send_busy = FALSE;
}


event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	nx_struct maxMsg *in_msg = (nx_struct maxMsg*) payload;
	if (in_msg->max_value > max_value) {
		max_value = in_msg->max_value;
		dbg("Application", "maxTestApp NetworkReceive.receive() - got new max: %d", max_value);
		post send_msg();
		dbgs(F_APPLICATION, S_RECEIVING, 0, (uint16_t) (max_value >> 16), 
							(uint16_t) (max_value & 0x0000FFFFuL) );
	}

	if (in_msg->max_value < max_value) {
		post send_msg();
	}

	return msg;
}


event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void Timer.fired() {
	dbg("Application", "maxTestApp Timer.fired() max_value is %d", max_value);
	dbgs(F_APPLICATION, S_INIT, 0, (uint16_t) (max_value >> 16), 
							(uint16_t) (max_value & 0x0000FFFFuL) );
	if (!send_busy) {
		post send_msg();
	}
}

}
