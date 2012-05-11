/*
 *  Sending Counter application for Fennec Fox platform.
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
 * Application: Sends incremental counter value on the network
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2011
 */


#include <Fennec.h>
#include "TestIDEPApp.h"

generic module TestIDEPAppP(uint16_t delay, uint16_t src, uint16_t dest) {
  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint16_t counter;

  command error_t Mgmt.start() {
    counter = 1;

    if (TOS_NODE_ID < 10) {
        //setFennecStatus( F_BRIDGING, ON );
        //break;
        call Timer0.startPeriodic(delay);
    }

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
    msg_t* message = signal Module.next_message();
    testIDEP_msg_t *c = (testIDEP_msg_t*) call NetworkCall.getPayload(message);

    call Leds.set(counter);

    c->id = TOS_NODE_ID;
    c->counter = counter;

    message->len = sizeof(testIDEP_msg_t);
    message->next_hop = dest;

    dbg("Application", "Application Sending %d\n", counter);
    if (call NetworkCall.send(message) != SUCCESS) {
      signal Module.drop_message(message);
    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    if (err == SUCCESS) counter++;
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    uint8_t n = size / sizeof(testIDEP_msg_t);
    uint8_t i = 0;
    testIDEP_msg_t *tc;

    for(tc = (testIDEP_msg_t*)payload; i < n; i++) {
      dbg("Application", "Application got: [%d %d]\n", tc->id, tc->counter);
      tc++;
    }
    //dbg("Application", "Application Receiving %d\n", c->counter);
    signal Module.drop_message(msg);
  }

}
