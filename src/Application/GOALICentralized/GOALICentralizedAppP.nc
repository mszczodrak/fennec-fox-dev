/*
 *  GOALI-Centralized application for Fennec Fox platform.
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
 * Application: GOALI project centralized application
 * Author: Marcin Szczodrak
 * Date: 8/15/2011
 * Last Modified: 8/15/2011
 */

#include <Fennec.h>
#include "GOALICentralizedApp.h"

generic module GOALICentralizedAppP(uint16_t delay, uint16_t bridge_node) {
  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;

  uses interface Read<uint16_t> as Occupancy;

  uses interface NetworkCall;
  uses interface NetworkSignal;

  uses interface Serial;
}

implementation {

  uint16_t counter = 0;
  uint16_t last_value;
  bool running = OFF;

  task void send_message() {
    msg_t* message;
    goali_centralized_msg_t *g;

    if (running == OFF) {
      return;
    }

    message = signal Module.next_message();

    if (message != NULL) {
      //dbg("Application", "Application sends message\n");
      g = (goali_centralized_msg_t*) call NetworkCall.getPayload(message);
      call Leds.set(counter);
      g->counter = counter;
      g->value = last_value;
      g->node_id = TOS_NODE_ID;
      dbg("Application", "Application sending %d %d %d\n", g->counter, g->value, g->node_id);
      message->len = sizeof(goali_centralized_msg_t);
      message->next_hop = bridge_node;
      if (call NetworkCall.send(message) != SUCCESS) {
        dbg("Application", "Application Failed to send message\n");
        signal Module.drop_message(message);
      }
    }
  }

  command error_t Mgmt.start() {
    running = ON;

    dbg("Application", "Application GOALICentral started\n");

    switch(TOS_NODE_ID) {

      case bridge_node:
        break;

      default:
        call Timer0.startOneShot(delay);
        break;
    }

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    running = OFF;
    call Timer0.stop();
    call Timer1.stop();
    call Leds.set(0);
    dbg("Application", "Application GOALICentral stoped\n");
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    if (running == ON) {
      counter++;
      if (call Occupancy.read() != SUCCESS) {
        /* so far we skip reporting */
      }
    }
  }

  event void Timer1.fired() {
    if (running == ON) {
      post send_message();
    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
    if (running == ON && err != SUCCESS) {
      dbg("Application", "Application: Sending was a failure\n");
      call Timer1.startOneShot(delay / 4);
    }
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    if (running == ON) {
      goali_centralized_msg_t *net_g = (goali_centralized_msg_t*)payload;

      call Serial.send(payload, sizeof(goali_centralized_msg_t));

      dbg("Application", "Application Received message # %d from %d with value %d\n",
	net_g->counter, net_g->node_id, net_g->value);
      call Leds.set(net_g->counter);
    }
    signal Module.drop_message(msg);
  }

  event void Occupancy.readDone( error_t result, uint16_t val ) {
    if (running == ON && result == SUCCESS) {
      last_value = val;
      post send_message();
    }
  }

  event void Serial.receive(void *buf, uint16_t len) {
    
  }
}
