/*
 *  Test Serial application for Fennec Fox platform.
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
 * Application: Test Serial Communication
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2012
 */


#include <Fennec.h>
#include "TestSerialApp.h"

generic module TestSerialAppP(uint16_t delay) {
  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface NetworkCall;
  uses interface NetworkSignal;

  uses interface Serial;
}

implementation {

  uint16_t counter;

  nx_struct serial_pkt serial_msg;

  command error_t Mgmt.start() {
    counter = 0;
    call Timer0.startPeriodic(delay);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer0.stop();
    call Leds.set(0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    serial_msg.counter = ++counter;
    call Serial.send(&serial_msg, sizeof(nx_struct serial_pkt));
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
  }

  event void Serial.receive(void *buf, uint16_t len) {
  }

}
