/*
 *  null network module for Fennec Fox platform.
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
 * Network: null Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include "nullNet.h"

module nullNetP {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as NetworkAMSend;
  provides interface Receive as NetworkReceive;
  provides interface Receive as NetworkSnoop;
  provides interface AMPacket as NetworkAMPacket;
  provides interface Packet as NetworkPacket;
  provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  provides interface ModuleStatus as NetworkStatus;

  uses interface nullNetParams;

  uses interface AMSend as MacAMSend;
  uses interface Receive as MacReceive;
  uses interface Receive as MacSnoop;
  uses interface AMPacket as MacAMPacket;
  uses interface Packet as MacPacket;
  uses interface PacketAcknowledgements as MacPacketAcknowledgements;
  uses interface ModuleStatus as MacStatus;
}

implementation {

command error_t Mgmt.start() {
	dbg("Network", "nullNet Mgmt.start()");
	signal Mgmt.startDone(SUCCESS);
	return SUCCESS;
}

command error_t Mgmt.stop() {
	dbg("Network", "nullNet Mgmt.stop()");
	signal Mgmt.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	if ((addr == TOS_NODE_ID) || (addr == NODE)) {
		signal NetworkAMSend.sendDone(msg, SUCCESS);
		signal MacReceive.receive(msg, 
		call NetworkAMSend.getPayload(msg, len + 
				sizeof(nx_struct null_net_header)), 
		len + sizeof(nx_struct null_net_header));
		return SUCCESS;
	}

	return call MacAMSend.send(addr, msg, len + 
		sizeof(nx_struct null_net_header));
}

command error_t NetworkAMSend.cancel(message_t* msg) {
	return call MacAMSend.cancel(msg);
}

command uint8_t NetworkAMSend.maxPayloadLength() {
	return (call MacAMSend.maxPayloadLength() - 
		sizeof(nx_struct null_net_header));
}

command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr = (uint8_t*) call MacAMSend.getPayload(msg, 
				len + sizeof(nx_struct null_net_header));
	return (void*) (ptr + sizeof(nx_struct null_net_header));
}

event void MacAMSend.sendDone(message_t *msg, error_t error) {
	signal NetworkAMSend.sendDone(msg, error);
}

event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	return signal NetworkReceive.receive(msg, 
			ptr + sizeof(nx_struct null_net_header), 
			len - sizeof(nx_struct null_net_header));
}

event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return signal NetworkSnoop.receive(msg, payload, len);
}

command am_addr_t NetworkAMPacket.address() {
	return call MacAMPacket.address();
}

command am_addr_t NetworkAMPacket.destination(message_t* amsg) {
	return call MacAMPacket.destination(amsg);
}

command am_addr_t NetworkAMPacket.source(message_t* amsg) {
	return call MacAMPacket.source(amsg);
}

command void NetworkAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	return call MacAMPacket.setDestination(amsg, addr);
}

command void NetworkAMPacket.setSource(message_t* amsg, am_addr_t addr) {
	return call MacAMPacket.setSource(amsg, addr);
}

command bool NetworkAMPacket.isForMe(message_t* amsg) {
	return call MacAMPacket.isForMe(amsg);
}

command am_id_t NetworkAMPacket.type(message_t* amsg) {
	return call MacAMPacket.type(amsg);
}

command void NetworkAMPacket.setType(message_t* amsg, am_id_t t) {
	return call MacAMPacket.setType(amsg, t);
}

command am_group_t NetworkAMPacket.group(message_t* amsg) {
	return call MacAMPacket.group(amsg);
}

command void NetworkAMPacket.setGroup(message_t* amsg, am_group_t grp) {
	return call MacAMPacket.setGroup(amsg, grp);
}

command am_group_t NetworkAMPacket.localGroup() {
	return call MacAMPacket.localGroup();
}

command void NetworkPacket.clear(message_t* msg) {
	return call MacPacket.clear(msg);
}

command uint8_t NetworkPacket.payloadLength(message_t* msg) {
	return call MacPacket.payloadLength(msg);
}

command void NetworkPacket.setPayloadLength(message_t* msg, uint8_t len) {
	return call MacPacket.setPayloadLength(msg, len);
}

command uint8_t NetworkPacket.maxPayloadLength() {
	return call MacPacket.maxPayloadLength();
}

command void* NetworkPacket.getPayload(message_t* msg, uint8_t len) {
	return call MacPacket.getPayload(msg, len);
}

async command error_t NetworkPacketAcknowledgements.requestAck( message_t* msg ) {
	return call MacPacketAcknowledgements.requestAck(msg);
}

async command error_t NetworkPacketAcknowledgements.noAck( message_t* msg ) {
	return call MacPacketAcknowledgements.noAck(msg);
}

async command bool NetworkPacketAcknowledgements.wasAcked(message_t* msg) {
	return call MacPacketAcknowledgements.wasAcked(msg);
}

event void MacStatus.status(uint8_t layer, uint8_t status_flag) {
}

event void nullNetParams.receive_status(uint16_t status_flag) {
}

}
