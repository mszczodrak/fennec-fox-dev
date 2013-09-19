/*
 *  Ctp network module for Fennec Fox platform.
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
 * Network: Ctp Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "ctpNet.h"

module ctpNetP {
provides interface Mgmt;

uses interface ctpNetParams;
uses interface Leds;

provides interface ModuleStatus as NetworkStatus;
provides interface AMSend as NetworkAMSend;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface StdControl as RoutingControl;
uses interface RootControl;
uses interface Send as CtpSend;
uses interface AMPacket as CtpAMPacket;
uses interface Packet as CtpPacket;
uses interface PacketAcknowledgements as CtpPacketAcknowledgements;
}

implementation {

command error_t Mgmt.start() {
	call RoutingControl.start();
	if (TOS_NODE_ID == call ctpNetParams.get_root()) {
		call RootControl.setRoot();
	}

	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

event void CtpSend.sendDone(message_t* msg, error_t error) {
	signal NetworkAMSend.sendDone(msg, error);
}

command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	return call CtpSend.send(msg, len);
}

command error_t NetworkAMSend.cancel(message_t* msg) {
	return call CtpSend.cancel(msg);
}

command uint8_t NetworkAMSend.maxPayloadLength() {
	return call CtpSend.maxPayloadLength();
}

  command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
    return call CtpSend.getPayload(msg, len);
  }

  command am_addr_t NetworkAMPacket.address() {
    return call CtpAMPacket.address();
  }

  command am_addr_t NetworkAMPacket.destination(message_t* amsg) {
    return call CtpAMPacket.destination(amsg);
  }

  command am_addr_t NetworkAMPacket.source(message_t* amsg) {
    return call CtpAMPacket.source(amsg);
  }

  command void NetworkAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
    return call CtpAMPacket.setDestination(amsg, addr);
  }

  command void NetworkAMPacket.setSource(message_t* amsg, am_addr_t addr) {
    return call CtpAMPacket.setSource(amsg, addr);
  }

  command bool NetworkAMPacket.isForMe(message_t* amsg) {
    return call CtpAMPacket.isForMe(amsg);
  }

  command am_id_t NetworkAMPacket.type(message_t* amsg) {
    return call CtpAMPacket.type(amsg);
  }

  command void NetworkAMPacket.setType(message_t* amsg, am_id_t t) {
    return call CtpAMPacket.setType(amsg, t);
  }

  command am_group_t NetworkAMPacket.group(message_t* amsg) {
    return call CtpAMPacket.group(amsg);
  }

  command void NetworkAMPacket.setGroup(message_t* amsg, am_group_t grp) {
    return call CtpAMPacket.setGroup(amsg, grp);
  }

  command am_group_t NetworkAMPacket.localGroup() {
    return call CtpAMPacket.localGroup();
  }

  command void NetworkPacket.clear(message_t* msg) {
    return call CtpPacket.clear(msg);
  }

  command uint8_t NetworkPacket.payloadLength(message_t* msg) {
    return call CtpPacket.payloadLength(msg);
  }

  command void NetworkPacket.setPayloadLength(message_t* msg, uint8_t len) {
    return call CtpPacket.setPayloadLength(msg, len);
  }

  command uint8_t NetworkPacket.maxPayloadLength() {
    return call CtpPacket.maxPayloadLength();
  }

  command void* NetworkPacket.getPayload(message_t* msg, uint8_t len) {
    return call CtpPacket.getPayload(msg, len);
  }

  async command error_t NetworkPacketAcknowledgements.requestAck( message_t* msg ) {
    return call CtpPacketAcknowledgements.requestAck(msg);
  }

  async command error_t NetworkPacketAcknowledgements.noAck( message_t* msg ) {
    return call CtpPacketAcknowledgements.noAck(msg);
  }

  async command bool NetworkPacketAcknowledgements.wasAcked(message_t* msg) {
    return call CtpPacketAcknowledgements.wasAcked(msg);
  }

}
