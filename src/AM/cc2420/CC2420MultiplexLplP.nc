module CC2420MultiplexLplP {
provides interface LowPowerListening;
provides interface Send;
provides interface Receive;
provides interface SplitControl;
provides interface State as SendState;

uses interface Send as SubSend;
uses interface Receive as SubReceive;
uses interface SplitControl as SubControl;

uses interface cc2420Params;
uses interface SystemLowPowerListening;

/* wire to DummyLplC */
uses interface LowPowerListening as DummyLowPowerListening;
uses interface Send as DummySend;
uses interface Receive as DummyReceive;
uses interface SplitControl as DummySplitControl;
uses interface State as DummySendState;

provides interface Send as DummySubSend;
provides interface Receive as DummySubReceive;
provides interface SplitControl as DummySubControl;

/* wire to DefaultLplC */
uses interface LowPowerListening as DefaultLowPowerListening;
uses interface Send as DefaultSend;
uses interface Receive as DefaultReceive;
uses interface SplitControl as DefaultSplitControl;
uses interface State as DefaultSendState;

provides interface Send as DefaultSubSend;
provides interface Receive as DefaultSubReceive;
provides interface SplitControl as DefaultSubControl;

}

implementation {

norace uint16_t sleepInterval = 0;

command error_t SplitControl.start() {
	sleepInterval = call cc2420Params.get_sleepInterval();

	call SystemLowPowerListening.setDefaultRemoteWakeupInterval(sleepInterval);
	call SystemLowPowerListening.setDelayAfterReceive(call cc2420Params.get_sleepDelay());

	call LowPowerListening.setLocalWakeupInterval(sleepInterval);

	if (sleepInterval) {
		return call DefaultSplitControl.start();
	} else {
		return call DummySplitControl.start();
	}
}

command error_t SplitControl.stop() {
	if (sleepInterval) {
		return call DefaultSplitControl.stop();
	} else {
		return call DummySplitControl.stop();
	}
}

command error_t Send.send(message_t *msg, uint8_t len) {
	if (sleepInterval) {
		call LowPowerListening.setRemoteWakeupInterval(msg, sleepInterval);
		return call DefaultSend.send(msg, len);
	} else {
		return call DummySend.send(msg, len);
	}
}

command uint8_t Send.maxPayloadLength() {
	if (sleepInterval) {
		return call DefaultSend.maxPayloadLength();
	} else {
		return call DummySend.maxPayloadLength();
	}
}

command void *Send.getPayload(message_t* msg, uint8_t len) {
	if (sleepInterval) {
		return call DefaultSend.getPayload(msg, len);
	} else {
		return call DummySend.getPayload(msg, len);
	}
}

command error_t Send.cancel(message_t *msg) {
	if (sleepInterval) {
		return call DefaultSend.cancel(msg);
	} else {
		return call DummySend.cancel(msg);
	}
}

async command error_t SendState.requestState(uint8_t reqSendState) {
	if (sleepInterval) {
		return call DefaultSendState.requestState(reqSendState);
	} else {
		return call DummySendState.requestState(reqSendState);
	}
}

async command void SendState.forceState(uint8_t reqSendState) {
	if (sleepInterval) {
		return call DefaultSendState.forceState(reqSendState);
	} else {
		return call DummySendState.forceState(reqSendState);
	}
}

async command void SendState.toIdle() {
	if (sleepInterval) {
		return call DefaultSendState.toIdle();
	} else {
		return call DummySendState.toIdle();
	}
}

async command bool SendState.isIdle() {
	if (sleepInterval) {
		return call DefaultSendState.isIdle();
	} else {
		return call DummySendState.isIdle();
	}
}

async command bool SendState.isState(uint8_t myState) {
	if (sleepInterval) {
		return call DefaultSendState.isState(myState);
	} else {
		return call DummySendState.isState(myState);
	}
}

async command uint8_t SendState.getState() {
	if (sleepInterval) {
		return call DefaultSendState.getState();
	} else {
		return call DummySendState.getState();
	}
}

command void LowPowerListening.setLocalWakeupInterval(uint16_t intervalMs) {
	if (sleepInterval) {
		return call DefaultLowPowerListening.setLocalWakeupInterval(intervalMs);
	} else {
		return call DummyLowPowerListening.setLocalWakeupInterval(intervalMs);
	}
}

command uint16_t LowPowerListening.getLocalWakeupInterval() {
	if (sleepInterval) {
		return call DefaultLowPowerListening.getLocalWakeupInterval();
	} else {
		return call DummyLowPowerListening.getLocalWakeupInterval();
	}
}

command void LowPowerListening.setRemoteWakeupInterval(message_t *msg, uint16_t intervalMs) {
	if (sleepInterval) {
		return call DefaultLowPowerListening.setRemoteWakeupInterval(msg, intervalMs);
	} else {
		return call DummyLowPowerListening.setRemoteWakeupInterval(msg, intervalMs);
	}
}

command uint16_t LowPowerListening.getRemoteWakeupInterval(message_t *msg) {
	if (sleepInterval) {
		return call DefaultLowPowerListening.getRemoteWakeupInterval(msg);
	} else {
		return call DummyLowPowerListening.getRemoteWakeupInterval(msg);
	}
}

/*
	Sub Events 
*/

event void SubSend.sendDone(message_t* msg, error_t error) {
	if (sleepInterval) {
		return signal DefaultSubSend.sendDone(msg, error);
	} else {
		return signal DummySubSend.sendDone(msg, error);
	}
}

event message_t *SubReceive.receive(message_t* msg, void* payload, uint8_t len) {
	if (sleepInterval) {
		return signal DefaultSubReceive.receive(msg, payload, len);
	} else {
		return signal DummySubReceive.receive(msg, payload, len);
	}
}

event void SubControl.startDone(error_t error) {
	if (sleepInterval) {
		return signal DefaultSubControl.startDone(error);
	} else {
		return signal DummySubControl.startDone(error);
	}
}

event void SubControl.stopDone(error_t error) {
	if (sleepInterval) {
		return signal DefaultSubControl.stopDone(error);
	} else {
		return signal DummySubControl.stopDone(error);
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

/*
	Dummy Events
*/

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

/*
	Default Commands
*/

command error_t DefaultSubControl.start() {
	return call SubControl.start();
}

command error_t DefaultSubControl.stop() {
	return call SubControl.stop();
}


command error_t DefaultSubSend.send(message_t *msg, uint8_t len) {
	return call SubSend.send(msg, len);
}

command uint8_t DefaultSubSend.maxPayloadLength() {
	return call SubSend.maxPayloadLength();
}

command void *DefaultSubSend.getPayload(message_t* msg, uint8_t len) {
	return call SubSend.getPayload(msg, len);
}

command error_t DefaultSubSend.cancel(message_t *msg) {
	return call SubSend.cancel(msg);
}


/*
	Default Events
*/

event void DefaultSplitControl.startDone(error_t error) {
	return signal SplitControl.startDone(error);
}

event void DefaultSplitControl.stopDone(error_t error) {
	return signal SplitControl.stopDone(error);
}

event void DefaultSend.sendDone(message_t* msg, error_t error) {
	return signal Send.sendDone(msg, error);
}

event message_t *DefaultReceive.receive(message_t* msg, void* payload, uint8_t len) {
	return signal Receive.receive(msg, payload, len);
}


}
