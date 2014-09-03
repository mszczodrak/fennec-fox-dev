/*
 * Copyright (c) 2014, Columbia University.
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
  * Fennec Fox rf231 adaptation
  *
  * @author: Marcin K Szczodrak
  */


#include <Fennec.h>

module rf231P {
provides interface SplitControl;

provides interface AMSend[process_t process_id];
provides interface Receive[process_t process_id];
provides interface Receive as Snoop[process_t process_id];

uses interface Param;
uses interface StdControl as AMQueueControl;
uses interface SplitControl as SubSplitControl;
uses interface LowPowerListening;
uses interface PacketAcknowledgements;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface RadioChannel;

uses interface AMSend as SubAMSend[process_t process_id];
uses interface AMPacket;
uses interface Packet;
uses interface Receive as SubReceive[process_t process_id];
uses interface Receive as SubSnoop[process_t process_id];

}

implementation {

uint8_t channel;
uint8_t power;
uint16_t sleepInterval;
	
command error_t SplitControl.start() {
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {
	return call SubSplitControl.stop();
}

task void setChannel() {
	call Param.get(CHANNEL, &channel, sizeof(channel));
	if (call RadioChannel.getChannel() == channel) {
		return;
	}

	if (call RadioChannel.setChannel(channel) != SUCCESS) {
		post setChannel();
	}
}

event void SubSplitControl.startDone(error_t error) {
	call Param.get(SLEEPINTERVAL, &sleepInterval, sizeof(sleepInterval));

	if (error == SUCCESS) {
		call AMQueueControl.start();
        	call LowPowerListening.setLocalWakeupInterval(sleepInterval);
	}

	post setChannel();

	return signal SplitControl.startDone(error);
}

event void SubSplitControl.stopDone(error_t error) {
	call LowPowerListening.setLocalWakeupInterval(0);
	if (error == SUCCESS) {
		call AMQueueControl.stop();
	}
	return signal SplitControl.stopDone(error);
}

command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {
	call Param.get(POWER, &power, sizeof(power));
	call Param.get(SLEEPINTERVAL, &sleepInterval, sizeof(sleepInterval));

	call LowPowerListening.setRemoteWakeupInterval(msg, sleepInterval);
	call PacketTransmitPower.set(msg, power);
	return call SubAMSend.send[id](addr, msg, len);
}

event void SubAMSend.sendDone[am_id_t id](message_t* msg, error_t error) {
	signal AMSend.sendDone[id](msg, error);
}

command error_t AMSend.cancel[am_id_t id](message_t* msg) {
	return call SubAMSend.cancel[id](msg);
}

command uint8_t AMSend.maxPayloadLength[am_id_t id]() {
	return call SubAMSend.maxPayloadLength[id]();
}

command void* AMSend.getPayload[am_id_t id](message_t* msg, uint8_t len) {
	return call SubAMSend.getPayload[id](msg, len);
}

event message_t * SubReceive.receive[process_t id](message_t* msg, void* payload, uint8_t len) {
	if (!validProcessId(call AMPacket.type(msg))) {
		return msg;
	}
	return signal Receive.receive[id](msg, payload, len);
}

event message_t * SubSnoop.receive[process_t id](message_t* msg, void* payload, uint8_t len) {
	if (!validProcessId(call AMPacket.type(msg))) {
		return msg;
	}
	return signal Snoop.receive[id](msg, payload, len);
}


event void RadioChannel.setChannelDone() {}


default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
	return msg;
}

default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
	return msg;
}

default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t error) {}



}
