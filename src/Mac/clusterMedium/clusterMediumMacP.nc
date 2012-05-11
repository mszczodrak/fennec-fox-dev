/*
 *  clusterMedium mac protocol for Fennec Fox platform.
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
 * Application: implementation of clusterMedium
 * Author: Marcin Szczodrak
 * Date: 9/28/2011
 * Last Modified: 9/30/2011
 */

#include <Fennec.h>
#include "clusterMediumMac.h"

/* p - p-persistent value ; 1 is 0.01 and 100 for 1
 * cluster id - nodes with the same id are in the same cluster
 */
generic module clusterMediumMacP(uint8_t p, uint8_t cluster_id) {

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
                + sizeof(uint8_t)  /* len */
                );
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg)
                - sizeof(uint8_t) /* len */
                );
  }

  event void BackoffTimer.fired() {
    post send_when_clear();
  }

  command error_t MacCall.send(msg_t *msg) {
    nx_struct cluster_medium_mac_header *header;
    dbg("Mac", "Mac clusterMedium: MacCall.send\n");

    if (msg == NULL) return FAIL;

    header = (nx_struct cluster_medium_mac_header*) call RadioCall.getPayload(msg);

    if (header == NULL) return FAIL;

    header->cluster_id = cluster_id;

    msg->len += (sizeof(nx_struct cluster_medium_mac_header));
    msg->next_hop = BROADCAST;

    if ((call RadioCall.load(msg)) == SUCCESS)
      return SUCCESS;

    signal MacSignal.sendDone(msg, FAIL);
    return FAIL;
  }

  command uint8_t* MacCall.getSource(msg_t *msg) {
    dbg("Mac", "Mac clusterMedium: MacCall.getSource\n");
    return NULL;
  }

  command uint8_t* MacCall.getDestination(msg_t *msg) {
    dbg("Mac", "Mac clusterMedium: MacCall.getDestination\n");
    return NULL;
  }

  command error_t MacCall.ack(msg_t *msg) {
    dbg("Mac", "Mac clusterMedium: MacCall.ack\n");
    return SUCCESS;
  }

  command error_t MacCall.sniffing(bool flag, msg_t *msg) {
    dbg("Mac", "Mac clusterMedium: MacCall.sniffing\n");
    return SUCCESS;
  }

  event void RadioSignal.receive(msg_t* msg, uint8_t *payload, uint8_t len) {
    nx_struct cluster_medium_mac_header *header;

    dbg("Mac", "Mac clusterMedium: RadioSignal.receive\n");

    if ((msg == NULL) || (payload == NULL)) {
      signal Module.drop_message(msg);
      return;
    }

    header = (nx_struct cluster_medium_mac_header*) payload;


    payload += sizeof(nx_struct cluster_medium_mac_header);
    msg->len -= sizeof(nx_struct cluster_medium_mac_header);

    signal MacSignal.receive(msg, payload, msg->len);

  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error){
    dbg("Mac", "Mac clusterMedium: RadioSignal.sendDone\n");
    if (msg != NULL) {
      call BackoffTimer.stop();
      signal MacSignal.sendDone(msg, error);
    }
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error){
    dbg("Mac", "Mac clusterMedium: RadioSignal.loadDone\n");
    if (msg == NULL) return;

    if (error != SUCCESS) {
      signal MacSignal.sendDone(msg, FAIL);
    } else {
      last_message = msg;
      post send_when_clear();
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    nx_struct cluster_medium_mac_header *header;

    dbg("Mac", "Mac clusterMedium: RadioSignal.check_destination \n");

    if ((msg == NULL) || (payload == NULL)) return FALSE;    

    /* check configuration number */
    if (!check_configuration(msg)) return FALSE;

    /* check cluster id */
    header = (nx_struct cluster_medium_mac_header*) payload;
    if (header->cluster_id != cluster_id) return FALSE;

    return TRUE;
  }

  task void send_when_clear() {
    dbg("Mac", "Mac clusterMedium: send_when_clear \n");
    if ( ( call RadioCall.sampleCCA(last_message) ) &&  
      ( (call Random.rand16() % 100 ) + 1 <= p ) ) {
      if ((call RadioCall.send(last_message)) != SUCCESS) {
        signal MacSignal.sendDone(last_message, FAIL);
      }
    } else {
      call BackoffTimer.startOneShot( CLUSTER_MEDIUM_SAMPLE_DELAY );
    }
  }

}

