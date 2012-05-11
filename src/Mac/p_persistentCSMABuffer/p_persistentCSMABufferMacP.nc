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
 * Application: implementation of p-persistant CSMA with addressing and buffer
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#include <Fennec.h>
#include "p_persistentCSMABufferMac.h"

module p_persistentCSMABufferMacP {

  provides interface Mgmt;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as BackoffTimer;
  uses interface Random;
  uses interface Queue<msg_t*>;
}

implementation {

  bool sniffing;
  uint8_t send_attempts;

  task void send_when_clear();

  command error_t Mgmt.start() {
    atomic sniffing = FALSE;
    send_attempts = 0;

    

    signal Mgmt.startDone( SUCCESS );
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    call BackoffTimer.stop();
    signal Mgmt.stopDone( SUCCESS );
    return SUCCESS;
  }

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    return (call RadioCall.getPayload(msg)
                + 2 * call Addressing.length(msg)
                + sizeof(uint8_t)  /* len */
                );
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg)
                - 2 * call Addressing.length(msg)
                - sizeof(nx_struct p_persistentCSMABuffer_mac_footer)
                - sizeof(uint8_t) /* len */
                );
  }

  event void BackoffTimer.fired() {
    post send_when_clear();
  }

  command error_t MacCall.send(msg_t *msg) {
    uint8_t *m;

    if (call Queue.full()) {
      signal MacSignal.sendDone(msg, FAIL);
      return FAIL;
    }

    call Queue.enqueue(msg);

    m = call RadioCall.getPayload(msg);

    msg->len += (2 * call Addressing.length(msg)
		+ sizeof(nx_struct p_persistentCSMABuffer_mac_footer)
                + sizeof(uint8_t));     /* len */
    *m = msg->len;
    m++;

    /* destination */
    call Addressing.copy(m, msg->next_hop, msg);

    /* source */
    m += call Addressing.length(msg);
    call Addressing.copy(m, NODE, msg);

    if(! getFennecStatus( F_SENDING ) ) {
      if ((call RadioCall.load(msg)) == SUCCESS)
        return SUCCESS;
    }

    signal MacSignal.sendDone(msg, FAIL);
    return FAIL;
  }

  command uint8_t* MacCall.getSource(msg_t *msg) {
    return (call RadioCall.getPayload(msg)
                + call Addressing.length(msg)
                + sizeof(uint8_t)
                );
  }

  command uint8_t* MacCall.getDestination(msg_t *msg) {
    return (call RadioCall.getPayload(msg)
                + sizeof(uint8_t)
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
    payload += 2 * call Addressing.length(msg) + sizeof(uint8_t);

    msg->len -= (2 * call Addressing.length(msg)
                        + sizeof(nx_struct p_persistentCSMABuffer_mac_footer)
                        + sizeof(uint8_t) /* len */
                );
    signal MacSignal.receive(msg, payload, msg->len);
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error){
    call BackoffTimer.stop();
    signal MacSignal.sendDone(call Queue.dequeue(), error);
    post send_when_clear();
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error){
    if (error != SUCCESS) {
      signal MacSignal.sendDone(msg, FAIL);
    } else {
      post send_when_clear();
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    /* check destination address */
    payload += sizeof(uint8_t); /* len */;

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(BROADCAST, msg), msg))
      return TRUE;

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(NODE, msg), msg))
      return TRUE;

    return sniffing;
  }

  task void send_when_clear() {
    if ( (!call Queue.empty()) && 
      ( call RadioCall.sampleCCA(*call Queue.headptr()) ) &&  
      ( (call Random.rand16() % 100 ) + 1 <= PPERSISTENTCSMABUFFER_P_VALUE ) ) {
      if ((call RadioCall.send(*call Queue.headptr())) != SUCCESS) {
        signal MacSignal.sendDone(call Queue.dequeue(), FAIL);
      }
    } else {
      call BackoffTimer.startOneShot( PPERSISTENTCSMABUFFER_SAMPLE_DELAY );
    }
  }

}

