#include <Fennec.h>

generic module random_lplP(process_t process) {

provides interface SplitControl;

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


}

implementation {

command error_t SplitControl.start() {

	call LowPowerListening.setLocalWakeupInterval(call random_lplParams.get_sleepInterval());
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



}
