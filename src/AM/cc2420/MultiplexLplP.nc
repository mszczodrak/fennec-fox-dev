module MultiplexLplP {
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

command error_t SplitControl.start() {
	if (useLpl) {

	} else {
		return call DummySplitControl.start();
	}
}

command error_t SplitControl.stop() {
	if (useLpl) {

	} else {
		return call DummySplitControl.stop();
	}
}

command error_t Send.send(message_t *msg, uint8_t len) {
	if (useLpl) {

	} else {
		return call DummySend.send(msg, len);
	}
}

command uint8_t Send.maxPayloadLength() {
	if (useLpl) {

	} else {
		return call DummySend.maxPayloadLength();
	}
}

command void *Send.getPayload(message_t* msg, uint8_t len) {
	if (useLpl) {

	} else {
		return call DummySend.getPayload(msg, len);
	}
}

command error_t Send.cancel(message_t *msg) {
	if (useLpl) {

	} else {
		return call DummySend.cancel(msg);
	}
}


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

/*
	Sub Events 
*/

event void SubSend.sendDone(message_t* msg, error_t error) {
	if (useLpl) {

	} else {
		return signal DummySubSend.sendDone(msg, error);
	}
}

event message_t *SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
	if (useLpl) {

	} else {
		return signal DummySubReceive.receive(msg, payload, len);
	}
}

/*
	Dummy Commands
*/

command error_t DummySubControl.start() {
	return call SubControl.start();
}

command error_t DummySubControl.stop() {
	return call SubControl.stop();
}


command error_t DummySubSend.send(message_t *msg, uint8_t len) {
	return call SubSend.send(msg, len);
}

command uint8_t DummySubSend.maxPayloadLength() {
	return call SubSend.maxPayloadLength();
}

command void *DummySubSend.getPayload(message_t* msg, uint8_t len) {
	return call SubSend.getPayload(msg, len);
}

command error_t DummySubSend.cancel(message_t *msg) {
	return call SubSend.cancel(msg);
}




/* Dummy Events */

event void DummySplitControl.startDone(error_t error) {
	return signal SplitControl.startDone(error);
}

event void DummySplitControl.stopDone(error_t error) {
	return signal SplitControl.stopDone(error);
}




event void DummySend.sendDone(message_t* msg, error_t error) {
	return signal Send.sendDone(msg, error);
}


event message_t *DummyReceive.receive(message_t* msg, void* payload, uint8_t len) {
	return signal Receive.receive(msg, payload, len);
}


}
