#include <Fennec.h>

module cc2420P {
provides interface SplitControl;
provides interface RadioChannel;

uses interface cc2420Params;
uses interface StdControl as AMQueueControl;
uses interface SplitControl as SubSplitControl;
uses interface Resource as RadioResource;
uses interface SystemLowPowerListening;
uses interface LowPowerListening;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

/*
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
*/

uses interface CC2420Packet;

}

implementation {
	
command error_t SplitControl.start() {
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {
	return call SubSplitControl.stop();
}

event void SubSplitControl.startDone(error_t error) {
	if (error == SUCCESS) {
		call AMQueueControl.start();
        	call SystemLowPowerListening.setDefaultRemoteWakeupInterval(call cc2420Params.get_sleepInterval());
	        call SystemLowPowerListening.setDelayAfterReceive(call cc2420Params.get_sleepDelay());
        	call LowPowerListening.setLocalWakeupInterval(call cc2420Params.get_sleepInterval());
	}
	return signal SplitControl.startDone(error);
}

event void SubSplitControl.stopDone(error_t error) {
	if (call RadioResource.isOwner()) {
		call RadioResource.release();
	}
        call LowPowerListening.setLocalWakeupInterval(0);
	if (error == SUCCESS) {
		call AMQueueControl.stop();
	}
	return signal SplitControl.stopDone(error);
}

command error_t RadioChannel.setChannel(uint8_t channel) {

}

event void RadioResource.granted() {

}

//event void setChannelDone() {

//}

command uint8_t RadioChannel.getChannel() {
	return 0;
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



}
