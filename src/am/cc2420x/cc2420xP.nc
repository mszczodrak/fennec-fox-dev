#include <Fennec.h>

module cc2420xP {
provides interface SplitControl;

uses interface cc2420xParams;
uses interface StdControl as AMQueueControl;
uses interface SplitControl as SubSplitControl;
uses interface SystemLowPowerListening;
uses interface LowPowerListening;

provides interface AMSend[process_t process_id];
uses interface AMSend as SubAMSend[process_t process_id];

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface RadioChannel;

}

implementation {
	
command error_t SplitControl.start() {
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {
	return call SubSplitControl.stop();
}

task void setChannel() {
	if (call RadioChannel.getChannel() == call cc2420xParams.get_channel()) {
		return;
	}

	if (call RadioChannel.setChannel(call cc2420xParams.get_channel()) != SUCCESS) {
		post setChannel();
	}
}

event void SubSplitControl.startDone(error_t error) {
	if (error == SUCCESS) {
		call AMQueueControl.start();
        	call SystemLowPowerListening.setDefaultRemoteWakeupInterval(call cc2420xParams.get_sleepInterval());
	        call SystemLowPowerListening.setDelayAfterReceive(call cc2420xParams.get_sleepDelay());
        	call LowPowerListening.setLocalWakeupInterval(call cc2420xParams.get_sleepInterval());
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
	//call LowPowerListening.setRemoteWakeupInterval(msg, call cc2420xParams.get_sleepInterval());
	call PacketTransmitPower.set(msg, call cc2420xParams.get_power());
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

event void RadioChannel.setChannelDone() {}


default event void AMSend.sendDone[am_id_t id](message_t* msg, error_t error) {}



}
