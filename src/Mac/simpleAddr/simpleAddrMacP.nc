/*
 *  Dummy mac module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
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
 * Network: Dummy Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "simpleAddrMac.h"

generic module simpleAddrMacP() {

  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
}

implementation {

  command error_t Mgmt.start() {
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t MacAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
    nx_struct simpleAddr_mac_header *header = (nx_struct simpleAddr_mac_header*) call RadioAMSend.getPayload(msg, len);

    if (header == NULL) return FAIL;

    header->src = TOS_NODE_ID;
    header->dest = addr;

    return call RadioAMSend.send(addr, msg, len + sizeof(nx_struct simpleAddr_mac_header));
  }

  command error_t MacAMSend.cancel(message_t* msg) {
    return call RadioAMSend.cancel(msg);
  }

  command uint8_t MacAMSend.maxPayloadLength() {
    return (call RadioAMSend.maxPayloadLength() - sizeof(nx_struct simpleAddr_mac_header));
  }

  command void* MacAMSend.getPayload(message_t* msg, uint8_t len) {
    uint8_t *m = call RadioAMSend.getPayload(msg, len);
    return m + sizeof(nx_struct simpleAddr_mac_header);
  }

  event void RadioAMSend.sendDone(message_t *msg, uint8_t len) {
    signal MacAMSend.sendDone(msg, len);
  }

  event message_t* RadioReceive.receive(message_t *msg, void* payload, uint8_t len) {
    nx_struct simpleAddr_mac_header *header = (nx_struct simpleAddr_mac_header*) call RadioAMSend.getPayload(msg, len);
    if (header->dest != TOS_NODE_ID) {
      return msg;
    } else {
      uint8_t *p = (uint8_t*)payload;
      p = p + sizeof(nx_struct simpleAddr_mac_header);
      len = len - sizeof(nx_struct simpleAddr_mac_header);
      return signal MacReceive.receive(msg, p, len);
    }
  }
}

