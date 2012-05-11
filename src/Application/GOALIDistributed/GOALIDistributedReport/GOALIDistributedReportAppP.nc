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
#include "GOALIDistributedReportApp.h"

generic module GOALIDistributedReportAppP(uint16_t delay, uint16_t bridge_node) {
  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface NetworkCall;
  uses interface NetworkSignal;

  uses interface Serial;

  uses interface GOALIBuffer;
}

implementation {

  uint16_t counter = 0;
  uint16_t last_value = 13;
  bool running = OFF;

  task void send_message() {
    msg_t* message = signal Module.next_message();
    nx_struct goali_distributed_report_msg *g;
    if (message != NULL) {
      dbg("Application", "Application sends message\n");
      g = (nx_struct goali_distributed_report_msg*) call NetworkCall.getPayload(message);
      call Leds.set(counter);
      g->counter = counter;
      g->value = last_value;
      g->node_id = TOS_NODE_ID;
      dbg("Application", "Application sending %d %d %d\n", g->counter, g->value, g->node_id);
      message->len = sizeof(nx_struct goali_distributed_report_msg);
      message->next_hop = bridge_node;
      if (call NetworkCall.send(message) != SUCCESS) {
        dbg("Application", "Application Failed to send message\n");
        signal Module.drop_message(message);
      }
    }
  }

  command error_t Mgmt.start() {
    running = ON;
    call Timer0.startOneShot(delay);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    running = OFF;
    call Timer0.stop();
    call Leds.set(0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void Timer0.fired() {
    post send_message();
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
    if (running == ON && err != SUCCESS) 
	call Timer0.startOneShot(delay / 2);
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    if (running == ON) {
      nx_struct goali_distributed_report_msg *net_g = (nx_struct goali_distributed_report_msg*)payload;

      call Serial.send(payload, sizeof(nx_struct goali_distributed_report_msg));

      dbg("Application", "Application Received message # %d from %d with value %d\n",
	net_g->counter, net_g->node_id, net_g->value);
      call Leds.set(net_g->counter);
    }
    signal Module.drop_message(msg);
  }

  event void Serial.receive(void *buf, uint16_t len) {

  }

}
