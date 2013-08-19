/*
 *  null application module for Fennec Fox platform.
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
 * Application: null Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "nullApp.h"

module nullAppP {
  provides interface Mgmt;
  provides interface Module;

  uses interface nullAppParams;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {

  command error_t Mgmt.start() {
    //dbg("Application", "Application null starts\n");
    signal Mgmt.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Mgmt.stop() {
    //dbg("Application", "Application null stops\n");
    signal Mgmt.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void NetworkAMSend.sendDone(message_t *msg, error_t error) {}

  event message_t* NetworkReceive.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event message_t* NetworkSnoop.receive(message_t *msg, void* payload, uint8_t len) {
    return msg;
  }

  event void NetworkStatus.status(uint8_t layer, uint8_t status_flag) {
  }

  event void nullAppParams.receive_status(uint16_t status_flag) {
  }

}
