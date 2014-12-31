
#include <Fennec.h>

generic configuration serialVars8C(process_t process_id) {
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
components new serialVars8P(process_id);
SplitControl = serialVars8P;

Param = serialVars8P;

SubAMSend = serialVars8P.SubAMSend;
SubReceive = serialVars8P.SubReceive;
SubSnoop = serialVars8P.SubSnoop;
SubAMPacket = serialVars8P.SubAMPacket;
SubPacket = serialVars8P.SubPacket;
SubPacketAcknowledgements = serialVars8P.SubPacketAcknowledgements;

SubPacketLinkQuality = serialVars8P.SubPacketLinkQuality;
SubPacketTransmitPower = serialVars8P.SubPacketTransmitPower;
SubPacketRSSI = serialVars8P.SubPacketRSSI;
SubPacketTimeSyncOffset = serialVars8P.SubPacketTimeSyncOffset;
}
