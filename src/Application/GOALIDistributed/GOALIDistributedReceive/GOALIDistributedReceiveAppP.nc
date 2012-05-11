/*
 *  GOALI-Distributed : Receive application for Fennec Fox platform.
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
 * Application: GOALI project distributed-receive application
 * Author: Marcin Szczodrak
 * Date: 8/20/2011
 * Last Modified: 8/23/2011
 */

#include <Fennec.h>
#include "GOALIDistributedReceiveApp.h"
#define GOALI_DISTRIBUTED_RECEIVE_RETRY 50

generic module GOALIDistributedReceiveAppP(uint16_t delay, uint16_t bridge_node) {
  provides interface Mgmt;
  provides interface Module;
  uses interface Leds;
  uses interface Timer<TMilli> as Timer0;

  uses interface NetworkCall;
  uses interface NetworkSignal;

  uses interface GOALIBuffer;
}

implementation {

  uint16_t counter = 0;
  bool running = OFF;
  uint8_t num_of_nodes;
  uint8_t buffer[100];

  task void disseminate() {
    msg_t *message = signal Module.next_message();

    if (message != NULL) {
      uint8_t *data;
      nx_struct goali_distributed_receive_msg *header;

      data = call NetworkCall.getPayload(message);

      if (data == NULL) {
        signal Module.drop_message(message);
        call Timer0.startOneShot(GOALI_DISTRIBUTED_RECEIVE_RETRY);
        return;
      }

      header = (nx_struct goali_distributed_receive_msg*) data;

      counter++;

      header->counter = counter;
      header->node_id = TOS_NODE_ID;
      header->len = num_of_nodes;

      data += sizeof(nx_struct goali_distributed_receive_msg);
      /* data points to space where we put first the array */





      data += (sizeof(uint8_t) * num_of_nodes);
      /* data points to space where we put matrix */



      

      message->len = sizeof(nx_struct goali_distributed_receive_msg);
      message->next_hop = delay;

      dbg("Application", "Application GOALIDistributedReceive sends data c %d\n",
                                                                        counter);
      if (call NetworkCall.send(message) != SUCCESS) {
        signal Module.drop_message(message);
      }
    }
  }

  command error_t Mgmt.start() {
    running = ON;

    if (TOS_NODE_ID == bridge_node) {
      call Timer0.startPeriodic(delay);
    }

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
    num_of_nodes = 7;
    post disseminate();
  }

  event void NetworkSignal.sendDone(msg_t *msg, error_t err) {
    signal Module.drop_message(msg);
    if (running == ON && err != SUCCESS) {

    }
  }

  event void NetworkSignal.receive(msg_t *msg, uint8_t *payload, uint8_t size) {
    if (running == ON) {
      nx_struct goali_distributed_receive_msg *net_g =
	(nx_struct goali_distributed_receive_msg*)payload;

        dbg("Application", "Application Received message # %d from %d with value %d\n",
	net_g->counter, net_g->node_id, net_g->len);
    }
    signal Module.drop_message(msg);
  }
}
