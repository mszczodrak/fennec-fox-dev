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
 * Application: implementation of simple MAC protocol, just sends
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 */

#include <Fennec.h>
#include "simpleCCAMac.h"

generic module simpleCCAMacP() {

  provides interface Mgmt;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as Timer0;
  uses interface Random;
}

implementation {

  msg_t *last_message;

  command error_t Mgmt.start() {
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    return (call RadioCall.getPayload(msg) 
                + sizeof(uint8_t)  /* len */
                );
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg)
		- sizeof(uint8_t) /* len */
		);
  }

  task void send_when_clear() {
    if ( call RadioCall.sampleCCA(last_message) ) {
      if ((call RadioCall.send(last_message)) != SUCCESS) {
        signal MacSignal.sendDone(last_message, FAIL);
      }
    } else {
      call Timer0.startOneShot(call Random.rand16() % 5);
    }
  }

  event void Timer0.fired() {
    post send_when_clear();
  }

  command error_t MacCall.send(msg_t *msg) {

    uint8_t *m = call RadioCall.getPayload(msg);

    msg->len += (sizeof(uint8_t)	/* len */
		+ sizeof(nx_struct simpleCCAMac_mac_footer));

    *m = msg->len;

    if((!getFennecStatus( F_SENDING )) && (call RadioCall.load(msg) == SUCCESS)) {
      return SUCCESS;
    }

    signal MacSignal.sendDone(msg, FAIL);
    return FAIL;
  }

  command uint8_t* MacCall.getSource(msg_t *msg) {
    return NULL;  
  }

  command uint8_t* MacCall.getDestination(msg_t *msg) {
    return NULL;  
  }

  command error_t MacCall.ack(msg_t *msg) {
    return SUCCESS;
  }

  command error_t MacCall.sniffing(bool flag, msg_t *msg) {
    return SUCCESS;
  }
  
  event void RadioSignal.receive(msg_t* msg, uint8_t *payload, uint8_t len) {
    payload += sizeof(uint8_t);

    msg->len -= (sizeof(uint8_t) /* len */
		+ sizeof(nx_struct simpleCCAMac_mac_footer));

    signal MacSignal.receive(msg, payload, msg->len);
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error) {
    signal MacSignal.sendDone(msg, error);
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error) {
    if (error == SUCCESS) {
      last_message = msg;
      post send_when_clear();
    } else {
      signal MacSignal.sendDone(msg, FAIL);
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    return TRUE;
  }
}

