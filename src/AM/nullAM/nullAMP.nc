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
  * Fennec Fox nullAM MAC module
  *
  * @author: Marcin K Szczodrak
  */
#include <Fennec.h>
#include "nullAM.h"

module nullAMP {
provides interface SplitControl;
provides interface AMSend as MacAMSend[process_t process_id];
provides interface Receive as MacReceive[process_t process_id];
provides interface Receive as MacSnoop[process_t process_id];
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface nullAMParams;
uses interface StdControl as AMQueueControl;

provides interface LowPowerListening;
provides interface RadioChannel;

}

implementation {

uint8_t channel = 26;
am_id_t n_id;
message_t *n_msg;


task void startDone() {
	signal SplitControl.startDone(SUCCESS);
}

task void stopDone() {
	signal SplitControl.stopDone(SUCCESS);
}

task void sendDone() {
	signal MacAMSend.sendDone[n_id](n_msg, SUCCESS);
}	

command error_t SplitControl.start() {
	post startDone();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	post startDone();
	return SUCCESS;
}

command error_t RadioChannel.setChannel(uint8_t ch) {
	channel = ch;
	return SUCCESS;
}

command uint8_t RadioChannel.getChannel() {
        return channel;
}

command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) {
}

command uint16_t LowPowerListening.getLocalWakeupInterval() {
	return 0;
}

command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) {
}

command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
	return 0;
}

command error_t MacAMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {

	n_msg = msg;
	n_id = id;

	if (len > call MacPacket.maxPayloadLength()) {
		return ESIZE;
	}

	post sendDone();
	return SUCCESS;
}


command error_t MacAMSend.cancel[am_id_t id](message_t* msg) {
	return SUCCESS;
}

command uint8_t MacAMSend.maxPayloadLength[am_id_t id]() {
	return call MacPacket.maxPayloadLength();
}

command void* MacAMSend.getPayload[am_id_t id](message_t* m, uint8_t len) {
	return call MacPacket.getPayload(m, len);
}

command am_addr_t MacAMPacket.address() {
	return TOS_NODE_ID;
}

command am_addr_t MacAMPacket.destination(message_t* amsg) {
	return 0;
}

command am_addr_t MacAMPacket.source(message_t* amsg) {
	return 0;
}

command void MacAMPacket.setDestination(message_t* amsg, am_addr_t addr) {
}

command void MacAMPacket.setSource(message_t* amsg, am_addr_t addr) {
}

command bool MacAMPacket.isForMe(message_t* amsg) {
	return TRUE;
}

command am_id_t MacAMPacket.type(message_t* amsg) {
	return n_id;
}

command void MacAMPacket.setType(message_t* amsg, am_id_t type) {
	n_id = type;
}

command am_group_t MacAMPacket.group(message_t* amsg) {
	return 0;
}

command void MacAMPacket.setGroup(message_t* amsg, am_group_t grp) {
}

command am_group_t MacAMPacket.localGroup() {
}

command void MacPacket.clear(message_t* msg) {
    memset(msg, 0x0, sizeof(message_t));
}

command uint8_t MacPacket.payloadLength(message_t* msg) {
	return 120;
}

command void MacPacket.setPayloadLength(message_t* msg, uint8_t len) {
}

command uint8_t MacPacket.maxPayloadLength() {
	return 120;
}

command void* MacPacket.getPayload(message_t* msg, uint8_t len) {
	return msg->data;
}

async command error_t MacPacketAcknowledgements.requestAck( message_t* p_msg ) {
	return SUCCESS;
}

async command error_t MacPacketAcknowledgements.noAck( message_t* p_msg ) {
	return SUCCESS;
}

async command bool MacPacketAcknowledgements.wasAcked( message_t* p_msg ) {
	return TRUE;
}

async command bool MacLinkPacketMetadata.highChannelQuality(message_t* msg) {
	return TRUE;
}

}
