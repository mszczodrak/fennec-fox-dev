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
provides interface Mgmt;
provides interface Module;

uses interface timerMilliAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
uses interface ModuleStatus as NetworkStatus;

uses interface Timer<TMilli>;
provides interface Event;
}

implementation {

/** Available Parameters
	uint32_t delay = 1000,
	uint16_t src = 0
*/


uint16_t threshold;
uint8_t op;
am_addr_t addr;
bool occures;

command error_t Mgmt.start() {
	occures = FALSE;
	dbg("Application", "timerMilliApp Mgmt.start()");
	signal Mgmt.startDone(SUCCESS);
/*
	threshold = en->value;

call CounterAppParams.get_delay()

	op = en->operation;
	addr = en->addr;
	if ((NODE == addr) || (TOS_NODE_ID == addr)) {
		call Timer.startPeriodic(DEFAULT_FENNEC_SENSE_PERIOD);
		dbg("TimerEvent", "TimerEvent started with op %d and value %d\n", op, threshold);
	}
*/
	return SUCCESS;
}

command error_t Mgmt.stop() {
	call Timer.stop();
	dbg("TimerEvent", "TimerEvent stopped\n");
	dbg("Application", "timerMilliApp Mgmt.start()");
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}


event void Timer.fired() {
	dbg("TimerEvent", "TimerEvent: fired to check the event occurance\n");

	switch(op) {
	case EQ:
		if (occures) {
			occures = FALSE;
			signal Event.occured(FALSE);
		}
		break;

	case NQ:
		if (!occures) {
			occures = TRUE;
			signal Event.occured(TRUE);
		}
	break;

	case LT:
	case LE:
		if (!occures) {
			occures = TRUE;
			signal Event.occured(TRUE);
		}
		if (occures) {
			occures = FALSE;
			signal Event.occured(FALSE);
		}
		break;

	case GT:
	case GE:
		if (!occures) {
			occures = TRUE;
			signal Event.occured(TRUE);
		}
		if (occures) {
			occures = FALSE;
			signal Event.occured(FALSE);
		}
		break;

	default:
		dbg("TimerEvent", "TimerEvent testing event occrence but with unknown operator\n");
	}
}




event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
}


}
