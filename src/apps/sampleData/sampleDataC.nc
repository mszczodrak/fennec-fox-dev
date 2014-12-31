
#include <Fennec.h>

generic configuration sampleDataC(process_t process_id) {
provides interface SplitControl;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;
uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;
}

implementation {
components new sampleDataP(process_id);
SplitControl = sampleDataP;

Param = sampleDataP;

SubAMSend = sampleDataP.SubAMSend;
SubReceive = sampleDataP.SubReceive;
SubSnoop = sampleDataP.SubSnoop;
SubAMPacket = sampleDataP.SubAMPacket;
SubPacket = sampleDataP.SubPacket;
SubPacketAcknowledgements = sampleDataP.SubPacketAcknowledgements;

SubPacketLinkQuality = sampleDataP.SubPacketLinkQuality;
SubPacketTransmitPower = sampleDataP.SubPacketTransmitPower;
SubPacketRSSI = sampleDataP.SubPacketRSSI;
SubPacketTimeSyncOffset = sampleDataP.SubPacketTimeSyncOffset;
}
