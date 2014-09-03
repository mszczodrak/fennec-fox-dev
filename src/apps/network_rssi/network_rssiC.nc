
#include <Fennec.h>

generic configuration network_rssiC(process_t process_id) {
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
}

implementation {
components new network_rssiP(process_id);
SplitControl = network_rssiP;

Param = network_rssiP;

SubAMSend = network_rssiP.SubAMSend;
SubReceive = network_rssiP.SubReceive;
SubSnoop = network_rssiP.SubSnoop;
SubAMPacket = network_rssiP.SubAMPacket;
SubPacket = network_rssiP.SubPacket;
SubPacketAcknowledgements = network_rssiP.SubPacketAcknowledgements;

SubPacketLinkQuality = network_rssiP.SubPacketLinkQuality;
SubPacketTransmitPower = network_rssiP.SubPacketTransmitPower;
SubPacketRSSI = network_rssiP.SubPacketRSSI;
}
