/*
 *  Temperature Sensing application for Fennec Fox platform.
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
 * Application: Sends temperature sensor value across the network
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2011
 */

#include <Fennec.h>
#include "SendTempApp.h"

generic module SendTempAppP(uint8_t window, uint16_t delay, uint16_t dest) {

  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<uint16_t> as Temperature;

  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint16_t counter;
  uint16_t values[window];

  command error_t Mgmt.start() {
    counter = 0;

    switch(TOS_NODE_ID) {

      case dest:
        setFennecStatus( F_BRIDGING, ON );
        setFennecStatus( F_PRINTING, ON );
        break;
    
      default:
        call Timer0.startPeriodic(delay);
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
    if (call Temperature.read() != SUCCESS) {

    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    temp_msg_t *temp = (temp_msg_t*)payload;
    call Leds.set(temp->counter);
    signal Module.drop_message(msg);
  }

  event void Temperature.readDone( error_t result, uint16_t val ) {
    uint8_t i;

    for(i = 0; !counter && i < window; i++) {
       values[i] = val;
    }

    if (result == SUCCESS) {
      uint32_t sum = 0;
      msg_t* message = signal Module.next_message();
      temp_msg_t *temp = (temp_msg_t*) call NetworkCall.getPayload(message);
      counter++;
      call Leds.set(counter);
      values[counter % window] = val;
      for (i = 0; i < window; i++) {
        sum += values[i];
      }
      temp->counter = counter;
      temp->value = sum / window;
      message->len = sizeof(temp_msg_t);
      message->next_hop = dest;
      call NetworkCall.send(message);
    }
  }
}
