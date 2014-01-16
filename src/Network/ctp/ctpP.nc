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
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox CTP Network Protocol adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/18/2010
  */

#include <Fennec.h>
#include "ctp.h"

generic module ctpP() {
provides interface SplitControl;

uses interface ctpParams;
uses interface Leds;

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

command error_t SplitControl.start() {
	dbg("Network", "ctpP SplitControl.start()");
	call RoutingControl.start();
	dbg("Network", "ctpP SplitControl.start() - root: %d", call ctpParams.get_root());
	if (TOS_NODE_ID == call ctpParams.get_root()) {
		call RootControl.setRoot();
	}

	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Network", "ctpP SplitControl.stop()");
	call RoutingControl.stop();
	signal SplitControl.stopDone(SUCCESS);
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
