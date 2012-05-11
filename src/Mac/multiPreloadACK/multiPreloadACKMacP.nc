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
 * Application: implementation of multi-destination preload MAC protocol
 *              MAC sends, ACKs, and preloads next message to radio buffer
 *              as long as the message is send to destination to which
 *              there is no unACKed message waiting in the buffer
 *
 * Author: Marcin Szczodrak
 * Date: 8/29/2010
 */

#include <Fennec.h>
#include "multiPreloadACKMac.h"

module multiPreloadACKMacP {

  provides interface SplitControl;
  provides interface MacSend;
  provides interface MacReceive;

  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as Timer0;
}

implementation {

  multiPreloadAck_entry_t messages[ MULTIPRELOADACK_MAX_MESSAGES ];
  uint8_t multiPreloadAck_state;
  

  multiPreloadAck_entry_t *find_next( uint8_t m_state);
  multiPreloadAck_entry_t *find_specific( msg_t *msg );
  void cleanEntry( multiPreloadAck_entry_t *entry );
  void check_protocol_status();
  void updateTimer( uint32_t delta_time );

  command error_t SplitControl.start() {
    uint8_t i;

    for(i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
      cleanEntry( &messages[i] );
    }

    multiPreloadAck_state = S_STARTED;

    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    uint8_t i;
    call Timer0.stop();
    multiPreloadAck_state = S_STOPPED;

    for(i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
      drop_message( messages[i].msg );
      cleanEntry( &messages[i] );
    }

    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  command void* MacSend.getPayload(msg_t *message) {
    uint8_t *data = (uint8_t*) message;
    return data + MULTIPRELOADACK_MAC_HEADER_SIZE;
  }

  command uint8_t MacSend.getMaxSize() {
    return MAX_MESSAGE_SIZE - 
      MULTIPRELOADACK_MAC_HEADER_SIZE - MULTIPRELOADACK_MAC_FOOTER_SIZE;
  }

  event void Timer0.fired() {
    uint8_t delta_time;
    uint8_t i;

    dbg("Mac", "Mac Timer fired\n");

    delta_time = call Timer0.getdt();

    updateTimer( delta_time );

      for( i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
        if ( (messages[i].msg != NULL) && (messages[i].state == S_ACK_WAIT) && (messages[i].ack_timer == 0) ) {
          if ( messages[i].retries < MULTIPRELOADACK_RESEND_TRIES ) {
            messages[i].retries++;
            messages[i].state = S_NOT_ACKED;
          } else {
            /* Keep failing to receive ACK, just give up */
            signal MacSend.sendDone(messages[i].msg, FAIL);
            dbg("Mac", "send   ");
            cleanEntry( &messages[i] );
            dbg("Mac", "    done\n");
          }
        }
    }

    check_protocol_status();
  }
  
  command error_t MacSend.send(msg_t *msg) {

    uint8_t *m;
    multiPreloadAck_mac_header_t *header = (multiPreloadAck_mac_header_t*) msg->data;
    multiPreloadAck_mac_footer_t *footer;

    dbg("Mac", "multiPreloadAck: is in send\n");

    if (msg->next_hop != BROADCAST) {
      multiPreloadAck_entry_t *entry = find_next(S_STOPPED);

      if ( entry == NULL ) {
        return FAIL;
      }

      atomic {
        /* save pointer to message in the queue */
        entry->state = S_STARTED;
        entry->msg = msg;
      }
    }

    /* process headers */
    header->length = MULTIPRELOADACK_MAC_HEADER_SIZE + MULTIPRELOADACK_MAC_FOOTER_SIZE + msg->len;
    header->conf = msg->conf_id;
    header->src = TOS_NODE_ID;
    header->dest = msg->next_hop;

    m = (uint8_t*) msg->data;
    footer = (multiPreloadAck_mac_footer_t*)m + MULTIPRELOADACK_MAC_HEADER_SIZE + msg->len;
    footer->footer = 0;

    msg->len = header->length;

    if (!getFennecStatus( F_SENDING ) && (msg->next_hop == BROADCAST)) {
      if ((call RadioCall.load(msg)) == SUCCESS) {
        setFennecStatus( F_SENDING, ON );
        return SUCCESS;
      }
    }
        
    check_protocol_status();
    return SUCCESS;
  }

  command error_t MacSend.ack() {

    msg_t *msg = nextMessage();
    multiPreloadAck_mac_header_t *header = (multiPreloadAck_mac_header_t*) msg;

    dbg("Mac", "multiPreloadAck: is in ack\n");


    if (msg == NULL) {
      return FAIL;
    }

    atomic {
      if ( multiPreloadAck_state != S_STARTED ) {
        drop_message(msg);
        return FAIL;
      }

      multiPreloadAck_state = S_SENDING_ACK;

      header->length = MULTIPRELOADACK_MAC_HEADER_SIZE + MULTIPRELOADACK_MAC_FOOTER_SIZE;
      header->conf = msg->conf_id;
      header->src = TOS_NODE_ID;
      header->dest = BROADCAST;

      msg->len = header->length;
      msg->next_hop = BROADCAST;
    }

    dbg("Mac", "multiPreloadAck: is sending ACK\n");
  
    if (!getFennecStatus( F_SENDING )) {
      if ((call RadioCall.load(msg)) == SUCCESS) {
        setFennecStatus( F_SENDING, ON);
        return SUCCESS;
      }
    }

    drop_message(msg);
    return FAIL;
  }

  event void RadioSignal.receive(msg_t* msg) {
    uint8_t *data = ((uint8_t*) msg) + MULTIPRELOADACK_MAC_HEADER_SIZE;
    multiPreloadAck_mac_header_t *header = (multiPreloadAck_mac_header_t*) msg;
    uint8_t i;

//    dbg("Mac", "multiPreloadAck: is in receive\n");

    if (msg->len < MIN_MESSAGE_SIZE) {
      drop_message(msg);
      return;
    }

    msg->len -= (MULTIPRELOADACK_MAC_HEADER_SIZE + MULTIPRELOADACK_MAC_FOOTER_SIZE);

    if (( msg->len > 0 ) && ((header->dest == TOS_NODE_ID) || (header->dest == BROADCAST))) {
        /* Received a real message */
	dbg("Mac", "multiPreloadAck: drop_message real msg\n");
        signal MacReceive.receive(msg, data, msg->len);
    } else {
      /* Received an ack, see what can we do with that */
      /* an ACK can be an exlplicit ACK message, or implicit
  	 message send from a node from which ACK is waiting */

      for ( i = 0 ; i < MULTIPRELOADACK_MAX_MESSAGES; i++) { 
        if ((messages[i].msg != NULL) && (header->src == messages[i].msg->next_hop) &&
           ( messages[i].state == S_ACK_WAIT )) {

	   dbg("Mac", "multiPreloadAck: drop_message ACK\n");
           drop_message(msg);

           signal MacSend.sendDone(messages[i].msg, SUCCESS);
	  
           cleanEntry( &messages[i] );
        }
      }
      dbg("Mac", "multiPreloadAck: Received what?\n");
      drop_message(msg);
    }
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error){
    multiPreloadAck_entry_t *entry = NULL;

    setFennecStatus( F_SENDING, OFF);

    dbg("Mac", "multiPreloadAck: is in sendDone\n");

    if ( error == SUCCESS ) {

      if ( multiPreloadAck_state == S_TRANSMITTING ) {
        /* update status */
        entry = find_specific( msg );

        if (entry != NULL) {
          entry->state = S_ACK_WAIT;
          if ( call Timer0.isRunning() ) {
            updateTimer( call Timer0.getNow() - call Timer0.gett0() );
            entry->ack_timer = MULTIPRELOADACK_ACK_TIME;
          } else {
            entry->ack_timer = MULTIPRELOADACK_ACK_TIME;
            call Timer0.startOneShot( MULTIPRELOADACK_ACK_TIME );
          }
        }
      }

      if ( msg->next_hop == BROADCAST ) {
	if (multiPreloadAck_state == S_SENDING_ACK ) {
          drop_message(msg);
        } else {
  	  signal MacSend.sendDone(msg, SUCCESS);
        }
      }

      multiPreloadAck_state = S_STARTED;
      check_protocol_status();
    } else {
      dbg("Mac", "multiPreloadAck: sendDona FAILed\n");
      entry = find_specific( msg );
      if (entry != NULL) {
        entry->state = S_STARTED;
      } else {
        drop_message(msg);
      }
    }
    multiPreloadAck_state = S_STARTED;
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error){
    multiPreloadAck_entry_t *entry = NULL;

  //  dbg("Mac", "is in loadDone\n");


    if (error == SUCCESS) {
      
//      if( multiPreloadAck_state == S_SENDING_ACK ) {
      if( msg->next_hop == BROADCAST ) {
          call RadioCall.send(msg);
      } else {
        entry = find_specific( msg );
        entry->state = S_LOADED;

        multiPreloadAck_state = S_TRANSMITTING;
        call RadioCall.send(msg);
      }
    } else {
      entry = find_specific( msg );
      if ( entry == NULL ) {
        dbg("Mac", "load done failed? ...\n");
        drop_message(msg);
        dbg("Mac", "yes ;(\n");
      }
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg) {
    multiPreloadAck_mac_header_t *header = (multiPreloadAck_mac_header_t*) msg;

    if ( ((header->conf < getNumberOfConfigurations()) || (header->conf == POLICY_CONFIGURATION)) &&
         ((header->dest == BROADCAST) || (header->dest == TOS_NODE_ID))  ) {
      return TRUE;
    } else {
      return FALSE;
    }
  }


  multiPreloadAck_entry_t *find_next( uint8_t m_state ) {
    uint8_t i;
    multiPreloadAck_entry_t *unsafe = NULL;


  //  dbg("Mac", "is in find_next\n");


    for( i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
    }

    for( i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
      if ( (messages[i].state == m_state) ) {
 
        /* if possible, pick a message which goes to next hop to which there
 	 * are no outstanding ACKs */
        if ( (m_state == S_STARTED) || (m_state == S_NOT_ACKED) ) {
          uint8_t j;
          bool safe = TRUE;

          for ( j = 0; j < MULTIPRELOADACK_MAX_MESSAGES; j++) {
            if ( ( i != j ) && ( messages[j].msg != NULL ) &&
              ( messages[i].msg->next_hop == messages[j].msg->next_hop) &&
              ( messages[j].state == S_ACK_WAIT) ) {
                safe = FALSE;
            }
          }

          if ( safe ) {
            return &messages[i];
          } else {
            if (unsafe == NULL) {
              unsafe = &messages[i];
            }
          }

        } else {
          return &messages[i];
        }
      }
    }

    return unsafe;
  }


  multiPreloadAck_entry_t *find_specific( msg_t *msg ) {
    uint8_t i;

  //  dbg("Mac", "is in find_specific\n");


    for( i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
      if ( messages[i].msg == msg ) {
        return &messages[i];
      }
    }

    return NULL;
  }


  void check_protocol_status() {
    multiPreloadAck_entry_t *entry;

  //  dbg("Mac", "is in check_protocol_status\n");


    if (( multiPreloadAck_state == S_STARTED ) && (!getFennecStatus( F_SENDING ))) {
      entry = find_next( S_STARTED );

      if (entry == NULL) {
        entry = find_next( S_NOT_ACKED );
      }

      if ( entry != NULL ) {
        entry->state = S_LOADING;    
        multiPreloadAck_state = S_LOADING;
        setFennecStatus( F_SENDING, ON);
        call RadioCall.load( entry->msg );
      }
    } else {

    }
  }


  void updateTimer( uint32_t delta_time ) {
    uint8_t min_time = MULTIPRELOADACK_ACK_TIME + 1;
    uint8_t i;

 //   dbg("Mac", "is in updateTimer\n");


    for( i = 0; i < MULTIPRELOADACK_MAX_MESSAGES; i++) {
      if ((messages[i].msg != NULL) && (messages[i].state == S_ACK_WAIT)) {
        if (messages[i].ack_timer > delta_time) {
          messages[i].ack_timer -= delta_time;
          if (min_time > messages[i].ack_timer) {
            min_time = messages[i].ack_timer;
          }
        } else {
          messages[i].ack_timer = 0;
        }
      }
    }

    if ( min_time <= MULTIPRELOADACK_ACK_TIME ) {
      call Timer0.startOneShot( min_time );
    } else {
    }

  }

  void cleanEntry( multiPreloadAck_entry_t *entry ) {

//    dbg("Mac", "is in cleanEntry\n");
    if (entry != NULL) {
      entry->msg = NULL;
      entry->state = S_STOPPED;
      entry->retries = 0;
      entry->ack_timer = 0;
    }
  }

}
