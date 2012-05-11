/*
 *  IEEE 802.15.4 MAC protocol for Fennec Fox platform.
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
 * MAC: implementation of IEEE 802.15.4 -2006 MAC protocol
 * Author: Marcin Szczodrak
 * Date: 8/10/2011
 * Last Modified: 2/02/2012
 */


#include <Fennec.h>
#include "ieee802154Mac.h"

generic module ieee802154MacP(bool use_cca, bool use_ack, bool use_dest_check,
				uint8_t max_cca_retries, 
				uint8_t max_send_retries, 
				uint16_t ack_wait_time,
				uint16_t initial_backoff,
				uint16_t congestion_backoff,
				uint16_t minimum_backoff) {

  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;

  uses interface Timer<TMilli> as BackoffTimer;
  uses interface Random;
}

implementation {

  bool sniffing;
  uint8_t state = S_STOPPED;
  msg_t *loaded_message;
  nxle_uint8_t dsn;
  nxle_uint8_t last_seen_dsn;
  uint8_t nb; 			/* backoff attemps */
  uint8_t ns;			/* send attempts */
  msg_t *ack_message;

  void getBackoff(uint16_t d) {
    if (d) {
      call BackoffTimer.startOneShot(call Random.rand16() % d + minimum_backoff);
    } else {
      call BackoffTimer.startOneShot(minimum_backoff);
    }
  }

  void send_ack() {
    //dbg("Mac", "Mac IEEE802.15.4 send_ack\n");
    state = S_LOADING;
    ack_message->asap = ON;

    if ((call RadioCall.load(ack_message)) != SUCCESS) {
      signal Module.drop_message(ack_message);
      ack_message = NULL;
      state = S_STARTED;
      dbg("Mac", "Mac IEEE802.15.4 send_ack failed to load\n");
    }
  }

  task void signal_send_done_fail() {
    //dbg("Mac", "Mac IEEE802.15.4 signal_send_done_fail()\n");
    if (loaded_message != NULL) {
      dbg("Mac", "Mac IEEE802.15.4 signal_send_done_fail\n");
      signal MacSignal.sendDone(loaded_message, FAIL);
    }
    loaded_message = NULL;
    state = S_STARTED;
  }

  task void start_loading_data_message() {
    //dbg("Mac", "Mac IEEE802.15.4 start_loading_data_message()\n");
    if (loaded_message == NULL) return;

    state = S_LOADING;

    if ((call RadioCall.load(loaded_message)) != SUCCESS) {
      if (++ns >= max_send_retries) {
        dbg("Mac", "Mac send done fail too many retries\n");
        call RadioCall.cancel(loaded_message);
        post signal_send_done_fail();
      } else {
        getBackoff(initial_backoff);
      }
    } else {
      //dbg("Mac", "Mac IEEE802.15.4 loading message to %d\n", loaded_message->next_hop);
    }
  }

  task void send_data_message() {
    //dbg("Mac", "Mac IEEE802.15.4 send_data_message()\n");
    
    if (call RadioCall.send(loaded_message) != SUCCESS) {
      dbg("Mac", "Mac IEEE802.15.4 seding message failed\n");
      state = S_SAMPLE_CCA;
      if (++ns >= max_send_retries) {
        dbg("Mac", "Mac send done fail too many retries\n");
        call RadioCall.cancel(loaded_message);
        post signal_send_done_fail();
      } else {
        getBackoff(congestion_backoff);
      }
    }
  }

  command error_t Mgmt.start() {
    //dbg("Mac", "Mac IEEE802.15.4 Mgmt.start\n");
    dbgs(F_MAC, S_NONE, DBGS_MGMT_START, 0, 0);
    if (state == S_STOPPED) {
      state = S_STARTED;
      dsn = call Random.rand16() % 255;
      last_seen_dsn = dsn;
      loaded_message = NULL;
      atomic sniffing = FALSE;
      ack_message = NULL;
      //dbg("Mac", "Mac IEEE802.15.4 signal startDone SUCCESS\n");
      signal Mgmt.startDone(SUCCESS);
      return SUCCESS;
    } else {
      //dbg("Mac", "Mac IEEE802.15.4 already started\n");
      signal Mgmt.startDone(SUCCESS);
      //dbg("Mac", "Mac IEEE802.15.4 Mgmt.start\n");
      return SUCCESS;
    }
  }

  command error_t Mgmt.stop() {
    //dbg("Mac", "Mac IEEE802.15.4 Mgmt.stop\n");
    dbgs(F_MAC, S_NONE, DBGS_MGMT_STOP, 0, 0);
    if (state != S_STOPPED) {
      state = S_STOPPED;
      call BackoffTimer.stop();
      //dbg("Mac", "Mac IEEE802.15.4 signal stopDone SUCCESS\n");
      signal Module.drop_message(ack_message);
      ack_message = NULL;
      signal Mgmt.stopDone(SUCCESS);
      return SUCCESS;
    } else {
      //dbg("Mac", "Mac IEEE802.15.4 already stopped\n");
      signal Mgmt.stopDone(SUCCESS);
      //dbg("Mac", "Mac IEEE802.15.4 Mgmt.stop\n");
      return SUCCESS;
    }
  }

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    //dbg("Mac", "Mac IEEE802.15.4 MacCall.getPayload\n");
    uint8_t *m = call RadioCall.getPayload(msg);
    if (m != NULL) {
      return (m + sizeof(nx_struct ieee802154_mac_header) + 2 * call Addressing.length(msg) );
    } else {
      return NULL;
    }
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    //dbg("Mac", "Mac IEEE802.15.4 MacCall.getMaxSize\n");
    return (call RadioCall.getMaxSize(msg)
		- 2 * call Addressing.length(msg)
		- sizeof(nx_struct ieee802154_mac_header)
		- sizeof(nx_struct ieee802154_mac_footer)
		);
  }

  command error_t MacCall.send(msg_t *msg) {
    uint8_t *m;
    nx_struct ieee802154_mac_header *header;

    //dbg("Mac", "Mac IEEE802.15.4 MacCall.send\n");

    /* check is msg is not NULL */
    if (msg == NULL) {
      dbg("Mac", "Mac IEEE802.15.4 MacCall.send - msg == NULL\n");
      return FAIL;
    }

    /* if there is something loaded, we can't send right now */
    if (loaded_message != NULL) {
      //dbg("Mac", "Mac IEEE802.15.4 MacCall.send - loaded_message != NULL\n");
      return FAIL;
    }

    loaded_message = msg;
    nb = 0;
    ns = 0;

    /* get pointer to the payload area */
    m = call RadioCall.getPayload(msg);

    /* check if payload pointer is not NULL */
    if (m == NULL) {
      dbg("Mac", "Mac IEEE802.15.4 MacCall.send - m == NULL\n");
      return FAIL;
    }
    
    msg->len += (2 * call Addressing.length(msg) 
		+ sizeof(nx_struct ieee802154_mac_header)
		+ sizeof(nx_struct ieee802154_mac_footer)	
		);

    header = (nx_struct ieee802154_mac_header*)m;

    dsn = ++dsn % 255;
    header->dsn = dsn;

    /* according to CC2420CsmaP - without security */
    header->fcf &= ((0x3 << IEEE154_FCF_SRC_ADDR_MODE) |
                    (0x3 << IEEE154_FCF_DEST_ADDR_MODE));
    header->fcf |= ( ( IEEE154_TYPE_DATA << IEEE154_FCF_FRAME_TYPE ) |
                     ( 1 << IEEE154_FCF_INTRAPAN ) );

    m += sizeof(nx_struct ieee802154_mac_header);

    /* destination */
    call Addressing.copy((nx_uint8_t*)m, msg->next_hop, msg);

    /* any frame that is broadcast shall be sent with 
     * its Acknowledgment Request subfield set to zero
     * 7.5.6.4 */
    if (use_ack && 
       !call Addressing.eq((nx_uint8_t*)m, call Addressing.addr(BROADCAST, msg), msg))
      header->fcf |= (1 << IEEE154_FCF_ACK_REQ);

    /* source */ 
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    if (ack_message == NULL) {
      post start_loading_data_message();
    }

    return SUCCESS;
  }

  command uint8_t* MacCall.getSource(msg_t *msg) {
    uint8_t *m = call RadioCall.getPayload(msg);
    //dbg("Mac", "Mac IEEE802.15.4 MacCall.getSource\n");
    if (m != NULL) {
      return (m + sizeof(nx_struct ieee802154_mac_header) + call Addressing.length(msg) );
    } else {
      return NULL;
    }
  }

  command uint8_t* MacCall.getDestination(msg_t *msg) {
    uint8_t *m = call RadioCall.getPayload(msg);
    //dbg("Mac", "Mac IEEE802.15.4 MacCall.getDestination\n");
    if (m != NULL) {
      return (m + sizeof(nx_struct ieee802154_mac_header) );
    } else {
      return NULL;
    }
  }

  command error_t MacCall.ack(msg_t *msg) {
    //dbg("Mac", "Mac IEEE802.15.4 MacCall.ack\n");
    return SUCCESS;
  }

  command error_t MacCall.sniffing(bool flag, msg_t *msg) {
    //dbg("Mac", "Mac IEEE802.15.4 MacCall.sniffic\n");
    atomic sniffing = flag;
    return SUCCESS;
  }
  
  event void RadioSignal.receive(msg_t* msg, uint8_t *payload, uint8_t len) {
    nx_struct ieee802154_mac_header *header = 
		(nx_struct ieee802154_mac_header*)call RadioCall.getPayload(msg);

    if (header == NULL) {
      dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive but header is NULL??\n");
      signal Module.drop_message(msg);
      return;
    }

    if (state == S_STOPPED) {
      dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive dropped - S_STOPPED\n");
      signal Module.drop_message(msg);
      return;
    }

    if (header->fcf & ( IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE )) {
      if (header->dsn == dsn && state == S_ACK_WAIT) {
        dbg("Mac", "Mac IEEE802.15.4 receieved ACK %d %d %d %d\n", header->dsn, dsn, state, S_ACK_WAIT);
        call BackoffTimer.stop();
        state = S_STARTED;
        signal MacSignal.sendDone(loaded_message, SUCCESS);
        loaded_message = NULL;
      }
      signal Module.drop_message(msg);
      return;
    }

    if (header->fcf & (1 << IEEE154_FCF_ACK_REQ) && state == S_STARTED) {
      nx_struct ieee802154ack_mac_header *ack_header;

      if (ack_message != NULL) {
        dbg("Mac", "Mac IEEE802.15.4 received but skips ACK sending another ACK\n");
        goto skip_ack;
      }

      ack_message = signal Module.next_message();

      if (ack_message != NULL) {
        uint8_t *m = call RadioCall.getPayload(ack_message);
        
        if (m != NULL) {
    
          dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive received and sending ACK\n");
          ack_message->len = (sizeof(nx_struct ieee802154ack_mac_header)
                   + sizeof(nx_struct ieee802154_mac_footer)
                );
          ack_message->next_hop = BROADCAST;
          ack_header = (nx_struct ieee802154ack_mac_header*)m;
          ack_header->dsn = header->dsn;
          ack_header->fcf = 0;
          ack_header->fcf |= ( ( IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE ) |
                     ( 1 << IEEE154_FCF_INTRAPAN ) );
        
          if (state == S_STARTED) {                
            send_ack();                                           
          }
        } else { 
          dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive received but cannot ACK\n");
          signal Module.drop_message(ack_message);
        }
      }
    }

skip_ack:

    if (header->dsn == last_seen_dsn) {
      dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive drop message - last seen dsn\n");
      signal Module.drop_message(msg);
      return;
    }

    if (msg->len < (2 * call Addressing.length(msg)
                        + sizeof(nx_struct ieee802154_mac_header)
                        + sizeof(nx_struct ieee802154_mac_footer)
      							          )) {
      signal Module.drop_message(msg);
      dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive - msg len too short\n");
      return;
    }

    last_seen_dsn = header->dsn;

    payload += (2 * call Addressing.length(msg) 
		+ sizeof(nx_struct ieee802154_mac_header) 
		);
    
    msg->len -= (2 * call Addressing.length(msg)
			+ sizeof(nx_struct ieee802154_mac_header)
			+ sizeof(nx_struct ieee802154_mac_footer)
		);

    //dbg("Mac", "Mac IEEE802.15.4 RadioSignal.receive and signals MacSignal.receive\n");
    signal MacSignal.receive(msg, payload, msg->len);
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error) {
    nx_struct ieee802154_mac_header *header;

    //dbg("Mac", "Mac IEEE802.15.4 got sendDone\n");
    header = (nx_struct ieee802154_mac_header*)call RadioCall.getPayload(msg);

    if ((header == NULL) || (msg == NULL)) {
      signal Module.drop_message(msg);
      return;
    }

    if (msg == ack_message) {
      dbg("Mac", "Mac IEEE802.15.4 got sendDone for ACK\n");
      signal Module.drop_message(msg);
      ack_message = NULL;
      state = S_STARTED;
      post start_loading_data_message();
      return;
    }

    if (loaded_message != msg) {
      dbg("Mac", "Mac IEEE802.15.4 sendDone - loaded message is different than msg %d %d\n", loaded_message, msg);
      post signal_send_done_fail();
      return;
    }

    if (state == S_TRANSMITTING && error == SUCCESS) {
      if (header->fcf & (1 << IEEE154_FCF_ACK_REQ)) {
        /* wait with signaling send done till ACK arrives */
        dbg("Mac", "Mac IEEE802.15.4 sendDone - requires ACK so S_ACK_WAIT\n");
        call BackoffTimer.startOneShot(ack_wait_time);
        state = S_ACK_WAIT;
      } else {
        dbg("Mac", "Mac IEEE802.15.4 sendDone - send done whatever\n");
        signal MacSignal.sendDone(msg, error);
        call BackoffTimer.stop();
        loaded_message = NULL;
        state = S_STARTED;
      }
    } else {
      dbg("Mac", "Mac IEEE802.15.4 sendDone - something goes wrong\n");
      post start_loading_data_message();
    }

    if (ack_message != NULL) {
      /* there is ack message waiting to be sent */
      dbg("Mac", "Mac: there is ack message waiting to be sent\n");
      send_ack();
    }
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error) {
    //dbg("Mac", "Mac IEEE802.15.4 RadioSignal.loadDone message to %d\n", msg->next_hop);

    if (msg == ack_message) {
      if (error == SUCCESS) {
        dbg("Mac", "Mac IEEE802.15.4 loadDone, send Ack asap\n");
        call RadioCall.send(ack_message);
      } else {
        send_ack();
      }
      return;
    }

    if (loaded_message != msg) {
      dbg("Mac", "Mac IEEE802.15.4 loadDone, loaded_message != msg\n");
      signal Module.drop_message(msg);
      return;
    }

    if (msg->asap == ON) {
      if ( error == SUCCESS) {
        dbg("Mac", "Mac IEEE802.15.4 loadDone, send message asap\n");
        state = S_TRANSMITTING;
        post send_data_message();
      } else {
        post start_loading_data_message();
      }
      return;
    }

    if (error == SUCCESS) {
      state = S_SAMPLE_CCA;
      getBackoff(initial_backoff);
    } else {
      post start_loading_data_message();
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    nx_struct ieee802154_mac_header *header;

    //dbg("Mac", "Mac IEEE802.15.4 RadioSignal.check_destination\n");

    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    /* if we do not care about checking destination, say always TRUE */
    if (!use_dest_check)
      return TRUE;

    /* check if it is ACK msg */
    header = (nx_struct ieee802154_mac_header*)payload;
    if ((header->fcf & ( IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE ))) {
      return TRUE;
    }

    /* check destination address */
    payload += sizeof(nx_struct ieee802154_mac_header);

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(BROADCAST, msg), msg))
      return TRUE;
   

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(NODE, msg), msg))
      return TRUE;
    
    return sniffing;
  }

  /* 7.5.1.4 CSMA-CA algorithm */
  event void BackoffTimer.fired() {
    switch(state) {
      case S_SAMPLE_CCA:
        //dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_SAMPLE_CCA\n");
        if (!use_cca || call RadioCall.sampleCCA(loaded_message)) {
          nx_struct ieee802154_mac_header *header =
                (nx_struct ieee802154_mac_header*)call RadioCall.getPayload(loaded_message);
          //dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_SAMPLE_CCA -> S_TRANSMITTING\n");
          state = S_TRANSMITTING;
          if ((!use_cca) || (loaded_message->asap == ON) || 
		((header != NULL) && (header->fcf & ( IEEE154_TYPE_ACK << IEEE154_FCF_FRAME_TYPE ))) ||
		(loaded_message->next_hop == BROADCAST)) {
            //dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired - start TX without ACK\n");
          }
        } else {
          nb++;
          if ((nb < max_cca_retries) && (ns < max_send_retries)) {
            dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_SAMPLE_CCA - retry\n");
            getBackoff(congestion_backoff);
          } else {
            dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_SAMPLE_CCA - too many retries\n");
            call RadioCall.cancel(loaded_message);
            post signal_send_done_fail();
          }
          break;
        }

      case S_TRANSMITTING:
        //dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_TRANSMITTING\n");
        post send_data_message();
        break;

      case S_ACK_WAIT:
        //dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_ACK_WAIT\n");
        post start_loading_data_message();
        break;

      case S_LOADING:
        //dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired S_LOADING\n");
        post start_loading_data_message();
        break;

      default:
        dbg("Mac", "Mac IEEE802.15.4 BackoffTimer.fired - default but in state %d\n", state);
        break;
    }
  }
}

