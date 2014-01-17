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
 * Application: implementation of MAC Flush protocol
 *              see "Flush: a reliable bulk transport protocol for multihop 
                wireless networks" by Kim.
 * Author: Marcin Szczodrak
 * Date: 11/25/2011
 */

#include <Fennec.h>
#include "flush.h"

generic module flushP() {
  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Queue<struct qe_msg> as msgsQueue;
  uses interface Queue<struct qe_msg> as unACKedQueue;
}

implementation {

  bool sniffing;

  void send_ack(nx_uint8_t *dest, nx_uint8_t ack_seq);
  void received_ack(nx_struct simpleControlRate_mac_header *header);
  error_t found_duplicate(struct qe_msg *new_msg);

  uint8_t state = S_STOPPED;
  nx_uint8_t seq;

  command error_t Mgmt.start() {
    atomic sniffing = FALSE;
    signal Mgmt.startDone(SUCCESS);
    state = S_STARTED;
    seq = 0;
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call Timer0.stop();
    call Timer1.stop();
    state = S_STOPPED;
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    if (state == S_STOPPED) return NULL;

    return (call RadioCall.getPayload(msg)
		+ sizeof(nx_struct simpleControlRate_mac_header)
                + 2 * call Addressing.length(msg)
                );
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    if (state == S_STOPPED) return 0;

    return (call RadioCall.getMaxSize(msg)
		- sizeof(nx_struct simpleControlRate_mac_header)
		- 2 * call Addressing.length(msg)
		- sizeof(nx_struct simpleControlRate_mac_footer)
		);
  }

  event void Timer0.fired() {
    if((!call msgsQueue.empty()) && (state == S_STARTED)) {
      if ((call RadioCall.load((call msgsQueue.headptr())->msg)) == SUCCESS) {
        dbg("Mac", "Flush Loading seq %d\n", (call msgsQueue.headptr())->seq);
        state = S_LOADING;
      }
    }
  }

  event void Timer1.fired() {
    uint8_t i = call unACKedQueue.size();
    uint32_t delta = call Timer1.getdt();
    uint32_t next_fire = SIMPLECONTROL_ACK_WAIT_TIME + 1;

    struct qe_msg q;

    while(i--) {
      q = call unACKedQueue.dequeue();
      if (q.timeup <= delta) {
        if (--q.resend == 0) {
          dbg("Mac", "Mac: That's it! No more resending of this message\n");
          signal MacSignal.sendDone(q.msg, FAIL);
        } else {
          dbg("Mac", "Flush: Unacked message, resend\n");
          call msgsQueue.enqueue(q);
        }
      } else {
        q.timeup -= delta;
        if (q.timeup < next_fire) {
          next_fire = q.timeup;
        }
        call unACKedQueue.enqueue(q);
      }
    }
    if (! call unACKedQueue.empty()) {
      call Timer1.startOneShot(next_fire);
    }
  }

  command error_t MacCall.send(msg_t *msg) {
    uint8_t *m;
    nx_struct simpleControlRate_mac_header *header;
    struct qe_msg q;

    if (state == S_STOPPED) return FAIL;

    m = call RadioCall.getPayload(msg);
    if (m == NULL) return FAIL;

    header = (nx_struct simpleControlRate_mac_header*)m;

    dbg("Mac", "Flush: send\n");

    if (call msgsQueue.full()) {
      dbg("Mac", "Can't accept more\n");
      signal MacSignal.sendDone(msg, FAIL);
      return FAIL;
    }

    seq = ++seq % SIMPLECONTROL_MAX_SEQUENCE;

    q.msg = msg;
    q.seq = seq;
    q.resend = SIMPLECONTROL_MAX_RESEND;
    q.payload = call MacCall.getPayload(msg);

    if (found_duplicate(&q) == TRUE) {
      dbg("Mac", "Flush: found sender duplicate\n");
      return FAIL;
    }
    if (call msgsQueue.enqueue(q) != SUCCESS) return FAIL;

    dbg("Mac", "Q size is %d\n", call msgsQueue.size());

    msg->len += (sizeof(nx_struct simpleControlRate_mac_header)
		+ 2 * call Addressing.length(msg) 
		+ sizeof(nx_struct simpleControlRate_mac_footer));
		
    header->len = msg->len;
    header->seq = seq;

    if (call Addressing.eq((nx_uint8_t*)&msg->next_hop, call Addressing.addr(BROADCAST, msg), msg)){
      /* if it's broadcast, we do not need ACK */
      header->flag = SIMPLECONTROL_DATA_NO_ACK_FLAG;
    } else {
      dbg("Mac", "Flush: set ACK flag\n");
      header->flag = SIMPLECONTROL_DATA_TO_ACK_FLAG;
    }

    q.flag = header->flag;

    m += sizeof(nx_struct simpleControlRate_mac_header);

    /* set destination address */
    call Addressing.copy((nx_uint8_t*)m, msg->next_hop, msg);

    /* set source address */ 
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    dbg("Mac", "Flush: messages with seq %d enqueued\n", q.seq);

    if (!call Timer0.isRunning()) {
      call Timer0.startOneShot(1);
    }

    return SUCCESS;
  }

  command uint8_t* MacCall.getSource(msg_t *msg) {
    if (state == S_STOPPED) return NULL;

    return (call RadioCall.getPayload(msg) 
		+ sizeof(nx_struct simpleControlRate_mac_header)
                + call Addressing.length(msg) 
		);
  }

  command uint8_t* MacCall.getDestination(msg_t *msg) {
    if (state == S_STOPPED) return NULL;

    return (call RadioCall.getPayload(msg) 
		+ sizeof(nx_struct simpleControlRate_mac_header)
		);
  }

  command error_t MacCall.ack(msg_t *msg) {
    return SUCCESS;
  }

  command error_t MacCall.sniffing(bool flag, msg_t *msg) {
    atomic sniffing = flag;
    return SUCCESS;
  }
  
  event void RadioSignal.receive(msg_t* msg, uint8_t *payload, uint8_t len) {
    nx_struct simpleControlRate_mac_header *header;

    if (state == S_STOPPED) {
      signal Module.drop_message(msg);
      return;
    }

    header = (nx_struct simpleControlRate_mac_header*)payload;

    payload += 2 * call Addressing.length(msg) + sizeof(nx_struct simpleControlRate_mac_header);

    msg->len -= (sizeof(nx_struct simpleControlRate_mac_header)
			+ 2 * call Addressing.length(msg)
			+ sizeof(nx_struct simpleControlRate_mac_footer)
		);

    switch(header->flag) {
      case SIMPLECONTROL_DATA_TO_ACK_FLAG:
        send_ack((nx_uint8_t*)call MacCall.getSource(msg), header->seq);
        signal MacSignal.receive(msg, payload, msg->len);
	break;

      case SIMPLECONTROL_DATA_NO_ACK_FLAG:
        signal MacSignal.receive(msg, payload, msg->len);
	break;

      case SIMPLECONTROL_ACK_BACK_FLAG:
        received_ack(header);
        signal Module.drop_message(msg);
	break;

      default:
        signal Module.drop_message(msg);
    }
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error) {
    nx_struct simpleControlRate_mac_header *header;
    struct qe_msg q;
    struct qe_msg *q_ptr;

    if (state == S_STOPPED) {
      signal Module.drop_message(msg);
      return;
    }

    header = (nx_struct simpleControlRate_mac_header*) call RadioCall.getPayload(msg);

    state = S_STARTED;

    dbg("Mac", "Flush sendDone\n");

    switch(header->flag) {
      case SIMPLECONTROL_DATA_TO_ACK_FLAG:
        q = call msgsQueue.dequeue();
        q.timeup = SIMPLECONTROL_ACK_WAIT_TIME;
        if (!call Timer1.isRunning()) {
          call Timer1.startOneShot(SIMPLECONTROL_ACK_WAIT_TIME);
        }
        if (!call Timer0.isRunning()) {
          call Timer0.startOneShot(SIMPLECONTROL_MIN_DELAY * SIMPLECONTROL_NEIGHBORHOOD_SIZE);
        }

        call unACKedQueue.enqueue(q);
        break;

      case SIMPLECONTROL_DATA_NO_ACK_FLAG:
        q = call msgsQueue.dequeue();
        signal MacSignal.sendDone(q.msg, error);
        break;

      case SIMPLECONTROL_ACK_BACK_FLAG:
        q_ptr = call msgsQueue.headptr();
        if ((q_ptr->seq == header->seq) && (q_ptr->flag == header->flag)) {
          call msgsQueue.dequeue();
        }
        
        signal Module.drop_message(msg);
        break;

      default:
        signal Module.drop_message(msg);
    }

    if ((! call msgsQueue.empty()) && (! call Timer0.isRunning())) {
       call Timer0.startOneShot(1);
    }
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error) {
    if (state == S_STOPPED) {
      signal Module.drop_message(msg);
      return;
    }

    state = S_TRANSMITTING;
    call RadioCall.send((call msgsQueue.headptr())->msg);
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    /* check destination address */
    payload += sizeof(nx_struct simpleControlRate_mac_header);

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(BROADCAST, msg), msg))
      return TRUE;

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(NODE, msg), msg))
      return TRUE;

    return sniffing;
   
  }


  /* Helpful functions */
  void send_ack(nx_uint8_t *dest, nx_uint8_t ack_seq) {
    msg_t *msg = signal Module.next_message();
    uint8_t *m = call RadioCall.getPayload(msg);
    nx_struct simpleControlRate_mac_header *header = (nx_struct simpleControlRate_mac_header*)m;
    struct qe_msg q;

    msg->len =  sizeof(nx_struct simpleControlRate_mac_header)
                + 2 * call Addressing.length(msg)
		+ sizeof(nx_struct simpleControlRate_mac_footer);

    header->len = msg->len; 
    header->seq = ack_seq; 
    header->flag = SIMPLECONTROL_ACK_BACK_FLAG;

    m += sizeof(nx_struct simpleControlRate_mac_header);

    /* destination */
    
    call Addressing.move((nx_uint8_t*)&msg->next_hop, dest, msg);
    call Addressing.move((nx_uint8_t*)m, (nx_uint8_t*)&msg->next_hop, msg);

    /* source */
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    q.msg = msg;
    q.seq = header->seq;
    q.resend = SIMPLECONTROL_MAX_RESEND;
    q.flag = header->flag;

    if(state == S_STARTED) {
      if (call RadioCall.load(msg) == SUCCESS) {
        state = S_LOADING;
        return;
      }
    }

    call msgsQueue.enqueue(q);

    if (! call Timer0.isRunning()) {
      call Timer0.startOneShot(1);
    }
  }

  void received_ack(nx_struct simpleControlRate_mac_header *header) {
    uint8_t i = call unACKedQueue.size();
    struct qe_msg q;
    while(i--) {
      q = call unACKedQueue.dequeue();
      if (q.seq == header->seq) {
        signal MacSignal.sendDone(q.msg, SUCCESS);
        return;
      }
      call unACKedQueue.enqueue(q);
    }
  }

  error_t found_duplicate(struct qe_msg *new_msg) {
    uint8_t i;
    struct qe_msg ptr;
    
    dbg("Mac", "Flush: found_duplicate\n");
    for(i = 0; i < call msgsQueue.size(); i++) {
      dbg("Mac", "Flush checking i %d\n", i);
      ptr = call msgsQueue.dequeue();
      if (!memcmp(&new_msg->payload, ptr.payload, new_msg->msg->len))
        return TRUE;
    }
    return FALSE;
  }
}

