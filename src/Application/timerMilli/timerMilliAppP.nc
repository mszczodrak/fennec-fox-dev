/*
 *  timer application module for Fennec Fox platform.
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
 * Application: timer Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "timerMilliApp.h"

module timerMilliAppP {
provides interface SplitControl;

uses interface timerMilliAppParams;

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
	dbg("Application", "timerMilliApp SplitControl.start()");
	dbg("Application", "timerMilliApp src: %d", call timerMilliAppParams.get_src());

	if ((call timerMilliAppParams.get_src() == BROADCAST) || 
		(call timerMilliAppParams.get_src() == TOS_NODE_ID)) {
		dbg("Application", "timerMilliApp will fire in %d ms", call timerMilliAppParams.get_delay());
		call Timer.startOneShot(call timerMilliAppParams.get_delay());

	}
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	call Timer.stop();
	dbg("Application", "timerMilliApp SplitControl.stop()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}


event void Timer.fired() {
	dbg("Application", "timerMilliApp signal Event.occured(TRUE)");
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
