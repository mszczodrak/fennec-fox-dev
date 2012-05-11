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
 * Date: 8/24/2010
 */

#include <Fennec.h>
#include "simplePreloadACKOKMac.h"

module simplePreloadACKOKMacP {

  provides interface SplitControl;
  provides interface MacSend;
  provides interface MacReceive;

  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as Timer0;
}

implementation {

  uint8_t spam_state;

  msg_t *last_message;
  msg_t *next_message;
  uint16_t last_src;

  command error_t SplitControl.start() {
    setFennecStatus( F_PRINTING, ON );
    last_message = NULL;
    next_message = NULL;
    spam_state = READY;
    last_src = TOS_NODE_ID;
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
    return data + SIMPLEPRELOADACKOK_MAC_HEADER_SIZE;
  }

  command uint8_t MacSend.getMaxSize() {
    return MAX_MESSAGE_SIZE - 
      SIMPLEPRELOADACKOK_MAC_HEADER_SIZE - SIMPLEPRELOADACKOK_MAC_FOOTER_SIZE;
  }

  event void Timer0.fired() {

    printf("timer fired at state %d\n", spam_state);

    switch(spam_state) {

      case OK_LOADING:
      case OK_LOADED:
        printf("OK_LOAD... -> FIRST_RESENDING\n");
        spam_state = FIRST_RESENDING;
        call RadioCall.load(last_message);
        break;

      default:
        printf("failed in state %d\n", spam_state);

    }

    printfflush();
  }

  command error_t MacSend.send(msg_t *msg) {

    uint8_t *m;
    simplePreloadAckOk_mac_header_t *header = (simplePreloadAckOk_mac_header_t*) msg->data;
    simplePreloadAckOk_mac_footer_t *footer;

    printf("got send at state %d ", spam_state);

    switch(spam_state) {
      case READY:
        printf("READY -> FIRST_LOADING\n");
        spam_state = FIRST_LOADING;
        break;

      default:
        printf("FAILED\n");
        return FAIL;
    }

    printfflush();

    next_message = msg;

    header->length = SIMPLEPRELOADACKOK_MAC_HEADER_SIZE + SIMPLEPRELOADACKOK_MAC_FOOTER_SIZE + msg->len;
    header->conf = msg->conf_id;
    header->src = TOS_NODE_ID;
    header->dest = msg->next_hop;
      
    m = (uint8_t*) msg->data;
    footer = (simplePreloadAckOk_mac_footer_t*)m + SIMPLEPRELOADACKOK_MAC_HEADER_SIZE + msg->len;
    footer->footer = 0;

    msg->len = header->length; 

    call RadioCall.load(msg);
    return SUCCESS;
  }

  error_t ok_load() {
    msg_t *msg;
    simplePreloadAckOk_mac_header_t *header;

    printf("call ok_load() in state %d ", spam_state);

    if ((last_src == TOS_NODE_ID) && (spam_state != ACK_LOADING)) {

     printf(" moved to OK_LOADED, the last_src %d is the TOS_NODE_ID %d\n", last_src, TOS_NODE_ID);
     spam_state = OK_LOADED;
     return SUCCESS;

    }

    printf("load()\n");
    printfflush();

    msg = nextMessage();
    header = (simplePreloadAckOk_mac_header_t*) msg;

    header->length = SIMPLEPRELOADACKOK_MAC_HEADER_SIZE + SIMPLEPRELOADACKOK_MAC_FOOTER_SIZE;
    header->conf = msg->conf_id;
    header->src = TOS_NODE_ID;
    header->dest = last_src;

    msg->len = header->length;
    msg->next_hop = last_src;

    call RadioCall.load(msg);
    return SUCCESS;
  }

  error_t ok_send() {

    printf("call ok_send() in state %d", spam_state);

    if ((last_src == TOS_NODE_ID) && (spam_state != ACK_LOADED)) {
      printf(" moved to READY, the last_src %d is the TOS_NODE_ID %d\n", last_src, TOS_NODE_ID);
      spam_state = READY;
    } else {
      printf(" --> OK_SENDING\n");
      spam_state = OK_SENDING;
      call RadioCall.send(last_message);
    }

    printfflush();
    return SUCCESS;
  }

  command error_t MacSend.ack() {
    printf("request ack\n");
    printfflush();
    spam_state = ACK_LOADING;
    ok_load();
    return SUCCESS;
  }

  event void RadioSignal.receive(msg_t* msg) {
    uint8_t *data = ((uint8_t*) msg) + SIMPLEPRELOADACKOK_MAC_HEADER_SIZE;
    simplePreloadAckOk_mac_header_t *header = (simplePreloadAckOk_mac_header_t*) msg;
    simplePreloadAckOk_mac_header_t *last_header = (simplePreloadAckOk_mac_header_t*) last_message;
    msg->len -= (SIMPLEPRELOADACKOK_MAC_HEADER_SIZE + SIMPLEPRELOADACKOK_MAC_FOOTER_SIZE);

    printf("receive() ");

    if (( msg->len > 0 ) 
      (header->dest == TOS_NODE_ID || header->dest == BROADCAST )) {
      signal MacReceive.receive(msg, data, msg->len);
      last_src = header->src;
      printf("a real message, last src %d\n", last_src);
    } else {
      if ((last_message != NULL) && (header->src == last_header->dest)) {
        drop_message(last_message);
        last_message = NULL;
        call Timer0.stop();

        if (header->dest == TOS_NODE_ID) {
          /* OK */
          printf("header is TOS so its OK message ");
          switch(spam_state) {
              case OK_LOADING:
                spam_state = READY;
                printf("OK_LOADING -> REDY\n");
                break;

              case OK_LOADED:
                spam_state = READY;
                printf("OK_LOADED -> READY\n");
                break;

              case FIRST_RESENDING:
                printf("FIRST_RESENDING -> RECEIVED_ACK calls ok_load()\n");
                spam_state = RECEIVED_ACK;
                ok_load();
                break;

//            case RESENDING_LAST:
//              call RadioCall.load(next_message);
//              spam_state = FIRST_LOADING;
//              break;

            default: 
              printf("default what to do with state %d\n", spam_state);
          }
        } else {
          /* ACK */
          printf(" ACK message ");
          switch(spam_state) {
            case OK_LOADING:
              printf("OK_LOADING -> RECEIVED_ACK\n");
              spam_state = RECEIVED_ACK;
              break;

            case OK_LOADED:
              printf("OK_LOADED -> RECEIVED_ACK\n");
              spam_state = RECEIVED_ACK;
              ok_send();
              break;

            case FIRST_RESENDING:
              printf("FIRST_RESENDING -> RECEIVED_ACK calls ok_load()\n");
              spam_state = RECEIVED_ACK;
              ok_load();
              break;


//            case RESENDING_LAST:
//              call RadioCall.load(next_message);
//              spam_state = FIRST_LOADING;
//              break;

            default:
            printf("default with state %d\n", spam_state);
          }
        }
      }
      drop_message(msg);
    }
    printfflush();
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error){

    printf("sendDone() ");

    switch(spam_state) {
      case OK_SENDING:
        printf("OK_SENDING -> READY\n");
        drop_message(msg);
        spam_state = READY;
        break;

      case ACK_LOADED:
        printf("ACK_LOADED -> READY\n");
        drop_message(msg);
        spam_state = READY;
        break;

      case FIRST_SENDING:
        printf("FIRST_SENDIND -> OK_LOADING call ok_load()\n");
        last_message = nextMessage();
        memcpy(last_message, next_message, sizeof(msg_t));
        next_message = NULL;
        signal MacSend.sendDone(msg, error);
        call Timer0.startOneShot( SIMPLEPRELOADACKOK_ACK_TIME );
        spam_state = OK_LOADING;
        ok_load();
        break;

      case FIRST_RESENDING:
        call Timer0.startOneShot( SIMPLEPRELOADACKOK_ACK_TIME );
        spam_state = OK_LOADING;
        ok_load();
        break;

      case RECEIVED_ACK:
        spam_state = READY;
        break;
 

//      case RESENDING_LAST:
//        call RadioCall.load(next_message);
//        spam_state = SECOND_LOADING;
//        break;

      default:
        printf(" default with in state %d\n", spam_state);
    }
    printfflush();
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error){

    printf("loadDone() ");

    if (error == SUCCESS) {

      switch(spam_state) {
        case FIRST_LOADING:
          printf("FIRST_LOADING -> FIRST_SENDING\n");
          spam_state = FIRST_SENDING;
          call RadioCall.send(msg);
          break;

        case ACK_LOADING:
          spam_state = ACK_LOADED;
          printf("ACK_LOADING -> ACK_LOADED ,call Radio send()\n");
          call RadioCall.send(msg);
          break;
          
        case OK_LOADING:
          printf("OK_LOADING -> OK_LOADED\n");
          spam_state = OK_LOADED;
          break;

        case RECEIVED_ACK:
        case OK_SENDING:
          printf("RECEIVED_ACK / OK_SENDING -> calls ok_send()\n");
          ok_send();
          break;

        case FIRST_RESENDING:
          printf("FIRST_RESENDING calls send()\n");
          call RadioCall.send(msg);
          break;


        default:
          printf("default in state %d\n", spam_state);

      }
    }
    printfflush();
  }

}

