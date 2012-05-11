/*
 *  IDEP (Iterative Data Exchane Protocol) network module for Fennec Fox platform.
 *
 *  Copyright (C) 2011 Marcin Szczodrak
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
 * Network: IDEP protocol
 * Author: Marcin Szczodrak
 * Date: 9/7/2011
 * Last Modified: 9/13/2011
 */

#include <Fennec.h>
#include "idepNet.h"

generic module idepNetP(uint8_t entry_len, uint8_t cluster_size) {
  provides interface Mgmt;
  provides interface Module;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface Addressing;
  uses interface MacCall;
  uses interface MacSignal;

  uses interface Random;
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
}

implementation {

  uint16_t s_seq;   /* iteration sequence counter */
  msg_t *idep_msg;  /* pointer to a message that we send and which also works as 
		     * a buffer for incomming data */
  msg_t *apps_msg;  /* the actual message that we receive from application */
  uint8_t idep_entry_counter; /* counter saying how many data we received in latest run */
  void *idep_beginning;  /* pointer to the beginning of the payload space in idep_msg */
  void *apps_data;  /* pointer to the data received from local application */
  
  /* Definitions of Utility Functions */
  void send_task();		/* sends idep_msg */
  void signal_receive();        /* signals to app receive of message with data from 
				 * other neighboors the actual message is the idep_msg */

  uint8_t incoming_missing(msg_t *msg, uint8_t *payload, uint8_t len);
				/* checks if a received message is missing data elements
				 * that we already have */
  error_t insert_idep_value(msg_t *msg, uint8_t *payload, uint8_t len);
				/* inserts new data elements into local buffer (idep_msg)
				 * based on data received from incomming message */

  void *find_data(void *ptr);   /* searches local IDEP message for data record with the same
				 * data as the data pointed by ptr. If finds, it returns the
				 * pointer to the buffer space, otherwise NULL */

  /* This is where Fennec Fox module starts its life */
  command error_t Mgmt.start() {
    error_t err = SUCCESS;
    dbg("Network", "Network idep Mgmt.start\n");
    s_seq = 1;
    idep_entry_counter = 0;
    idep_msg = signal Module.next_message(); /* request memory space for new message */
    if (idep_msg == NULL) err = FAIL;
    idep_beginning = call NetworkCall.getPayload(idep_msg); /* get pointer to data payload */
    if (idep_beginning == NULL) err = FAIL;
    signal Mgmt.startDone(err);   /* Fennec Fox waits for a module to signal when it's done
				   * with initializing */
    return err;
  }

  /* This is where Fennec Fox module stops */
  command error_t Mgmt.stop() {
    dbg("Network", "Network idep Mgmt.stop\n");
    call Timer0.stop();
    call Timer1.stop();
    signal Module.drop_message(idep_msg);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  /* Application asks for a pointer to App's data payload */
  command uint8_t* NetworkCall.getPayload(msg_t* msg) {
    uint8_t *m;

    dbg("Network", "Network idep NetworkCall.getPayload\n");

    m = call MacCall.getPayload(msg);
    if (m == NULL) return NULL;
    return m + sizeof(nx_struct idep_header);
  }

  /* Application request to send data.
   * the data length is in msg_t.len
   * data destination is in msg_t.next_hop
   */
  command error_t NetworkCall.send(msg_t *msg) {
    dbg("Network", "Network idep NetworkCall.send\n");
    if (apps_msg != NULL) {
      /* busy */
      dbg("Network", "Network fails to send because it's busy\n");
      return FAIL;
    }

    if (msg == NULL) {
      return FAIL;
    }

    if (call Timer1.isRunning()) {
      dbg("Network", "Network fails to send as it's still running\n");
      return FAIL;
    }

    /* set upper bound time for which we plan to successfully run exchange the data */
    call Timer1.startOneShot(IDEP_MAX_OWN_TRANSMISSION_DELAY);

    /* store a pointer to app's message so we know what to signal in sendDone */
    apps_msg = msg;

    insert_idep_value(msg, call NetworkCall.getPayload(msg), entry_len);

    apps_data = find_data(call NetworkCall.getPayload(msg));

    return SUCCESS;
  }

  /* Application asks for maximum data payload size */
  command uint8_t NetworkCall.getMaxSize(msg_t *msg) {
    dbg("Network", "Network idep NetworkCall.getMaxSize\n");
    if (msg == NULL) return 0;
    return call MacCall.getMaxSize(msg) - sizeof(nx_struct idep_header);
  }

  /* Application asks for a pointer to the source address field */
  command uint8_t* NetworkCall.getSource(msg_t* msg) {
    if (msg == NULL) return NULL;

    dbg("Network", "Network idep NetworkCall.getSource\n");
    return NULL;
  }

  /* Application asks for a pointer to the destination address field */
  command uint8_t* NetworkCall.getDestination(msg_t* msg) {
    dbg("Network", "Network idep NetworkCall.getDestination\n");
    return NULL;
  }

  /* Functions handling events from supporting interfaces (from MAC) */

  event void MacSignal.sendDone(msg_t *msg, error_t err) {
    if (msg == NULL) return;

    dbg("Network", "Network idep MacSignal.sendDone\n");
    /* set the next time to fire the message */ 
    if (err != SUCCESS) {
      dbg("Network", "Network got from MAC send done fail\n");
    } else {
      if (apps_msg != NULL) {
        signal NetworkSignal.sendDone(apps_msg, SUCCESS);
        apps_msg = NULL;   
      }
    }

    call Timer0.startOneShot(call Random.rand32() % IDEP_RANDOM_DELAY_PERIOD + IDEP_MIN_DELAY_PERIOD);
  }

  event void MacSignal.receive(msg_t *msg, uint8_t *payload, uint8_t len) {
    uint8_t *app_payload;
    nx_struct idep_header *header;
    uint8_t number_of_missing = 0;
    uint32_t dt;
    uint32_t delta_dt;

    dbg("Network", "Network idep MacSignal.receive\n");

    if ((msg == NULL) || (payload == NULL) || (len == 0)) {
      return;
    }

    app_payload = call NetworkCall.getPayload(msg);
    header = (nx_struct idep_header*) payload;
    msg->len -= sizeof(nx_struct idep_header);

    /* this check is temporary, just for testing purposes */
    if (TOS_NODE_ID >= 10) {
      signal Module.drop_message(msg);
      return;
    }

    if (len <= 0) {
      signal Module.drop_message(msg);
      return;
    }

    /* this is Trickle-like check, to see that the incomming sequence is the recent one */
    if (header->seq < s_seq) {
      //dbg("Network", "Network received old sequence, ignore\n");
      signal Module.drop_message(msg);
      return;
    }

    /* also Trickle-like check, see if we should already upgrade ourself to the new sequence */
    if (header->seq > s_seq) {
      dbg("Network", "Network received higher sequence, finish the old sequence\n");
      /* first cleanup the current state */
      s_seq = header->seq - 1;
      apps_data = NULL;
      if (apps_msg != NULL) {
        signal NetworkSignal.sendDone(apps_msg, FAIL);
        apps_msg = NULL;
      }
      signal_receive();
    }

    /* if there is any new data in the incomming message, insert it into our message */
    insert_idep_value(msg, app_payload, msg->len);

    /* check if the incomming message is missing any data that we already have */
    number_of_missing = incoming_missing(msg, app_payload, msg->len);

    dt = call Timer0.getdt();

    if (number_of_missing) {
      //dbg("Network", "Network found that sender is missing %d entries\n", number_of_missing);
      /* Since our neighbor is missing something, let's speed up our transmission */
      delta_dt = number_of_missing * IDEP_MISSING_IMPACT; 
      
      /* check that delta_dt is less than dt, otherwise we would get overflow */
      if (dt > delta_dt) dt = dt - delta_dt;

    } else {
      //dbg("Network", "Net found that nothing is missing\n");
      /* Since someone already transmitted what we plan to send, let's delay our transmission */
      dt = dt + IDEP_DELAY_INCREASE; 
    }

    call Timer0.startOneShot(dt);

    signal Module.drop_message(msg);
  }

  /* TinyOS / FennecFox events - comming not from layers */

  event void Timer0.fired() {
    dbg("Network", "Network idep Timer0.fired\n");
    send_task();
  }

  event void Timer1.fired() {
    dbg("Network", "Network idep Timer1.fired\n");
    signal_receive();
  }


  /* Utility Functions */
  void send_task() {
    nx_struct idep_header *header;

    dbg("Network", "Network idep send_task\n");

    if (idep_msg == NULL) {
      return;
    }

    header = (nx_struct idep_header*) call MacCall.getPayload(idep_msg);

    if (header == NULL) {
      return;
    }

    header->seq = s_seq;
    header->flags = 0;
    header->len = entry_len;
    header->counter = idep_entry_counter;

    dbg("Network", "Network idep send_task\n");

    idep_msg->len = (idep_entry_counter * entry_len) + sizeof(nx_struct idep_header);
    idep_msg->next_hop = BROADCAST;

    call MacCall.send(idep_msg);
  }

  /* send Application receive signal */
  void signal_receive() {
    msg_t *message;
    dbg("Network", "Network idep signal_receive\n");

    dbg("Network", "Network reports to application receive of %d units of data\n",
								idep_entry_counter);

    call Timer1.stop();

    /* check if we have done at least one transmission */
    if (apps_msg != NULL) {
      /* Oups, we haven't transmitted even once */
      dbg("Network", "Network has not transmitted even once, so before we finish transmit own data\n");
      send_task();
      call Timer1.startOneShot(IDEP_HARD_LIMIT);
      return;
    }

    /* check if someone has transmitted our data */
    if (apps_data != NULL) {
      /* Oups, we haven't transmitted even once */
      dbg("Network", "Network: noone has transmitted my data!\n");
      /* this is a one-time shot, so we make sure to skip it next time */
      apps_data = NULL;
      return;
    }

    /* stop Timer, no more resending */
    call Timer0.stop();

    message = signal Module.next_message();

    if ((message != NULL) || (idep_msg != NULL)) {
      /* signal up the message, as it would be a received message */
      memcpy(message, idep_msg, sizeof(msg_t));
      signal NetworkSignal.receive(message, call NetworkCall.getPayload(message), 
				idep_entry_counter*entry_len);
    } else {
      dbg("Network", "Network got a huge problem... there is no space for idep_msg\n");
    }

    idep_entry_counter = 0;

    /* reinitiate the state, get yourself a new idep_msg memory space */
    idep_beginning = call NetworkCall.getPayload(idep_msg);

    /* get ready for the next round */
    s_seq++;
  }

  error_t insert_idep_value(msg_t *msg, uint8_t *payload, uint8_t len) {
    /* check if the payload is unique */
    void *inptr;
    void *eptr;
    uint8_t i;
    uint8_t new_payload_counter;

//    dbg("Network", "Network idep insert_idep_value\n");

    if ((msg == NULL) || (payload == NULL)) return FAIL;

    if (entry_len != 0) {
      new_payload_counter = len / entry_len;
    } else {
      dbg("Network", "Network idep divide by 0\n");
      signal Module.drop_message(msg);
      return FAIL;
    }

    /* check if we have already found all data and just waiting to report to app */
    if (idep_entry_counter == cluster_size) {
      return SUCCESS;
    }

    /* 
     * check every entry of the new payload with every entry of already existing payloads
     * bottom line: evoid duplicates 
     */

    dbg("Network", "Network idep here 1\n");

    i = 0;
    while (i < new_payload_counter) {
      /* outer loop scans across the entries of the incoming payload */
      
      inptr = payload + (i * entry_len);

      /* check if neighboring node has transmitted our data */
      if ((apps_data != NULL) && !memcmp(inptr, apps_data, entry_len)) {
        //dbg("Network", "Network: someone has transmitted\n");
        apps_data = NULL;
      }

      if (!find_data(inptr)) {
        /* new data so insert */
        if ((idep_beginning != NULL) && (inptr != NULL)) {
          eptr = idep_beginning + ((idep_entry_counter ) * entry_len);
          memcpy(eptr, inptr, entry_len);
          idep_entry_counter++;
          /* restart the timer since new 'staff' flies around */
          call Timer0.startOneShot(call Random.rand16() % IDEP_RANDOM_DELAY_PERIOD 
							+ IDEP_MIN_DELAY_PERIOD);
	}
      }
      i++;
    }

    /* check if we have already received data from everybody in the network */
    if (idep_entry_counter == cluster_size) {
      //dbg("Network", "Network found everything\n");
      uint32_t dt = call Timer1.getdt();
      if (dt > IDEP_RECEIVE_DELAY) {
        /* if dt left is more than constant IDEP_RECEIVE_DELAY, and we are already done,
         * then just wait for IDEP_RECEIVE_DELAY */
        call Timer1.startOneShot(IDEP_RECEIVE_DELAY); 
      }
    }

    dbg("Network", "Network done with inserting\n");
    return SUCCESS;
  }

  uint8_t incoming_missing(msg_t *msg, uint8_t *payload, uint8_t len) {
    void *inptr;
    uint8_t i;
    uint8_t new_payload_counter;
    uint8_t found = 0;

    dbg("Network", "Network idep incoming_missing\n");

    if ((msg == NULL) || (payload == NULL)) return 0;

    if (entry_len != 0) {
      new_payload_counter = len / entry_len;
    } else {
      dbg("Network", "Network idep divide by 0\n");
      signal Module.drop_message(msg);
      return 0;
    }

    i = 0;
    /* for every element of incomming payload */
    while (i < new_payload_counter) {
      inptr = payload + (i * entry_len);

      /* see if it already is in our memory */
      if (find_data(inptr) != NULL) {
        /* equal - count how many elements were found */
        found++;
      }

      i++;
    }
    /* return the number of elements we believe the sender is missing */
    return new_payload_counter - found;
  }

  /* returns pointer to the same data in the buffer field */
  void *find_data(void *ptr) {
    void *eptr;

    if ((ptr == NULL) || (idep_beginning == NULL)) return NULL;

    dbg("Network", "Network idep find_data\n");

    for(eptr = idep_beginning; eptr < idep_beginning + (idep_entry_counter * entry_len);
                                                                        eptr += entry_len) {
      if (!memcmp(ptr, eptr, entry_len)) {
        return eptr; 
      }
    }
    return NULL;
  }
}
