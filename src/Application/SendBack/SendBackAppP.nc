/*
 *  Send Back application for Fennec Fox platform.
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
 * Application: Send back incremental counter value on the network
 * Author: Marcin Szczodrak
 * Date: 8/13/2011
 * Last Modified: 8/13/2011
 */

#include <Fennec.h>
#include "SendBackApp.h"

generic module SendBackAppP(uint16_t delay, uint16_t min_delay, uint16_t src, uint16_t dest) {
  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface NetworkCall;
  uses interface NetworkSignal;
  uses interface Random;
}

implementation {

  uint16_t counter;

  uint16_t get_random() {
    if (delay) {
      return (call Random.rand16() % delay) + min_delay;
    } else {
      return min_delay;
    }
  }

  command error_t Mgmt.start() {
    counter = 3;

    switch(TOS_NODE_ID) {

      case dest:
        setFennecStatus( F_BRIDGING, ON );
        break;
   
      case src:
        call Timer0.startOneShot(get_random() + 3 * min_delay);
        break;
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
    send_back_msg_t *c = (send_back_msg_t*) call NetworkCall.getPayload(message);
    counter++;

    call Leds.set(counter);

    c->counter = counter;

    message->len = sizeof(send_back_msg_t);

    if (TOS_NODE_ID == src) {
      message->next_hop = dest;
    } else {
      message->next_hop = src;
    }

    dbg("Application", "Application Sending %d\n", counter);
    if (call NetworkCall.send(message) != SUCCESS) {
      signal Module.drop_message(message);
    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    if (err == SUCCESS) {
      printf("Ap: SUCCESS\n");
    } else {
      printf("Ap: FAIL\n");
    }
    printfflush();
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    send_back_msg_t *c = (send_back_msg_t*)payload;
    call Leds.set(c->counter);
    counter = c->counter;
    dbg("Application", "Application Receiving %d\n", c->counter);
    signal Module.drop_message(msg);
    call Timer0.startOneShot(get_random());
  }

}
