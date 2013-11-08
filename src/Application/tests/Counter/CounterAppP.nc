/*
 *  Counter test application module for Fennec Fox platform.
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
 * Network: Counter test Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include <Timer.h>
#include "CounterApp.h"

module CounterAppP {
provides interface Mgmt;

uses interface CounterAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Leds;
uses interface Timer<TMilli>;

}

implementation {

/**
 Available Parameters:
	uint16_t delay,
	uint16_t delay_scale,
	uint16_t src,
	uint16_t dest
*/


message_t packet;
bool sendBusy = FALSE;
uint16_t seqno;

command error_t Mgmt.start() {
	uint32_t send_delay = call CounterAppParams.get_delay() * 
		call CounterAppParams.get_delay_scale();
	//call Leds.led0On();
	//dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);
	dbg("Application", "CounterApp Mgmt.start()");

	dbg("Application", "CounterApp starting delay: %d", send_delay);
	dbg("Application", "CounterApp starting src: %d  dest: %d",
		call CounterAppParams.get_src(), call CounterAppParams.get_dest());
	seqno = 0;

	if ((call CounterAppParams.get_src() == BROADCAST) || 
	(call CounterAppParams.get_src() == TOS_NODE_ID)) {
		call Leds.led1On();
		call Timer.startPeriodic(send_delay);
	}

	sendBusy = FALSE;
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	call Timer.stop();
	dbg("Application", "CounterApp Mgmt.stop()");
	//dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

void sendMessage() {
	CounterMsg* msg = (CounterMsg*)call NetworkAMSend.getPayload(&packet,
							sizeof(CounterMsg));
	call Leds.led1Toggle();
	if (msg == NULL) {
		return;
	}

	msg->source = TOS_NODE_ID;
	msg->seqno = seqno;

	dbg("Application", "CounterApp sendMessage() seqno: %d source: %d", msg->seqno, msg->source); 
	//dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, seqno, call CounterAppParams.get_dest());

	if (call NetworkAMSend.send(call CounterAppParams.get_dest(), &packet, 
					sizeof(CounterMsg)) != SUCCESS) {
	} else {
		dbg("Application", "CounterApp call NetworkAMSend.send(%d, 0x%1x, %d)",
					call CounterAppParams.get_dest(), &packet,
					sizeof(CounterMsg));
		sendBusy = TRUE;
		call Leds.set(seqno);
	}
}

event void Timer.fired() {
	if (!sendBusy) {
		sendMessage();
	}
	seqno++;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Application", "CounterApp event NetworkAMSend.sendDone(0x%1x, %d)",
					msg, error);
	sendBusy = FALSE;
}


event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	CounterMsg* cm = (CounterMsg*)payload;

	dbg("Application", "CounterApp event NetworkReceive.receive(0x%1x, 0x%1x, %d)", msg, payload, len); 
	dbg("Application", "CounterApp receive seqno: %d source: %d", cm->seqno, cm->source); 
	//dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, cm->seqno, cm->source);
	call Leds.set(cm->seqno);
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

}
