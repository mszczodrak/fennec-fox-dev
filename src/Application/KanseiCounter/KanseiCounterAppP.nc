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
#include "KanseiCounterApp.h"

#include "KanseiWork.h"

generic module KanseiCounterAppP(uint16_t delay, uint16_t src, uint16_t dest) {
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

  nx_struct kansei_msg serial_msg;

  command error_t Mgmt.start() {
    counter = 0;

    if ((dest != TOS_NODE_ID) && ((src == TOS_NODE_ID) || (src == NODE))) {
      call Timer0.startPeriodic(delay);
    }

    serial_msg.layer = F_APPLICATION;

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
    counter_msg_t *c;
    msg_t *message;

    serial_msg.data[0] = K_TIMER_FIRED;
    serial_msg.data[1] = 0;
    serial_msg.data[2] = 0;
    serial_msg.data[3] = 0;
    call Serial.send(&serial_msg, sizeof(nx_struct kansei_msg));

    message = signal Module.next_message();
    if (message == NULL) return;

    c = (counter_msg_t*) call NetworkCall.getPayload(message);
    if (c == NULL) {
      signal Module.drop_message(message);
      return;
    }

    call Leds.set(counter);

    c->counter = counter;
    c->from = TOS_NODE_ID;

    message->len = sizeof(counter_msg_t);
    message->next_hop = dest;

    dbg("Application", "Application Send Counter %d from %d to %d\n", counter, TOS_NODE_ID, dest);

    if (call NetworkCall.send(message) != SUCCESS) {
      signal Module.drop_message(message);
    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
//    serial_msg.data[0] = K_SEND;
//    serial_msg.data[1] = counter;
//    serial_msg.data[2] = TOS_NODE_ID;
//    serial_msg.data[3] = dest;
//    call Serial.send(&serial_msg, sizeof(nx_struct kansei_msg));

    if (err == SUCCESS) counter++;
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {

    counter_msg_t *c = (counter_msg_t*)payload;
    call Leds.set(c->counter);
    dbg("Application", "Application Receive Counter %d from %d to %d\n", c->counter, c->from, TOS_NODE_ID);

    serial_msg.data[0] = K_RECEIVE;
    serial_msg.data[1] = c->counter;
    serial_msg.data[2] = c->from;
    serial_msg.data[3] = dest;
    call Serial.send(&serial_msg, sizeof(nx_struct kansei_msg));

    signal Module.drop_message(msg);

  }

  event void Serial.receive(void *buf, uint16_t len) {

  }


}
