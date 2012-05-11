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
#include "csmaMac.h"

generic module csmaMacP() {

  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;
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

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    return (call RadioCall.getPayload(msg));
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg));
  }

  command error_t MacCall.send(msg_t *msg) {
    return call RadioCall.load(msg);
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
    signal MacSignal.receive(msg, payload, msg->len);
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error) {
    signal MacSignal.sendDone(msg, error);
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error) {
    call RadioCall.send(msg);
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    return TRUE;
  }
}

