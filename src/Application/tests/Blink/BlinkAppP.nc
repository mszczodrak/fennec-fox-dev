/*
 *  Blinking application for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2011 Marcin Szczodrak
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
 * Application: LED blinking
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 5/2/2012
 */

#include <Fennec.h>

module BlinkAppP {

  provides interface Mgmt;
  provides interface Module;

  uses interface BlinkAppCParams;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;

  uses interface Leds;
  uses interface Timer<TMilli> as Timer;
}

implementation {
  bool on;

  command error_t Mgmt.start() {
    dbg("Application", "Application Blink(%d, %d) start\n", 
	call BlinkAppCParams.get_led(), BlinkAppCParams.get_delay());
    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);
    on = 0;
    call Timer.startPeriodic(call BlinkAppCParams.get_delay());
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer.stop();
    call Leds.set(0);
    dbg("Application", "Application Blink(%d, %d) stop\n", 
	call BlinkAppCParams.get_led(), BlinkAppCParams.get_delay());

    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer.fired() {
    dbg("Application", "Application Blink set LED to %d\n", 
				call BlinkAppCParams.get_led());
    //dbgs(F_APPLICATION, S_NONE, DBGS_BLINK_LED, call BlinkAppCParams.get_led(), on);
    on ? call Leds.set(0) : call Leds.set(call BlinkAppCParams.get_led()) ;
    on = !on;
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

  event void BlinkAppCParams.receive_status(uint16_t status_flag) {
  }
}
