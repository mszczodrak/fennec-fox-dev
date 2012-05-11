/*
 *  SimpleMac protocol for Fennec Fox platform.
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
 * Application: implementation of simple MAC protocol, just sends
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/4/2011
 */

#include <Fennec.h>
#include "simpleMac.h"

generic module simpleMacP() {

  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface Addressing;
  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {

  uint8_t state = S_STOPPED;

  command error_t Mgmt.start() {
    if (state == S_STARTED) {
      //dbg("Mac", "Mac simple already started\n");
      signal Mgmt.startDone(SUCCESS);
      return SUCCESS;
    }
    //dbg("Mac", "Mac simple starting\n");

    dbgs(F_MAC, S_NONE, DBGS_MGMT_START, 0, 0);

    state = S_STARTED;

    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    if (state == S_STOPPED) {
      //dbg("Mac", "Mac simple already stopped\n");
      signal Mgmt.stopDone(SUCCESS);
      return SUCCESS;
    }
    //dbg("Mac", "Mac simple stopping\n");

    dbgs(F_MAC, S_NONE, DBGS_MGMT_STOP, 0, 0);

    state = S_STOPPED;

    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  command uint8_t* MacCall.getPayload(msg_t *msg) {
    return call RadioCall.getPayload(msg);
  }

  command uint8_t MacCall.getMaxSize(msg_t *msg) {
    return (call RadioCall.getMaxSize(msg));
  }

  command error_t MacCall.send(msg_t *msg) {
    if (msg != NULL) {
      msg->len += sizeof(nx_struct simpleMac_mac_footer);
      return call RadioCall.load(msg);
    }
    return FAIL;
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
    if (msg != NULL) {
      msg->len -= sizeof(nx_struct simpleMac_mac_footer);
      signal MacSignal.receive(msg, payload, msg->len);
    } else {
      signal Module.drop_message(msg);
    }
  }

  event void RadioSignal.sendDone(msg_t *msg, error_t error) {
    //dbg("Mac", "Mac simple RadioSignal.sendDone\n");
    signal MacSignal.sendDone(msg, error);
  }

  event void RadioSignal.loadDone(msg_t *msg, error_t error) {
    if ((error == SUCCESS) && (msg != NULL)) {
      call RadioCall.send(msg);
    } else {
      signal MacSignal.sendDone(msg, FAIL);
    }
  }

  async event bool RadioSignal.check_destination(msg_t *msg, uint8_t *payload) {
    /* check configuration number */
    if (!check_configuration(msg))
      return FALSE;

    return TRUE;
  }
}

