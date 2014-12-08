
#include <Fennec.h>

generic configuration down_sampleC(process_t process_id) {
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
components new down_sampleP(process_id);
SplitControl = down_sampleP;

Param = down_sampleP;

SubAMSend = down_sampleP.SubAMSend;
SubReceive = down_sampleP.SubReceive;
SubSnoop = down_sampleP.SubSnoop;
SubAMPacket = down_sampleP.SubAMPacket;
SubPacket = down_sampleP.SubPacket;
SubPacketAcknowledgements = down_sampleP.SubPacketAcknowledgements;

SubPacketLinkQuality = down_sampleP.SubPacketLinkQuality;
SubPacketTransmitPower = down_sampleP.SubPacketTransmitPower;
SubPacketRSSI = down_sampleP.SubPacketRSSI;
SubPacketTimeSyncOffset = down_sampleP.SubPacketTimeSyncOffset;
}
