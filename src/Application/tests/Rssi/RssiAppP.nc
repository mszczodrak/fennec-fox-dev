/*
 *  Rssi application module for Fennec Fox platform.
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
 * Application: Rssi Application Module
 * Author: Marcin Szczodrak
 * Date: 12/2/2013
 * Last Modified: 12/4/2013
 */

#include <Fennec.h>
#include "RssiApp.h"

module RssiAppP {
provides interface SplitControl;

uses interface RssiAppParams;

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

task void reset_led_timer() {
	call LedTimer.startOneShot(2 * call RssiAppParams.get_delay());
}

command error_t SplitControl.start() {
	dbg("Application", "RssiApp SplitControl.start()");
	call SendTimer.startPeriodic(call RssiAppParams.get_delay());
	post reset_led_timer();
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Application", "RssiApp SplitControl.start()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void NetworkAMSend.sendDone(message_t *msg, error_t error) {

}

event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
	metadata_t *meta = (metadata_t*)getMetadata(msg);
	int8_t rssi = (int8_t) meta->rssi;
	rssi -= 45;	/* cc2420 spec */

	signal LedTimer.fired();

	if (rssi > -90 ) {
		call Leds.led0On();
	}

	if (rssi > -65 ) {
		call Leds.led1On();
	}

	if (rssi > -40 ) {
		call Leds.led2On();
	}

	return msg;
}

event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}

event void SendTimer.fired() {
	memset(&packet, 0, sizeof(message_t));
	call NetworkAMSend.send(BROADCAST, &packet, 80);
}

event void LedTimer.fired() {
	call Leds.set(0);
	post reset_led_timer();
}

}
