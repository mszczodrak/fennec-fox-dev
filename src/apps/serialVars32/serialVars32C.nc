
#include <Fennec.h>

generic configuration serialVars32C(process_t process_id) {
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
components new serialVars32P(process_id);
SplitControl = serialVars32P;

Param = serialVars32P;

SubAMSend = serialVars32P.SubAMSend;
SubReceive = serialVars32P.SubReceive;
SubSnoop = serialVars32P.SubSnoop;
SubAMPacket = serialVars32P.SubAMPacket;
SubPacket = serialVars32P.SubPacket;
SubPacketAcknowledgements = serialVars32P.SubPacketAcknowledgements;

SubPacketLinkQuality = serialVars32P.SubPacketLinkQuality;
SubPacketTransmitPower = serialVars32P.SubPacketTransmitPower;
SubPacketRSSI = serialVars32P.SubPacketRSSI;
SubPacketTimeSyncOffset = serialVars32P.SubPacketTimeSyncOffset;
}
