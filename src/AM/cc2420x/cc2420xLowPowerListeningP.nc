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

uses interface cc2420xParams;

/* wire to LowPowerListeningDummyC */
uses interface LowPowerListening as DummyLowPowerListening;
uses interface Send as DummySend;
uses interface Receive as DummyReceive;
uses interface SplitControl as DummySplitControl;
uses interface State as DummySendState;

provides interface Send as DummySubSend;
provides interface Receive as DummySubReceive;
provides interface SplitControl as DummySubControl;
provides interface RadioPacket as DummySubPacket;

/* wire to LowPowerListeningLayerC */
uses interface LowPowerListening as DefaultLowPowerListening;
uses interface Send as DefaultSend;
uses interface Receive as DefaultReceive;
uses interface SplitControl as DefaultSplitControl;
uses interface State as DefaultSendState;

provides interface Send as DefaultSubSend;
provides interface Receive as DefaultSubReceive;
provides interface SplitControl as DefaultSubControl;
provides interface RadioPacket as DefaultSubPacket;

}

implementation
{
uint16_t sleepInterval = 0;

command error_t SplitControl.start() {
	sleepInterval = call cc2420Params.get_sleepInterval();

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






}
