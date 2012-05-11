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
 * Application: implementation of p-persistant CSMA with hashing
 * Author: Marcin Szczodrak
 * Date: 3/3/2011
 */

#include <Fennec.h>
#include "hashing.h"
#include "p_persistentCSMAHashingMac.h"

generic module p_persistentCSMAHashingMacP() {

  provides interface Mgmt;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as BackoffTimer;
  uses interface Random;
}

implementation {

  uint8_t send_attempts;
  msg_t *last_message;

  task void send_when_clear();

  command error_t Mgmt.start() {
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
                + sizeof(nx_struct p_persistentCSMAHashing_mac_header)
                );
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg)
		- sizeof(nx_struct p_persistentCSMAHashing_mac_footer)
                - sizeof(nx_struct p_persistentCSMAHashing_mac_header)
                );
  }

  event void BackoffTimer.fired() {
    post send_when_clear();
  }

  command error_t MacCall.send(msg_t *msg) {
    uint8_t *m = call RadioCall.getPayload(msg);

    nx_struct p_persistentCSMAHashing_mac_header *header = 
	(nx_struct p_persistentCSMAHashing_mac_header*) m;

    header->hash = pearson_hashing((nx_uint8_t*)m
			+ sizeof(nx_struct p_persistentCSMAHashing_mac_header),
			msg->len);

    msg->len += (sizeof(nx_struct p_persistentCSMAHashing_mac_header)
			+ sizeof(nx_struct p_persistentCSMAHashing_mac_footer));

    header->len = msg->len;

    if(! getFennecStatus( F_SENDING ) ) {
      if ((call RadioCall.load(msg)) == SUCCESS)
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
    nx_struct p_persistentCSMAHashing_mac_header *header =
        (nx_struct p_persistentCSMAHashing_mac_header*) payload;

    payload += sizeof(nx_struct p_persistentCSMAHashing_mac_header);
    msg->len -= (sizeof(nx_struct p_persistentCSMAHashing_mac_header)
		+ sizeof(nx_struct p_persistentCSMAHashing_mac_footer));

    if (header->hash == pearson_hashing((nx_uint8_t*)payload, msg->len)) {
      signal MacSignal.receive(msg, payload, msg->len);
    } else {
      drop_message(msg);
    }

  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error){
    call BackoffTimer.stop();
    signal MacSignal.sendDone(msg, error);
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error){
    if (error != SUCCESS) {
      signal MacSignal.sendDone(msg, FAIL);
    } else {
      last_message = msg;
      post send_when_clear();
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    return TRUE;
  }

  task void send_when_clear() {
    if ( ( call RadioCall.sampleCCA(last_message) ) &&  
      ( (call Random.rand16() % 100 ) + 1 <= PPERSISTENTCSMAHASHING_P_VALUE ) ) {
      if ((call RadioCall.send(last_message)) != SUCCESS) {
        signal MacSignal.sendDone(last_message, FAIL);
      }
    } else {
      call BackoffTimer.startOneShot( PPERSISTENTCSMAHASHING_SAMPLE_DELAY );
    }
  }

}

