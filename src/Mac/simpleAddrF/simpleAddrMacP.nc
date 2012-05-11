/*
 *  SimpleiAddrMac protocol for Fennec Fox platform.
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
 * Application: implementation of simple MAC protocol, just sends and checks address
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/4/2011
 */

#include <Fennec.h>
#include "simpleAddrMac.h"

generic module simpleAddrMacP() {

  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {

  bool sniffing;

  command error_t Mgmt.start() {
    atomic sniffing = FALSE;
    dbgs(F_MAC, S_NONE, DBGS_MGMT_START, 0, 0);
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    dbgs(F_MAC, S_NONE, DBGS_MGMT_STOP, 0, 0);
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    uint8_t *m;
    m = call RadioCall.getPayload(msg);
    if (m == NULL) return NULL;
    return m + 2 * call Addressing.length(msg);
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg)
		- 2 * call Addressing.length(msg)
		- sizeof(nx_struct simpleAddr_mac_footer)
		);
  }

  command error_t MacCall.send(msg_t *msg) {
    uint8_t *m = call RadioCall.getPayload(msg);

    msg->len += (2 * call Addressing.length(msg) 
		+ sizeof(nx_struct simpleAddr_mac_footer)	
		);

    /* destination */
    call Addressing.copy((nx_uint8_t*)m, msg->next_hop, msg);

    /* source */ 
    m += call Addressing.length(msg);
    call Addressing.copy((nx_uint8_t*)m, NODE, msg);

    if ((call RadioCall.load(msg)) == SUCCESS){
      return SUCCESS;
    }
    return FAIL;
  }

  command uint8_t* MacCall.getSource(msg_t *msg) {
    return (call RadioCall.getPayload(msg) 
                + call Addressing.length(msg) 
		);
  }

  command uint8_t* MacCall.getDestination(msg_t *msg) {
    return (call RadioCall.getPayload(msg) 
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
    payload += 2 * call Addressing.length(msg);

    msg->len -= (2 * call Addressing.length(msg)
			+ sizeof(nx_struct simpleAddr_mac_footer)
		);
    signal MacSignal.receive(msg, payload, msg->len);
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error) {
    //dbg("Mac", "Mac sends done whatever comes from radio\n");
    signal MacSignal.sendDone(msg, error);
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error) {
    call RadioCall.send(msg);
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    /* check destination address */

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(BROADCAST, msg), msg))
      return TRUE;
   

    if (call Addressing.eq((nx_uint8_t*)payload, call Addressing.addr(NODE, msg), msg))
      return TRUE;
    
    return sniffing;
  }
}

