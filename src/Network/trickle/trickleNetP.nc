/*
 *  Trickle network module for Fennec Fox platform.
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
 * Network: Trickle Dissemination Protocol
 * Author: Marcin Szczodrak
 * Date: 9/18/2011
 * Last Modified: 9/19/2011
 */


#include <Fennec.h>
#include "trickleNet.h"

generic module trickleNetP(uint16_t short_period, uint16_t long_period, 
                                uint16_t period_threshold, uint16_t scale) {
  provides interface Mgmt;
  provides interface Module;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface Addressing;
  uses interface MacCall;
  uses interface MacSignal;

  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Random;
}

implementation {

  uint16_t seq = 0;
  uint16_t period;
  uint16_t counter;

  msg_t *local_buffer;
  msg_t *apps_message;
  bool sending_data;

  task void send_data() {
    dbg("Network", "Network trickle sends data with sequence %d\n", seq);
    if (call MacCall.send(local_buffer) != SUCCESS) {
      dbg("Network", "Network failed to send app data, retry\n");
      call Timer0.startOneShot(call Random.rand16() % TRICKLE_MAX_SEND_DELAY);
    }
  }


  task void send_beacon() {
    msg_t *msg = signal Module.next_message();
    nx_struct trickle_net_header *header;

    if (msg == NULL) {
      return;
    }

    dbg("Network", "Network trickle is sending beacon\n");

    header = (nx_struct trickle_net_header*) call MacCall.getPayload(msg);
    header->seq = seq;
    header->flags = TRICKLE_BEACON;

    msg->len = sizeof(nx_struct trickle_net_header);
    msg->next_hop = BROADCAST;

    if (call MacCall.send(msg) != SUCCESS) {
      signal Module.drop_message(msg);
    }
  }

  command error_t Mgmt.start() {
    nx_struct trickle_net_header *header;
    counter = 0;
    sending_data = FALSE;
    apps_message = NULL;

    /* by default start with long period */
    period = long_period;  
    call Timer1.startOneShot(period);

    local_buffer = signal Module.next_message();  

    if (local_buffer == NULL) {
      signal Mgmt.startDone(FAIL);
      return FAIL;
    }

    header = (nx_struct trickle_net_header*) call MacCall.getPayload(local_buffer);
    header->seq = seq;
    header->flags = TRICKLE_BEACON;

    local_buffer->len = sizeof(nx_struct trickle_net_header);
    local_buffer->next_hop = BROADCAST;

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer0.stop();
    call Timer1.stop();
    signal Module.drop_message(local_buffer);
    signal Module.drop_message(apps_message);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* NetworkCall.getPayload(msg_t* msg) {
    return call MacCall.getPayload(msg) + sizeof(nx_struct trickle_net_header);
  }

  command error_t NetworkCall.send(msg_t *msg) {
    nx_struct trickle_net_header *header = (nx_struct trickle_net_header*) 
						call MacCall.getPayload(msg);
    if (apps_message != NULL) {
      dbg("Network", "Network: trickle is busy\n");
      return FAIL;
    }

    header->seq = ++seq;
    header->flags = TRICKLE_DATA;
 
    msg->len += sizeof(nx_struct trickle_net_header);
    msg->next_hop = BROADCAST;

    apps_message = msg;
    sending_data = TRUE;
    counter = 0;
    period = short_period;
    call Timer1.startOneShot(period);

    memcpy(local_buffer, msg, sizeof(msg_t));

    call Timer0.startOneShot(call Random.rand16() % TRICKLE_MAX_SEND_DELAY);

    return SUCCESS;
  }

  command uint8_t NetworkCall.getMaxSize(msg_t *msg) {
    return call MacCall.getMaxSize(msg) - sizeof(nx_struct trickle_net_header);
  }

  command uint8_t* NetworkCall.getSource(msg_t* msg) {
    return NULL;
  }

  command uint8_t* NetworkCall.getDestination(msg_t* msg) {
    return NULL;
  }

  event void MacSignal.sendDone(msg_t *msg, error_t err) {
    nx_struct trickle_net_header *header = (nx_struct trickle_net_header*)
                                              call MacCall.getPayload(msg);
    sending_data = FALSE;

    //dbg("Network", "Network got send done\n");
    if (apps_message != NULL && apps_message == msg) {
      apps_message = NULL;
      dbg("Network", "Network sent apps data, signal send done\n");
      signal NetworkSignal.sendDone(msg, err);
      period = short_period;
      call Timer0.startOneShot(period);
      return;
    }

    if (header->flags == TRICKLE_DATA) {
      //dbg("Network", "Network sent data\n");
    } else {
      signal Module.drop_message(msg);
      //dbg("Network", "Network sent beacon\n");
    }
  }

  event void MacSignal.receive(msg_t *msg, uint8_t *payload, uint8_t len) {
    nx_struct trickle_net_header *header = (nx_struct trickle_net_header *)payload;

    //dbg("Network", "Network received message\n");

    if (len <= 0) {
      //dbg("Network", "Network received too small message\n");
      signal Module.drop_message(msg);
      return;
    }

    if (header->seq == seq) {
      /* same sequence */
      counter++;	
      //dbg("Network", "Network receive the same sequence %d, increase counter to %d\n",
									//seq, counter);
      signal Module.drop_message(msg); 
      return;
    }

    if (header->seq < seq) {
      dbg("Network", "Network trickle seq less %d < %d\n", header->seq, seq);

      signal Module.drop_message(msg); 
      sending_data = TRUE;
      counter = 0;
      call Timer0.startOneShot(call Random.rand16() % TRICKLE_MAX_SEND_DELAY);
      return;
    }

    if (header->seq > seq) {
      /* new sequence number */
      dbg("Network", "Network trickle seq greater %d > %d\n", header->seq, seq);

      if (header->flags == TRICKLE_DATA) {
        seq = header->seq;
        counter = 0;
        period = short_period;
        call Timer1.startOneShot(period);

        memcpy(local_buffer, msg, sizeof(msg_t));

        msg->len -= sizeof(nx_struct trickle_net_header);
        payload += sizeof(nx_struct trickle_net_header);

        signal NetworkSignal.receive(msg, payload, msg->len);
      } else {
        counter = 0;
        call Timer0.startOneShot(call Random.rand16() % TRICKLE_MAX_SEND_DELAY);
        signal Module.drop_message(msg);
      }
    }
  }


  /* The t timer */
  event void Timer0.fired() {
    if (counter < period_threshold) {
      if (sending_data) {
        dbg("Network", "Network sends apps' data with seq %d\n", seq);
        post send_data();
      } else {
        //dbg("Network", "Network sends beacon %d - counter is %d and threshold is %d\n",
	//  seq, counter, period_threshold);
        post send_beacon();
      }
    }
  }


  /* The Tau timer */
  event void Timer1.fired() {
    /* check if we have already transmitted */

//    dbg("Network", "Network: end of period check status\n");
    counter = 0;
    sending_data = FALSE;

    period *= scale;

    if (long_period < period) {
      period = long_period;
    }

    call Timer1.startOneShot(period);
    call Timer0.startOneShot(call Random.rand16() % period);
  }


}
