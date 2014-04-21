#include <Fennec.h>

module cc2420xP {
provides interface SplitControl;

uses interface cc2420xParams;
uses interface StdControl as AMQueueControl;
uses interface SplitControl as SubSplitControl;
uses interface SystemLowPowerListening;
uses interface LowPowerListening;

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
	call LowPowerListening.setLocalWakeupInterval(0);
	if (error == SUCCESS) {
		call AMQueueControl.stop();
	}
	return signal SplitControl.stopDone(error);
}


}
