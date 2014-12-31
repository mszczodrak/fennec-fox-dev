
#include <Fennec.h>

generic configuration buttonC(process_t process_id) {
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
components new buttonP(process_id);
SplitControl = buttonP;

Param = buttonP;

SubAMSend = buttonP.SubAMSend;
SubReceive = buttonP.SubReceive;
SubSnoop = buttonP.SubSnoop;
SubAMPacket = buttonP.SubAMPacket;
SubPacket = buttonP.SubPacket;
SubPacketAcknowledgements = buttonP.SubPacketAcknowledgements;

SubPacketLinkQuality = buttonP.SubPacketLinkQuality;
SubPacketTransmitPower = buttonP.SubPacketTransmitPower;
SubPacketRSSI = buttonP.SubPacketRSSI;
SubPacketTimeSyncOffset = buttonP.SubPacketTimeSyncOffset;
}
