#include <Fennec.h>

generic configuration SynchronizedDisseminateFinishC(process_t process) {
provides interface SplitControl;
provides interface AMSend;
provides interface Receive;
provides interface Receive as Snoop;
provides interface AMPacket;
provides interface Packet;
provides interface PacketAcknowledgements;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;
uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;
}

implementation {

components new SynchronizedDisseminateFinishP(process);
SplitControl = SynchronizedDisseminateFinishP;
Param = SynchronizedDisseminateFinishP;
AMSend = SynchronizedDisseminateFinishP.AMSend;
Receive = SynchronizedDisseminateFinishP.Receive;
Snoop = SynchronizedDisseminateFinishP.Snoop;
AMPacket = SynchronizedDisseminateFinishP.AMPacket;
Packet = SynchronizedDisseminateFinishP.Packet;
PacketAcknowledgements = SynchronizedDisseminateFinishP.PacketAcknowledgements;

SubAMSend = SynchronizedDisseminateFinishP;
SubReceive = SynchronizedDisseminateFinishP.SubReceive;
SubSnoop = SynchronizedDisseminateFinishP.SubSnoop;
SubAMPacket = SynchronizedDisseminateFinishP.SubAMPacket;
SubPacket = SynchronizedDisseminateFinishP.SubPacket;
SubPacketAcknowledgements = SynchronizedDisseminateFinishP.SubPacketAcknowledgements;
SubLinkPacketMetadata = SynchronizedDisseminateFinishP.SubLinkPacketMetadata;
LowPowerListening = SynchronizedDisseminateFinishP.LowPowerListening;
RadioChannel = SynchronizedDisseminateFinishP.RadioChannel;
SubPacketTimeSyncOffset = SynchronizedDisseminateFinishP.SubPacketTimeSyncOffset;

SubPacketTimeStampMilli = SynchronizedDisseminateFinishP.SubPacketTimeStampMilli;
SubPacketTimeStamp32khz = SynchronizedDisseminateFinishP.SubPacketTimeStamp32khz;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;
PacketTimeSyncOffset = SubPacketTimeSyncOffset;

components LedsC;
components new TimerMilliC() as SendTimerC;
components new TimerMilliC() as FinishTimerC;

SynchronizedDisseminateFinishP.Leds -> LedsC;
SynchronizedDisseminateFinishP.SendTimer -> SendTimerC;
SynchronizedDisseminateFinishP.FinishTimer -> FinishTimerC;

components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC;
LocalTime32khzC.Counter -> Counter32khz32C;
SynchronizedDisseminateFinishP.LocalTime -> LocalTime32khzC;

components SerialDbgsC;
SynchronizedDisseminateFinishP.SerialDbgs -> SerialDbgsC.SerialDbgs[process];

}
