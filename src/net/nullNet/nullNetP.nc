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
  * Fennec Fox nullNet network module
  *
  * @author: Marcin K Szczodrak
  */
#include <Fennec.h>
#include "nullNet.h"

generic module nullNetP(process_t process) {
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;
provides interface AMPacket as AMPacket;
provides interface Packet as Packet;
provides interface PacketAcknowledgements as PacketAcknowledgements;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;
}

implementation {

command error_t SplitControl.start() {
	dbg("", "[%d] nullNet SplitControl.start()", process);
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("", "[%d] nullNet SplitControl.stop()", process);
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

command error_t AMSend.send(am_addr_t addr, message_t* msg, uint8_t len) {
	dbg("", "[%d] nullNet AMSend.send(%d, 0x%1x, %d )",
		process, addr, msg, len);

	if ((addr == TOS_NODE_ID)) {
		dbg("", "[%d] nullNet AMSend.sendDone(0x%1x, %d )", process, msg, SUCCESS);
		signal AMSend.sendDone(msg, SUCCESS);
		signal SubReceive.receive(msg, 
		call AMSend.getPayload(msg, len + 
				sizeof(nx_struct nullNet_header)), 
		len + sizeof(nx_struct nullNet_header));
		return SUCCESS;
	}

	if (addr != AM_BROADCAST_ADDR) {
		call PacketAcknowledgements.requestAck(msg);
	}

	return call SubAMSend.send(addr, msg, len + 
		sizeof(nx_struct nullNet_header));
}

command error_t AMSend.cancel(message_t* msg) {
	dbg("", "[%d] nullNet AMSend.cancel(0x%1x)", process, msg);
	return call SubAMSend.cancel(msg);
}

command uint8_t AMSend.maxPayloadLength() {
	dbg("", "[%d] nullNet AMSend.maxPayloadLength()", process);
	return (call SubAMSend.maxPayloadLength() - 
		sizeof(nx_struct nullNet_header));
}

command void* AMSend.getPayload(message_t* msg, uint8_t len) {
	uint8_t *ptr; 
	dbg("", "[%d] nullNet AMSend.getpayload(0x%1x, %d )", process, msg, len);
	ptr = (uint8_t*) call SubAMSend.getPayload(msg, 
				len + sizeof(nx_struct nullNet_header));
	return (void*) (ptr + sizeof(nx_struct nullNet_header));
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
	dbg("", "[%d] nullNet AMSend.sendDone(0x%1x, %d )", process, msg, error);
	signal AMSend.sendDone(msg, error);
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("", "[%d] nullNet Receive.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct nullNet_header), 
			len - sizeof(nx_struct nullNet_header));
	return signal Receive.receive(msg, 
			ptr + sizeof(nx_struct nullNet_header), 
			len - sizeof(nx_struct nullNet_header));
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	uint8_t *ptr = (uint8_t*) payload;
	dbg("", "[%d] nullNet Snoop.receive(0x%1x, 0x%1x, %d )",
			process, msg, 
			ptr + sizeof(nx_struct nullNet_header), 
			len - sizeof(nx_struct nullNet_header));
	return signal Snoop.receive(msg, 
			ptr + sizeof(nx_struct nullNet_header), 
			len - sizeof(nx_struct nullNet_header));
}

command am_addr_t AMPacket.address() {
	return call SubAMPacket.address();
}

command am_addr_t AMPacket.destination(message_t* amsg) {
	return call SubAMPacket.destination(amsg);
}

command am_addr_t AMPacket.source(message_t* amsg) {
	return call SubAMPacket.source(amsg);
}

command void AMPacket.setDestination(message_t* amsg, am_addr_t addr) {
	return call SubAMPacket.setDestination(amsg, addr);
}

command void AMPacket.setSource(message_t* amsg, am_addr_t addr) {
	return call SubAMPacket.setSource(amsg, addr);
}

command bool AMPacket.isForMe(message_t* amsg) {
	return call SubAMPacket.isForMe(amsg);
}

command am_id_t AMPacket.type(message_t* amsg) {
	return call SubAMPacket.type(amsg);
}

command void AMPacket.setType(message_t* amsg, am_id_t t) {
	return call SubAMPacket.setType(amsg, t);
}

command am_group_t AMPacket.group(message_t* amsg) {
	return call SubAMPacket.group(amsg);
}

command void AMPacket.setGroup(message_t* amsg, am_group_t grp) {
	return call SubAMPacket.setGroup(amsg, grp);
}

command am_group_t AMPacket.localGroup() {
	return call SubAMPacket.localGroup();
}

command void Packet.clear(message_t* msg) {
	return call SubPacket.clear(msg);
}

command uint8_t Packet.payloadLength(message_t* msg) {
	return call SubPacket.payloadLength(msg);
}

command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
	return call SubPacket.setPayloadLength(msg, len);
}

command uint8_t Packet.maxPayloadLength() {
	return call SubPacket.maxPayloadLength();
}

command void* Packet.getPayload(message_t* msg, uint8_t len) {
	return call SubPacket.getPayload(msg, len);
}

async command error_t PacketAcknowledgements.requestAck( message_t* msg ) {
	return call SubPacketAcknowledgements.requestAck(msg);
}

async command error_t PacketAcknowledgements.noAck( message_t* msg ) {
	return call SubPacketAcknowledgements.noAck(msg);
}

async command bool PacketAcknowledgements.wasAcked(message_t* msg) {
	return call SubPacketAcknowledgements.wasAcked(msg);
}

event void RadioChannel.setChannelDone() {
}

event void Param.updated(uint8_t var_id, bool conflict) {

}


}
