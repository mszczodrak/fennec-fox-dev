/*
 * Copyright (c) 2010 Columbia University.
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
 * Application: implementation of simple MAC protocol
 *              MAC sends, ACKs, and preloads next message to radio buffer
 * Author: Marcin Szczodrak
 * Date: 8/23/2010
 */

#include <Fennec.h>
#include "simplePreloadACKMac.h"

module simplePreloadACKMacP {

  provides interface SplitControl;
  provides interface MacSend;
  provides interface MacReceive;

  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as Timer0;
}

implementation {

  uint8_t spam_state;
  uint8_t resend_tries;
  msg_t *last_message;
  msg_t *next_message;

  command error_t SplitControl.start() {
    next_message = NULL;
    last_message = NULL;
    spam_state = READY;
    resend_tries = 0;
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    spam_state = STOPPED,
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  command void* MacSend.getPayload(msg_t *message) {
    uint8_t *data = (uint8_t*) message;
    return data + SIMPLEPRELOADACK_MAC_HEADER_SIZE;
  }

  command uint8_t MacSend.getMaxSize() {
    return MAX_MESSAGE_SIZE - 
      SIMPLEPRELOADACK_MAC_HEADER_SIZE - SIMPLEPRELOADACK_MAC_FOOTER_SIZE;
  }

  event void Timer0.fired() {

    if ( ++resend_tries > SIMPLEPRELOADACK_RESEND_TRIES ) {
      drop_message(last_message);
      last_message = NULL;
      resend_tries = 0;

      switch(spam_state) {

        case SECOND_LOADING:
          spam_state = FIRST_LOADING;
          break;

        case SECOND_LOADED:
          spam_state = FIRST_SENDING;
          call RadioCall.send(last_message);
          break;

        default:
          spam_state = READY;
      }
    } else {
      switch(spam_state) {

        case WAITING_ACK:
        case ACK_LOADED:
          spam_state = FIRST_RESENDING;
          call RadioCall.resend(last_message);
          break;

        case SECOND_LOADING:
        case SECOND_LOADED:
          call RadioCall.load(last_message);
          spam_state = RESENDING_LAST;
          break;

        default:

      }
    }
  }

  command error_t MacSend.send(msg_t *msg) {

    simplePreloadAck_mac_header_t *header = (simplePreloadAck_mac_header_t*) msg->data;
    simplePreloadAck_mac_footer_t *footer;

    switch(spam_state) {
      case ACK_LOADED:
        drop_message(last_message);

      case READY:
        spam_state = FIRST_LOADING;
        break;

      case WAITING_ACK:
        spam_state = SECOND_LOADING;
        break;

      default:
        return FAIL;
    }

    next_message = msg;

    header->length = SIMPLEPRELOADACK_MAC_HEADER_SIZE + SIMPLEPRELOADACK_MAC_FOOTER_SIZE + msg->len;
    header->conf = msg->conf_id;
    header->src = TOS_NODE_ID;
    header->dest = msg->next_hop;

    msg->len = header->length;

    call RadioCall.load(msg);
    return SUCCESS;
  }

  command error_t MacSend.ack() {

    msg_t *msg;
    simplePreloadAck_mac_header_t *header;

    switch(spam_state) {
      case READY:
        spam_state = ACK_LOADING;
        break;

      case ACK_LOADED:
        call RadioCall.send(last_message);
        return SUCCESS;

      default:
        return FAIL;
    }

    msg = nextMessage();
    last_message = msg;
    header = (simplePreloadAck_mac_header_t*) msg;

    header->length = SIMPLEPRELOADACK_MAC_HEADER_SIZE + SIMPLEPRELOADACK_MAC_FOOTER_SIZE;
    header->conf = msg->conf_id;
    header->src = TOS_NODE_ID;
    header->dest = BROADCAST;

    msg->len = header->length;
    msg->next_hop = BROADCAST;

    call RadioCall.load(msg);
    return SUCCESS;
  }

  event void RadioSignal.receive(msg_t* msg) {
    uint8_t *data = ((uint8_t*) msg) + SIMPLEPRELOADACK_MAC_HEADER_SIZE;
    simplePreloadAck_mac_header_t *header = (simplePreloadAck_mac_header_t*) msg;
    simplePreloadAck_mac_header_t *last_header = (simplePreloadAck_mac_header_t*) last_message;
    msg->len -= (SIMPLEPRELOADACK_MAC_HEADER_SIZE + SIMPLEPRELOADACK_MAC_FOOTER_SIZE);

    if (( msg->len > 0 ) && 
      (header->dest == TOS_NODE_ID || header->dest == BROADCAST )) {
      signal MacReceive.receive(msg, data, msg->len);
    } else {
      if ((last_message != NULL) && (header->src == last_header->dest)) {
        drop_message(last_message);
        last_message = NULL;
        resend_tries = 0;
        call Timer0.stop();

        switch(spam_state) {
          case WAITING_ACK:
          case FIRST_SENDING:
            spam_state = READY;
            break;
 
          case RESENDING_LAST:
            call RadioCall.load(next_message);
            spam_state = FIRST_LOADING;
            break;

          case SECOND_LOADED:
            spam_state = FIRST_SENDING;
            call RadioCall.send(msg);
            break;

          case SECOND_LOADING:
            spam_state = FIRST_LOADING;
            break;

          default: 

        }
      } 
      drop_message(msg);
    }
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error){

    switch(spam_state) {
      case ACK_LOADED:
        call RadioCall.load(msg);
        break;

      case FIRST_SENDING:
        last_message = nextMessage();
        memcpy(last_message, next_message, sizeof(msg_t));
        next_message = NULL;
        signal MacSend.sendDone(msg, error);
        call Timer0.startOneShot( SIMPLEPRELOADACK_ACK_TIME );
        spam_state = WAITING_ACK;
        break;

      case FIRST_RESENDING:
        call Timer0.startOneShot( SIMPLEPRELOADACK_ACK_TIME );
        spam_state = WAITING_ACK;
        break;

      case RESENDING_LAST:
        call RadioCall.load(next_message);
        call Timer0.startOneShot( SIMPLEPRELOADACK_ACK_TIME );
        spam_state = SECOND_LOADING;
        break;

      default:

    }
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error){

    if (error == SUCCESS) {

      switch(spam_state) {
        case FIRST_LOADING:
          spam_state = FIRST_SENDING;
          call RadioCall.send(msg);
          break;

        case SECOND_LOADING:
          spam_state = SECOND_LOADED;
          break;

        case ACK_LOADING:
          spam_state = ACK_LOADED;
          call RadioCall.send(msg);
          break;
          
        case RESENDING_LAST:
          call RadioCall.send(msg);
          break;


        case ACK_LOADED:
          break;

        default:

      }
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg) {
    simplePreloadAck_mac_header_t *header = (simplePreloadAck_mac_header_t*) msg;
    if ( ((header->conf < getNumberOfConfigurations()) || (header->conf == POLICY_CONFIGURATION)) &&
         ((header->dest == BROADCAST) || (header->dest == TOS_NODE_ID))  ) {
      return TRUE;
    } else {
      return FALSE;
    }
  }

}

