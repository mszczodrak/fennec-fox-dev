
#include <Fennec.h>

generic configuration FixDestC(process_t process_id) {
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
components new FixDestP(process_id);
SplitControl = FixDestP;

Param = FixDestP;

SubAMSend = FixDestP.SubAMSend;
SubReceive = FixDestP.SubReceive;
SubSnoop = FixDestP.SubSnoop;
SubAMPacket = FixDestP.SubAMPacket;
SubPacket = FixDestP.SubPacket;
SubPacketAcknowledgements = FixDestP.SubPacketAcknowledgements;

SubPacketLinkQuality = FixDestP.SubPacketLinkQuality;
SubPacketTransmitPower = FixDestP.SubPacketTransmitPower;
SubPacketRSSI = FixDestP.SubPacketRSSI;
SubPacketTimeSyncOffset = FixDestP.SubPacketTimeSyncOffset;
}
