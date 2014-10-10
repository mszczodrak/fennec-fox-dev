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
  * Fennec Fox generic UART Bridge application module
  *
  * @author: Marcin K Szczodrak
  */

#include <Fennec.h>
#include "PrintfBridge.h"

generic module PrintfBridgeP(process_t process) {
provides interface SplitControl;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;

uses interface Leds;

/* Serial Queue */
uses interface Queue<msg_queue_t> as SerialQueue;

}

implementation {

message_t packet;
void *serial_data;

/*
LED 0 (red) reports any deadly errors.
LED 1 (green) reports serial/network warnings.
LED 2 (blue) report actvity
*/

task void send_serial_message() {
	uint8_t i;
	msg_queue_t sm;

	/* Check if there is anything to send */
		if (call SerialQueue.empty()) {
		return;
	}

	/* Get the next message to send over the serial */
	sm = call SerialQueue.head();

	for (i = 0 ; i < sm.len ; i++) {
		printf("0x%1x ", sm.data[i]);
	}
	printf("\n");
	printfflush();

	call SerialQueue.dequeue();
}


command error_t SplitControl.start() {
	dbg("Application", "PrintfBridge SplitControl.start()");
	signal SplitControl.startDone(SUCCESS);
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Application", "PrintfBridge SplitControl.start()");
	signal SplitControl.stopDone(SUCCESS);
	return SUCCESS;
}

event void SubAMSend.sendDone(message_t *msg, error_t error) {
}

event message_t* SubReceive.receive(message_t *msg, void* payload, uint8_t len) {
	msg_queue_t sm;

	/* Check if there is space to save this message */
	if (call SerialQueue.full()) {
		return msg;
	}

	sm.dest = BROADCAST;
	sm.len = len;
	memcpy(&sm.data, payload, len);

	call SerialQueue.enqueue(sm);

	post send_serial_message();

	return msg;
}

event message_t* SubSnoop.receive(message_t *msg, void* payload, uint8_t len) {
	return msg;
}



}
