
#include <Fennec.h>

generic configuration serialVars16C(process_t process_id) {
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
components new serialVars16P(process_id);
SplitControl = serialVars16P;

Param = serialVars16P;

SubAMSend = serialVars16P.SubAMSend;
SubReceive = serialVars16P.SubReceive;
SubSnoop = serialVars16P.SubSnoop;
SubAMPacket = serialVars16P.SubAMPacket;
SubPacket = serialVars16P.SubPacket;
SubPacketAcknowledgements = serialVars16P.SubPacketAcknowledgements;

SubPacketLinkQuality = serialVars16P.SubPacketLinkQuality;
SubPacketTransmitPower = serialVars16P.SubPacketTransmitPower;
SubPacketRSSI = serialVars16P.SubPacketRSSI;
SubPacketTimeSyncOffset = serialVars16P.SubPacketTimeSyncOffset;
}
