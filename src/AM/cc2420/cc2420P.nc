#include <Fennec.h>

module cc2420P {
provides interface SplitControl;
provides interface RadioChannel;

uses interface cc2420Params;
uses interface SplitControl as SubSplitControl;
uses interface Resource as RadioResource;

/*
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;
*/

}

implementation {
	
command error_t SplitControl.start() {
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {
	return call SubSplitControl.stop();
}

event void SubSplitControl.startDone(error_t error) {
	return signal SplitControl.startDone(error);
}

event void SubSplitControl.stopDone(error_t error) {
	if (call RadioResource.isOwner()) {
		call RadioResource.release();
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
