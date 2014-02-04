/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox empty network driver
  *
  * @author: Marcin K Szczodrak
  */


#include <Fennec.h>
#include "nullNet.h"

generic module nullNetP() {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface nullNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
}

implementation {

command error_t SplitControl.start() {
	dbg("Network", "nullNetP SplitControl.start()");
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Network", "nullNetP SplitControl.stop()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t NetworkAMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("Network", "nullNetP NetworkAMSend.send(%d, 0x%1x, %d )", addr, msg, len);

	if ((addr == TOS_NODE_ID)) {
		dbg("Network", "nullNet NetworkAMSend.sendDone(0x%1x, %d )", msg, SUCCESS);
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
	dbg("Network", "nullNetP NetworkAMSend.cancel(0x%1x)", msg);
	return call MacAMSend.cancel(msg);
}

command uint8_t NetworkAMSend.maxPayloadLength() {
	dbg("Network", "nullNetP NetworkAMSend.maxPayloadLength()");
	return (call MacAMSend.maxPayloadLength() - 
		sizeof(nx_struct null_net_header));
}

command void* NetworkAMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("Network", "nullNetP NetworkAMSend.getpayload(0x%1x, %d )", msg, len);
	ptr = (uint8_t*) call MacAMSend.getPayload(msg, 
				len + sizeof(nx_struct null_net_header));
	return (void*) (ptr + sizeof(nx_struct null_net_header));
}

event void MacAMSend.sendDone(message_t *msg, error_t error) {
	dbg("Network", "nullNetP NetworkAMSend.sendDone(0x%1x, %d )", msg, error);
	signal NetworkAMSend.sendDone(msg, error);
}

event message_t* MacReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "nullNetP NetworkReceive.receive(0x%1x, 0x%1x, %d )", msg, 
			ptr + sizeof(nx_struct null_net_header), 
			len - sizeof(nx_struct null_net_header));
	return signal NetworkReceive.receive(msg, 
			ptr + sizeof(nx_struct null_net_header), 
			len - sizeof(nx_struct null_net_header));
}

event message_t* MacSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("Network", "nullNetP NetworkSnoop.receive(0x%1x, 0x%1x, %d )", msg, 
			ptr + sizeof(nx_struct null_net_header), 
			len - sizeof(nx_struct null_net_header));
	return signal NetworkSnoop.receive(msg, 
			ptr + sizeof(nx_struct null_net_header), 
			len - sizeof(nx_struct null_net_header));
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

}
