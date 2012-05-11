/*
 *  Sense Environment application for Fennec Fox platform.
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
 * Application: Senses temperature humidity and light and sends the readings over the network
 * Author: Marcin Szczodrak
 * Date: 4/20/2010
 * Last Modified: 9/16/2011
 */


#include <Fennec.h>
#include "SenseEnvironmentApp.h"

generic module SenseEnvironmentAppP(uint16_t delay, uint16_t dest) {

  provides interface Mgmt;
  provides interface Module;

  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<uint16_t> as Temperature;
  uses interface Read<uint16_t> as Humidity;
  uses interface Read<uint16_t> as Light;

  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  uint16_t counter;
  msg_t* message;
  nx_struct env_msg *env;

  command error_t Mgmt.start() {
    counter = 0;

    if (TOS_NODE_ID == dest) {
      setFennecStatus( F_BRIDGING, ON );
    } else {
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
    message = signal Module.next_message();
    env = (nx_struct env_msg*) call NetworkCall.getPayload(message);

    counter++;
    env->node_id = TOS_NODE_ID;
    env->counter = counter;

    call Leds.set(counter);
    if (call Temperature.read() != SUCCESS) {
      signal Module.drop_message(message);
    }
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    env = (nx_struct env_msg*)payload;

    send_serial(payload, sizeof(nx_struct env_msg));

    call Leds.set(env->counter);
    dbg("Application", "SenseEnvironmentAppP : Received msg # %d: temp %d, humidity %d, light %d\n", 
		env->counter, env->temp, env->hum, env->light);

    signal Module.drop_message(msg);
  }

  event void Temperature.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      env->temp = val;
    } else {
      signal Module.drop_message(message);
      return;
    } 

    if (call Humidity.read() != SUCCESS) {
      signal Module.drop_message(message);
    }
  }

  event void Humidity.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      env->hum = val;
    } else {
      signal Module.drop_message(message);
      return;
    } 

    if (call Light.read() != SUCCESS) {
      signal Module.drop_message(message);
    }
  }

  event void Light.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      env->light = val;
    } else {
      signal Module.drop_message(message);
      return;
    } 

    message->len = sizeof(nx_struct env_msg);
    message->next_hop = dest;

    if ((call NetworkCall.send(message)) != SUCCESS) {
      dbg("Application", "SenseEnvironmentAppP : failed to send a message\n");
      signal Module.drop_message(message);
    } else {
      dbg("Application", "SenseEnvironmentAppP : send a message with counter %d\n", env->counter);
    }
  }
}
