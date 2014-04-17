#include <Fennec.h>

module cc2420xP {
provides interface SplitControl;

uses interface cc2420xParams;
uses interface StdControl as AMQueueControl;
uses interface SplitControl as SubSplitControl;
uses interface SystemLowPowerListening;
uses interface LowPowerListening;

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
	if (error == SUCCESS) {
		call AMQueueControl.start();
        	call SystemLowPowerListening.setDefaultRemoteWakeupInterval(call cc2420xParams.get_sleepInterval());
	        call SystemLowPowerListening.setDelayAfterReceive(call cc2420xParams.get_sleepDelay());
        	call LowPowerListening.setLocalWakeupInterval(call cc2420xParams.get_sleepInterval());
	}
	return signal SplitControl.startDone(error);
}

event void SubSplitControl.stopDone(error_t error) {
/*
	if (call RadioResource.isOwner()) {
		call RadioResource.release();
	}
*/
	call LowPowerListening.setLocalWakeupInterval(0);
	if (error == SUCCESS) {
		call AMQueueControl.stop();
	}
	return signal SplitControl.stopDone(error);
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
