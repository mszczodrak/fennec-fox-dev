#include <Fennec.h>

generic module randomP(process_t process) {
provides interface SplitControl;

uses interface randomParams;
uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;
uses interface SlottedCollisionConfig;
uses interface LowPowerListeningConfig;
uses interface DummyConfig;
uses interface LocalTime<TRadio> as LocalTimeRadio;

uses interface SplitControl as SubSplitControl;
}

implementation {

command error_t SplitControl.start() {
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
