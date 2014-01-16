/*
 * Copyright (c) 2011 Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Columbia University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COLUMBIA
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Author: Marcin Szczodrak
 * Date: 3/22/2011
 */

#include <Fennec.h>
#include "basicp2pNet.h"

module basicp2pNetP {
  provides interface Mgmt;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface FennecStatus;
  uses interface Addressing;
  uses interface MacCall;
  uses interface MacSignal;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
  uses interface Leds;
  uses interface Random;
}

implementation {

  uint16_t s_seq;
  bool routing;
  uint8_t resend_tries;
  msg_t *last_message;
  uint8_t last;
  uint8_t estimate_counter;
  uint8_t state;
  struct basicp2p_net_estimate etxs[BASICP2P_NET_MAX_ESTIMATES_ENTRIES];
  uint16_t my_etx_cost;
  nx_uint8_t *parent_addr;
  nx_uint8_t *discov_addr;

  task void do_send() {
    if ((last_message != NULL) && (call MacCall.send(last_message) != SUCCESS)) {
      dbg("Network", "Network: failed to send message\n");
      call Timer0.startOneShot(BASICP2P_NET_RESEND_DELAY);
      if (routing == TRUE) {
//        drop_message(last_message);
//        last_message = NULL;
//        routing = FALSE;
      } else {
        signal NetworkSignal.sendDone(last_message, FAIL);
      }
    }
  }

  task void send_discovery() {
    uint8_t *m;
    msg_t *msg = nextMessage();
    nx_struct basicp2p_net_header *header;

    if (msg == NULL) 
      return;

    m = call MacCall.getPayload(msg);
    header = (nx_struct basicp2p_net_header*) m;

    header->seq = ++s_seq;
    /* set discovery flag */
    header->flags = BASICP2P_NET_DISCOVERY;

    /* destination */
    m += sizeof(nx_struct basicp2p_net_header);
    call Addressing.copy((nx_uint8_t*)m, BROADCAST, msg);

    /* source */
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    /* set discovery src */
    m += call Addressing.length(msg);
    call Addressing.move((nx_uint8_t*)m, discov_addr, msg);

    /* set my etx cost */
    m += call Addressing.length(msg);
    memcpy(m, &my_etx_cost, sizeof(my_etx_cost));

    msg->next_hop = BROADCAST;
    msg->len = sizeof(nx_struct basicp2p_net_header) 
		+ 3 * call Addressing.length(msg) + sizeof(my_etx_cost);

    call Timer2.startOneShot(BASICP2P_NET_MAC_RESPOND);
    last_message = msg;

    post do_send();
  }

  task void send_estimate() {
    uint8_t *m;
    msg_t *msg = nextMessage();
    nx_struct basicp2p_net_header *header;

    if (msg == NULL)
      return;

    m = call MacCall.getPayload(msg);
    header = (nx_struct basicp2p_net_header*) m;

    header->seq = ++s_seq;
    /* set discovery flag */
    header->flags = BASICP2P_NET_ESTIMATE;

    /* destination */
    m += sizeof(nx_struct basicp2p_net_header);
    call Addressing.copy((nx_uint8_t*)m, BROADCAST, msg);

    /* source */
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    msg->next_hop = BROADCAST;
    msg->len = sizeof(nx_struct basicp2p_net_header) + 2 * call Addressing.length(msg);

    call Timer2.startOneShot(BASICP2P_NET_MAC_RESPOND);
    last_message = msg;

    post do_send();
  }

  task void start_estimate() {
    uint8_t i;
    if (estimate_counter == BASICP2P_NET_NUM_OF_ESTIMATES) {
      for(i = 0; i < BASICP2P_NET_MAX_ESTIMATES_ENTRIES; i++) {
        etxs[i].etx = BASICP2P_NET_NUM_OF_ESTIMATES - etxs[i].etx;
      }
      return;
    }

    if (estimate_counter == 0) {
      for(i = 0; i < BASICP2P_NET_MAX_ESTIMATES_ENTRIES; i++) {
        etxs[i].addr = NULL;
        etxs[i].etx = 0;
      }
    }

    call Timer0.startOneShot(call Random.rand16() % BASICP2P_NET_MAX_ESTIMATE_DELAY);

    estimate_counter++;
  }

  void receive_data(msg_t *msg, uint8_t *payload, uint8_t len) {
    uint8_t *m = payload + sizeof(nx_struct basicp2p_net_header);
    uint8_t app_len = msg->len - (sizeof(nx_struct basicp2p_net_header) + 2 * call Addressing.length(msg));
    if (len <= 0)
      return;

    /* check if node addr */
    if (call Addressing.eq((nx_uint8_t*)m, call Addressing.addr(NODE, msg), msg)) {
        msg->len = app_len;
        signal NetworkSignal.receive(msg, m + 2 * call Addressing.length(msg), msg->len);
        call MacCall.ack(msg);
        return;
    }

    /* check if oneHop */
    if (call Addressing.eq((nx_uint8_t*)m, call Addressing.addr(BROADCAST, msg), msg)) {
        msg->len = app_len;
        signal NetworkSignal.receive(msg, m + 2 * call Addressing.length(msg), msg->len);
        return;
    }

    /* check if bridge */
    if ((getFennecStatus(F_BRIDGING) == ON) && (call Addressing.eq((nx_uint8_t*)m, call Addressing.addr(BRIDGE, msg), msg))) {
        msg->len = app_len;
        signal NetworkSignal.receive(msg, m + 2 * call Addressing.length(msg), msg->len);
        call MacCall.ack(msg);
        return;
    }

    /* keep routing */
    call Addressing.move((nx_uint8_t*)&msg->next_hop, parent_addr, msg);
    if (last_message == NULL) {
      call Timer2.startOneShot(BASICP2P_NET_MAC_RESPOND);
      last_message = msg;
      routing = TRUE;
      post do_send();
    } else {
      /* We haven't send the last one yet */
      drop_message(msg);
    }
  }


  void receive_etx(msg_t *msg, uint8_t *payload, uint8_t len) {
    uint8_t i;
    uint8_t *src = call NetworkCall.getSource(msg);

    for(i = 0; i < BASICP2P_NET_MAX_ESTIMATES_ENTRIES; i++) {
      if (etxs[i].addr == NULL) {
        etxs[i].addr = malloc(call Addressing.length(msg));
        call Addressing.move(etxs[i].addr, (nx_uint8_t*)src, msg);
        etxs[i].etx = 1;
        break;
      }
      if (call Addressing.eq(etxs[i].addr, (nx_uint8_t*)src, msg)) {
        etxs[i].etx++; 
        break;
      } 
    }

    drop_message(msg); 
  }

  void receive_discovery(msg_t *msg, uint8_t *payload, uint8_t len) {
    uint8_t *t_parent = payload + sizeof(nx_struct basicp2p_net_header) 
				+ call Addressing.length(msg);
    uint8_t *t_discov = t_parent + call Addressing.length(msg);
    uint8_t *t_etx = t_discov + call Addressing.length(msg);
    uint16_t t_ext_cost;
    uint16_t t_hop_cost = 0;
    uint8_t i;

    for(i = 0; i < BASICP2P_NET_MAX_ESTIMATES_ENTRIES; i++) {
      if ((etxs[i].addr != NULL) && (call Addressing.eq(etxs[i].addr, (nx_uint8_t*)t_parent, msg))) {
        t_hop_cost = etxs[i].etx;
        break;
      }
    }

    if (t_hop_cost == 0) {
      drop_message(msg);
      return;
    }

    memcpy(&t_ext_cost, t_etx, sizeof(t_ext_cost));

    /* found better path */  
    if ((t_ext_cost + t_hop_cost) < my_etx_cost) {
      my_etx_cost = t_ext_cost + t_hop_cost; 
      if (parent_addr == NULL)
        parent_addr = malloc(call Addressing.length(msg));

      if (discov_addr == NULL)
        discov_addr = malloc(call Addressing.length(msg));

      call Addressing.move(parent_addr, (nx_uint8_t*)t_parent, msg);
      call Addressing.move(discov_addr, (nx_uint8_t*)t_discov, msg);
          
      call Timer1.startOneShot(call Random.rand16() % BASICP2P_NET_MAX_ESTIMATE_DELAY);
    
      drop_message(msg);
      return;
    }

    /* suggest better path */
/*
    if ((t_ext_cost + t_hop_cost + (BASICP2P_NET_NUM_OF_ESTIMATES / 2)) > my_etx_cost) { 
      if (! call Timer1.isRunning()) {
        call Timer1.startOneShot(call Random.rand16() % BASICP2P_NET_MAX_ESTIMATE_DELAY);
      }  
      drop_message(msg);
      return;
    }
*/

    drop_message(msg);
  }


  command error_t Mgmt.start() {
    last = 0;
    s_seq = 0;
    resend_tries = 0;
    routing = FALSE;
    estimate_counter = 0;
    my_etx_cost = BASICP2P_NET_MAX_ETX_COST;
    last_message = NULL;
    parent_addr = NULL;
    discov_addr = NULL;

    state = S_STARTING;
    call Timer1.startOneShot(BASICP2P_NET_MAX_ESTIMATE_DELAY * BASICP2P_NET_NUM_OF_ESTIMATES);
    post start_estimate();
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* NetworkCall.getPayload(msg_t* msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    return m + sizeof(nx_struct basicp2p_net_header) + 2 * call Addressing.length(msg);
  }

  command error_t NetworkCall.send(msg_t *msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    nx_struct basicp2p_net_header *header = (nx_struct basicp2p_net_header*) m;

    if ((parent_addr == NULL) || (last_message != NULL)) {
      dbg("Network", "Network: Can't accept the message\n");
      signal NetworkSignal.sendDone(msg, FAIL);
      return FAIL;
    }

    header->seq = ++s_seq;
    header->flags = 0;

    /* set data flag */
    header->flags = header->flags | BASICP2P_NET_DATA;

    /* destination */
    m += sizeof(nx_struct basicp2p_net_header);
    call Addressing.copy((nx_uint8_t*)m, msg->next_hop, msg);

    /* source */
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    call Addressing.move((nx_uint8_t*)&msg->next_hop, parent_addr, msg);

    msg->len += sizeof(nx_struct basicp2p_net_header) + 2 * call Addressing.length(msg);

    call Timer2.startOneShot(BASICP2P_NET_MAC_RESPOND);
    last_message = msg;

    post do_send();

    return SUCCESS;
  }

  command uint8_t NetworkCall.getMaxSize(msg_t *msg) {
    return (call MacCall.getMaxSize(msg) - sizeof(nx_struct basicp2p_net_header)
        - 2 * call Addressing.length(msg));
  }

  command uint8_t* NetworkCall.getSource(msg_t* msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    return m + sizeof(nx_struct basicp2p_net_header) + call Addressing.length(msg);
  }

  command uint8_t* NetworkCall.getDestination(msg_t* msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    return m + sizeof(nx_struct basicp2p_net_header);
  }

  event void MacSignal.sendDone(msg_t *msg, error_t err) {
    if (err != SUCCESS) {
      call Timer2.startOneShot(BASICP2P_NET_MAC_RESPOND);
      last_message = msg;
      call Timer0.startOneShot(BASICP2P_NET_RESEND_DELAY);
    } else {
      uint8_t *m = call MacCall.getPayload(msg);
      nx_struct basicp2p_net_header *header = (nx_struct basicp2p_net_header*) m;
      switch( header->flags ) {
        case BASICP2P_NET_DATA:
          if (routing) {
            drop_message(msg);
            routing = FALSE;
            call Leds.set(routing);
          } else {
            signal NetworkSignal.sendDone(msg, err);
          }
          break;

        case BASICP2P_NET_DISCOVERY:
          drop_message(msg);
          break;

        case BASICP2P_NET_ESTIMATE:
          drop_message(msg);
	  post start_estimate();
          break;

        default:
          drop_message(msg);
          break;
      }
    }
    call Timer2.stop();
    last_message = NULL;
  }

  event void MacSignal.receive(msg_t *msg, uint8_t *payload, uint8_t len) {
    nx_struct basicp2p_net_header *header = (nx_struct basicp2p_net_header*) payload;

    switch( header->flags ) {

      case BASICP2P_NET_DATA:
        receive_data(msg, payload, len);
        break;

      case BASICP2P_NET_DISCOVERY:
        receive_discovery(msg, payload, len);
        break;

      case BASICP2P_NET_ESTIMATE:
        receive_etx(msg, payload, len);
        break;

      default:
        drop_message(msg);
        break;
    }
  }

  event void Timer0.fired() {
    switch(state) {
      case S_STARTING:
        post send_estimate();
        break;

      default:
        if (last_message == NULL) 
          return;

        if (call MacCall.send(last_message) != SUCCESS) {
          if( ++resend_tries > BASICP2P_NET_RESEND_TRIES) {
            signal NetworkSignal.sendDone(last_message, FAIL);
            resend_tries = 0;
          } else {
            call Timer0.startOneShot(BASICP2P_NET_RESEND_DELAY);
          }
        } else {
          resend_tries = 0;
        }
      }
  }

  event void Timer1.fired() {
    switch(state) {
      case S_STARTING:
        state = S_STARTED;
        signal Mgmt.startDone(SUCCESS);
        break;

      default:
        post send_discovery();
    }
  }


  event void Timer2.fired() {
    dbg("Network", "Network: has no sendDone responce from MAC\n");
    signal NetworkSignal.sendDone(last_message, FAIL);
    last_message = NULL;
  }

  event void FennecStatus.update(uint8_t flag, bool status) {
    if (flag == F_BRIDGING) {
      msg_t *t = nextMessage();
      parent_addr = malloc(call Addressing.length(t));
      discov_addr = malloc(call Addressing.length(t));
      call Addressing.copy(parent_addr, NODE, t);
      call Addressing.copy(discov_addr, NODE, t);
      my_etx_cost = 0;
      drop_message(t);
      call Timer1.startOneShot(0);
    }
  }

}
