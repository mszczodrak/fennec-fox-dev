#include <Fennec.h>

generic module random_lplP(process_t process) {

provides interface SplitControl;
provides interface BareSend;

uses interface random_lplParams;
uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;
uses interface SlottedCollisionConfig;
uses interface LowPowerListeningConfig;
uses interface DummyConfig;
uses interface LocalTime<TRadio> as LocalTimeRadio;
uses interface LowPowerListening;
uses interface SplitControl as SubSplitControl;
uses interface BareSend as SubSend;

}

implementation {

command error_t SplitControl.start() {
//	call LowPowerListening.setLocalWakeupInterval(call random_lplParams.get_sleepInterval());
	return call SubSplitControl.start();
}

command error_t SplitControl.stop() {

	return call SubSplitControl.stop();
}

event void SubSplitControl.startDone(error_t error) {
	signal SplitControl.startDone(error);
}

event void SubSplitControl.stopDone(error_t error) {
	signal SplitControl.stopDone(error);
}

command error_t BareSend.send(message_t* msg) {
//	call LowPowerListening.setRemoteWakeupInterval(msg, 
//		call random_lplParams.get_sleepInterval());
	return call SubSend.send(msg);
}

command error_t BareSend.cancel(message_t* msg) {
	return call SubSend.cancel(msg);
}

event void SubSend.sendDone(message_t* msg, error_t error) {
	signal BareSend.sendDone(msg, error);
}

}
