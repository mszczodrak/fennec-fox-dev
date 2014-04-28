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
  * Fennec Fox tossim adaptation
  *
  * @author: Marcin K Szczodrak
  */


#include <Fennec.h>

module tossimP {
provides interface SplitControl;
provides interface RadioChannel;

provides interface AMSend[process_t process_id];
provides interface Receive[process_t process_id];
provides interface Receive as Snoop[process_t process_id];

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

uses interface tossimParams;
uses interface StdControl as AMQueueControl;
uses interface SplitControl as SubSplitControl;
uses interface SystemLowPowerListening;
provides interface LowPowerListening;

uses interface AMSend as SubAMSend[process_t process_id];
uses interface AMPacket;
uses interface Receive as SubReceive[process_t process_id];
uses interface Receive as SubSnoop[process_t process_id];


/*
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
*/

uses interface CC2420Packet;
uses interface CC2420Config;

}

implementation {
	
command error_t SplitControl.start() {
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {
	return call SubSplitControl.stop();
}


task void setChannel() {
	if (call RadioChannel.getChannel() == call tossimParams.get_channel()) {
		return;
	}

	if (call RadioChannel.setChannel(call tossimParams.get_channel()) != SUCCESS) {
		post setChannel();
	}
}


event void SubSplitControl.startDone(error_t error) {
	if (error == SUCCESS) {
		call AMQueueControl.start();
        	call SystemLowPowerListening.setDefaultRemoteWakeupInterval(call tossimParams.get_sleepInterval());
	        call SystemLowPowerListening.setDelayAfterReceive(call tossimParams.get_sleepDelay());
        	//call LowPowerListening.setLocalWakeupInterval(call tossimParams.get_sleepInterval());
	}

	post setChannel();

	return signal SplitControl.startDone(error);
}

event void SubSplitControl.stopDone(error_t error) {
        //call LowPowerListening.setLocalWakeupInterval(0);
	if (error == SUCCESS) {
		call AMQueueControl.stop();
	}
	return signal SplitControl.stopDone(error);
}

command error_t AMSend.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len) {
	//call LowPowerListening.setRemoteWakeupInterval(msg, call tossimParams.get_sleepInterval());
	call PacketTransmitPower.set(msg, call tossimParams.get_power());
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

task void setChannelDone() {
	signal RadioChannel.setChannelDone();
}

command error_t RadioChannel.setChannel(uint8_t channel) {
	call CC2420Config.setChannel( channel );
	post setChannelDone();
	return SUCCESS;
}

command uint8_t RadioChannel.getChannel() {
	return call CC2420Config.getChannel();
}

async command bool PacketLinkQuality.isSet(message_t* msg) {
	return TRUE;
}

async command uint8_t PacketLinkQuality.get(message_t* msg) {
	return call CC2420Packet.getLqi(msg);
}

async command void PacketLinkQuality.clear(message_t* msg) {

}

async command void PacketLinkQuality.set(message_t* msg, uint8_t value) {

}

async command bool PacketTransmitPower.isSet(message_t* msg) {
	return TRUE;
}

async command uint8_t PacketTransmitPower.get(message_t* msg) {
	return call CC2420Packet.getPower(msg);

}

async command void PacketTransmitPower.clear(message_t* msg) {

}

async command void PacketTransmitPower.set(message_t* msg, uint8_t value) {
	return call CC2420Packet.setPower(msg, value);
}

async command bool PacketRSSI.isSet(message_t* msg) {
	return TRUE;
}

async command uint8_t PacketRSSI.get(message_t* msg) {
	return (uint8_t) call CC2420Packet.getRssi(msg);
}

async command void PacketRSSI.clear(message_t* msg) {

}

async command void PacketRSSI.set(message_t* msg, uint8_t value) {

}



/*
async command bool PacketTimeStampRadio.isValid(message_t* msg) {
//	return call TimeStampFlag.get(msg);
}

async command uint32_t PacketTimeStampRadio.timestamp(message_t* msg) {
//	return getMeta(msg)->timestamp;
}

async command void PacketTimeStampRadio.clear(message_t* msg) {
//	call TimeStampFlag.clear(msg);
}

async command void PacketTimeStampRadio.set(message_t* msg, uint32_t value) {
//	call TimeStampFlag.set(msg);
//	getMeta(msg)->timestamp = value;
}
*/


event void CC2420Config.syncDone(error_t error) {}


default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
	return msg;
}

default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len) {
	return msg;
}

default event void AMSend.sendDone[uint8_t id](message_t* msg, error_t err) {
}

command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) {}

command uint16_t LowPowerListening.getLocalWakeupInterval() {
	return 0;
}

command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) {}

command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
	return 0;
}

}
