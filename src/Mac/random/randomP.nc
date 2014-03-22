#include <Fennec.h>

generic module randomP(process_t process) {
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

}

implementation {

task void hello() {

}


}
