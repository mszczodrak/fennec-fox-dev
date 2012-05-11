/*
 *  Broadcast network module for Fennec Fox platform.
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
 * Network: Broadcast message
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/5/2011
 */


#include <Fennec.h>
#include "broadcastNet.h"

generic module broadcastNetP() {
  provides interface Mgmt;
  provides interface Module;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface Addressing;
  uses interface MacCall;
  uses interface MacSignal;
}

implementation {

  uint16_t s_seq;

  command error_t Mgmt.start() {
    s_seq = 0;
    dbgs(F_NETWORK, S_NONE, DBGS_MGMT_START, 0, 0);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbgs(F_NETWORK, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* NetworkCall.getPayload(msg_t* msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    if (m == NULL) return NULL;
    return m + sizeof(nx_struct broadcast_header) + call Addressing.length(msg);
  }

  command error_t NetworkCall.send(msg_t *msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    nx_struct broadcast_header *header = (nx_struct broadcast_header*) m;

    header->seq = ++s_seq;
    header->flags = 0;
 
    /* destination */
    m += sizeof(nx_struct broadcast_header);
    call Addressing.copy((nx_uint8_t*)m, BROADCAST, msg);

    msg->len += sizeof(nx_struct broadcast_header) + call Addressing.length(msg);
    msg->next_hop = BROADCAST;

    return call MacCall.send(msg);
  }

  command uint8_t NetworkCall.getMaxSize(msg_t *msg) {
    return (call MacCall.getMaxSize(msg) - sizeof(nx_struct broadcast_header) - 
        call Addressing.length(msg));
  }

  command uint8_t* NetworkCall.getSource(msg_t* msg) {
    return NULL;
  }

  command uint8_t* NetworkCall.getDestination(msg_t* msg) {
    uint8_t *m = call MacCall.getPayload(msg);
    return m + sizeof(nx_struct broadcast_header);
  }

  event void MacSignal.sendDone(msg_t *msg, error_t err) {
    signal NetworkSignal.sendDone(msg, err);
  }

  event void MacSignal.receive(msg_t *msg, uint8_t *payload, uint8_t len) {
    uint8_t *m = payload + sizeof(nx_struct broadcast_header);
    msg->len -= (sizeof(nx_struct broadcast_header) + call Addressing.length(msg));

    if (len <= 0) {
      signal Module.drop_message(msg);
      return;
    }

    signal NetworkSignal.receive(msg, m + call Addressing.length(msg), msg->len);
  }
}
