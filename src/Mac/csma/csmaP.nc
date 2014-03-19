#include <Fennec.h>

generic module csmaP(process_t process) {
uses interface csmaParams;
uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;
uses interface SlottedCollisionConfig;
uses interface LowPowerListeningConfig;
}

implementation {

task void hello() {

}


}
