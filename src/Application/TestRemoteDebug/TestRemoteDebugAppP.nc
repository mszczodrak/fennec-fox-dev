/*
 *  Test Remote Debug application for Fennec Fox platform.
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
 * Application: Test Remote Debug
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2012
 */


#include <Fennec.h>

generic module TestRemoteDebugAppP(uint16_t delay) {
  provides interface Mgmt;
  provides interface Module;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;


  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
}

implementation {

  uint16_t counter;

  command error_t Mgmt.start() {
    counter = 0;
    call Timer0.startPeriodic(delay);
    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_START, 0, 0);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer0.stop();
    call Leds.set(0);
    dbgs(F_APPLICATION, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    call Leds.set(counter);
    counter = (counter + 1) % 30000;
    dbgs(F_APPLICATION, S_NONE, DBGS_TEST_SIGNAL, counter, counter);
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
