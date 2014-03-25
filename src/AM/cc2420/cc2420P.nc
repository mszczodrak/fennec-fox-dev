#include <Fennec.h>

module cc2420P {
uses interface cc2420Params;

provides interface RadioChannel;

/*
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;
*/

}

implementation {
	
task void test() {

}


command error_t RadioChannel.setChannel(uint8_t channel) {

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
