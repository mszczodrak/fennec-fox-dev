module MultipleLplP {
provides interface LowPowerListening;
provides interface Send;
provides interface Receive;
provides interface SplitControl;
provides interface State as SendState;

uses interface Send as SubSend;
uses interface Receive as SubReceive;
uses interface SplitControl as SubControl;


/* wire to DummyLplC */
uses interface LowPowerListening as DummyLowPowerListening;
uses interface Send as DummySend;
uses interface Receive as DummyReceive;
uses interface SplitControl as DummySplitControl;
uses interface State as DummySendState;

provides interface Send as DummySubSend;
provides interface Receive as DummySubReceive;
provides interface SplitControl as DummySubControl;

}

implementation {

bool useLpl = FALSE;

command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) {
	if (useLpl) {

	} else {
		return call DummyLowPowerListening.setLocalWakeupInterval(intervalMs);
	}
}

command uint16_t LowPowerListening.getLocalWakeupInterval() {
	if (useLpl) {

	} else {
		return call DummyLowPowerListening.getLocalWakeupInterval();
	}
}

command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) {
	if (useLpl) {

	} else {
		return call DummyLowPowerListening.setRemoteWakeupInterval(msg, intervalMs);
	}
}

command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
	if (useLpl) {

	} else {
		return call DummyLowPowerListening.getRemoteWakeupInterval(msg);
	}
}







}



