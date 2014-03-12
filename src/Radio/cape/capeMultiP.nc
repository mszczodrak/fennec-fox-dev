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
  * Cape Fox radio driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 12/28/2013
  */

module capeMultiP {
provides interface SplitControl[uint8_t process_id];
provides interface TossimPacketModel as Packet[uint8_t process_id];

uses interface TossimPacketModel as SubPacket;
uses interface SplitControl as SubSplitControl;

}

implementation {

uint8_t proc_id;

command error_t SplitControl.start[uint8_t process_id]() {
	proc_id = process_id;
	return call SubSplitControl.start();
}

command error_t SplitControl.stop[uint8_t process_id]() {
	proc_id = process_id;
	return call SubSplitControl.stop();
}

event void SubSplitControl.startDone(error_t err) {
	signal SplitControl.startDone[proc_id](err);
}

event void SubSplitControl.stopDone(error_t err) {
	signal SplitControl.stopDone[proc_id](err);
}

command error_t Packet.send[uint8_t process_id](int dest, message_t* msg, uint8_t len) {
	cape_hdr_t* header = (cape_hdr_t*)msg;
	header->destpan = process_id;
	return call SubPacket.send(dest, msg, len);
}

command error_t Packet.cancel[uint8_t process_id](message_t* msg) {
	return call SubPacket.cancel(msg);
}

event void SubPacket.sendDone(message_t *msg, error_t error) {
	cape_hdr_t* header = (cape_hdr_t*)msg;
	msg->conf = header->destpan;
	signal Packet.sendDone[header->destpan](msg, error);
}

event bool SubPacket.shouldAck(message_t *msg) {
	cape_hdr_t* header = (cape_hdr_t*)msg;
	msg->conf = header->destpan;
	return signal Packet.shouldAck[header->destpan](msg);
}

event void SubPacket.receive(message_t *msg) {
	cape_hdr_t* header = (cape_hdr_t*)msg;
	msg->conf = header->destpan;
	return signal Packet.receive[header->destpan](msg);
}

default event void SplitControl.startDone[uint8_t process_id](error_t err) {
}

default event void SplitControl.stopDone[uint8_t process_id](error_t err) {
}

default event void Packet.sendDone[uint8_t process_id](message_t *msg, error_t err) {
}

default event bool Packet.shouldAck[uint8_t process_id](message_t *msg) {
	return FALSE;
}

default event void Packet.receive[uint8_t process_id](message_t *msg) {
}

}
