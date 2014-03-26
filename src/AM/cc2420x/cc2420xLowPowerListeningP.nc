generic module cc2420LowPowerListeningP() {
provides interface SplitControl;
provides interface BareSend as Send;
provides interface BareReceive as Receive;
provides interface RadioPacket;
provides interface LowPowerListening;

uses interface SplitControl as SubControl;
uses interface BareSend as SubSend;
uses interface BareReceive as SubReceive;
uses interface RadioPacket as SubPacket;

uses interface LowPowerListeningConfig;
uses interface PacketAcknowledgements;

uses interface cc2420xParams;

/* wire to LowPowerListeningDummyC */
uses interface LowPowerListening as DummyLowPowerListening;
uses interface BareSend as DummySend;
uses interface BareReceive as DummyReceive;
uses interface SplitControl as DummySplitControl;
uses interface RadioPacket as DummyRadioPacket;

provides interface BareSend as DummySubSend;
provides interface BareReceive as DummySubReceive;
provides interface SplitControl as DummySubControl;
provides interface RadioPacket as DummySubPacket;

/* wire to LowPowerListeningLayerC */
uses interface LowPowerListening as DefaultLowPowerListening;
uses interface BareSend as DefaultSend;
uses interface BareReceive as DefaultReceive;
uses interface SplitControl as DefaultSplitControl;
uses interface RadioPacket as DefaultRadioPacket;

provides interface BareSend as DefaultSubSend;
provides interface BareReceive as DefaultSubReceive;
provides interface SplitControl as DefaultSubControl;
provides interface RadioPacket as DefaultSubPacket;

}

implementation
{
uint16_t sleepInterval = 0;

command error_t SplitControl.start() {
	sleepInterval = call cc2420xParams.get_sleepInterval();

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

command error_t Send.send(message_t *msg) {
	if (sleepInterval) {
		call LowPowerListening.setRemoteWakeupInterval(msg, sleepInterval);
		return call DefaultSend.send(msg);
	} else {
		return call DummySend.send(msg);
	}
}

command error_t Send.cancel(message_t *msg) {
	if (sleepInterval) {
		return call DefaultSend.cancel(msg);
	} else {
		return call DummySend.cancel(msg);
	}
}

async command uint8_t RadioPacket.headerLength(message_t* msg) {
	if (sleepInterval) {
		return call DefaultRadioPacket.headerLength(msg);
	} else {
		return call DummyRadioPacket.headerLength(msg);
	}
}

async command uint8_t RadioPacket.payloadLength(message_t* msg) {
	if (sleepInterval) {
		return call DefaultRadioPacket.payloadLength(msg);
	} else {
		return call DummyRadioPacket.payloadLength(msg);
	}
}

async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length) {
	if (sleepInterval) {
		return call DefaultRadioPacket.setPayloadLength(msg, length);
	} else {
		return call DummyRadioPacket.setPayloadLength(msg, length);
	}
}

async command uint8_t RadioPacket.maxPayloadLength() {
	if (sleepInterval) {
		return call DefaultRadioPacket.maxPayloadLength();
	} else {
		return call DummyRadioPacket.maxPayloadLength();
	}
}

async command uint8_t RadioPacket.metadataLength(message_t* msg) {
	if (sleepInterval) {
		return call DefaultRadioPacket.metadataLength(msg);
	} else {
		return call DummyRadioPacket.metadataLength(msg);
	}
}

async command void RadioPacket.clear(message_t* msg) {
	if (sleepInterval) {
		return call DefaultRadioPacket.clear(msg);
	} else {
		return call DummyRadioPacket.clear(msg);
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


command error_t DummySubSend.send(message_t *msg) {
	return call SubSend.send(msg);
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


command error_t DefaultSubSend.send(message_t *msg) {
	return call SubSend.send(msg);
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
