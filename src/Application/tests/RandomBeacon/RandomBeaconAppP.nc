/*
 *  RandomBeacon test application module for Fennec Fox platform.
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
 * Network: RandomBeacon test Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include <Timer.h>
#include "RandomBeaconApp.h"

module RandomBeaconAppP {
provides interface SplitControl;

uses interface RandomBeaconAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Leds;
uses interface Timer<TMilli>;
uses interface Random;

}

implementation {

/**
 Available Parameters:
	uint16_t delay,
	uint16_t delay_scale,
*/


message_t packet;
bool sendBusy = FALSE;

task void set_timer() {
	call Timer.startOneShot((call Random.rand32()) % 
		(call RandomBeaconAppParams.get_delay() * 
		call RandomBeaconAppParams.get_delay_scale()));
}


command error_t SplitControl.start() {
	//call Leds.led0On();
	//dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);
	dbg("Application", "RandomBeaconApp SplitControl.start()");

	post set_timer();

	sendBusy = FALSE;
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	dbg("Application", "RandomBeaconApp SplitControl.stop()");
	//dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

void sendMessage() {
	RandomBeaconMsg* msg = (RandomBeaconMsg*)call NetworkAMSend.getPayload(&packet,
							sizeof(RandomBeaconMsg));
	call Leds.led1Toggle();
	if (msg == NULL) {
		return;
	}

	msg->source = TOS_NODE_ID;
	msg->seqno = call Random.rand32();

	dbg("Application", "RandomBeaconApp sendMessage() seqno: %d source: %d", msg->seqno, msg->source); 
	dbgs(F_APPLICATION, S_NONE, DBGS_SEND_DATA, msg->seqno, msg->source);

	if (call NetworkAMSend.send(BROADCAST, &packet, 
					sizeof(RandomBeaconMsg)) != SUCCESS) {
	} else {
		dbg("Application", "RandomBeaconApp call NetworkAMSend.send(%d, 0x%1x, %d)",
					BROADCAST, &packet,
					sizeof(RandomBeaconMsg));
		sendBusy = TRUE;
		call Leds.set(msg->seqno);
	}
}

event void Timer.fired() {
	if (!sendBusy) {
		sendMessage();
	}
	post set_timer();
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Application", "RandomBeaconApp event NetworkAMSend.sendDone(0x%1x, %d)",
					msg, error);
	sendBusy = FALSE;
}


event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	RandomBeaconMsg* cm = (RandomBeaconMsg*)payload;

	dbg("Application", "RandomBeaconApp event NetworkReceive.receive(0x%1x, 0x%1x, %d)", msg, payload, len); 
	dbg("Application", "RandomBeaconApp receive seqno: %d source: %d", cm->seqno, cm->source); 
	dbgs(F_APPLICATION, S_NONE, DBGS_RECEIVE_DATA, cm->seqno, cm->source);
	call Leds.set(cm->seqno);
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

}
