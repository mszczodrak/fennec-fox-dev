#include <Fennec.h>

generic configuration dipC(process_t process) {
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

uses interface dipParams;

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

}

implementation {

components new dipP(process);
SplitControl = dipP;
dipParams = dipP;
AMSend = dipP.AMSend;
Receive = dipP.Receive;
Snoop = dipP.Snoop;
AMPacket = dipP.AMPacket;
Packet = dipP.Packet;
PacketAcknowledgements = dipP.PacketAcknowledgements;

SubAMSend = dipP;
SubReceive = dipP.SubReceive;
SubSnoop = dipP.SubSnoop;
SubAMPacket = dipP.SubAMPacket;
SubPacket = dipP.SubPacket;
SubPacketAcknowledgements = dipP.SubPacketAcknowledgements;
SubLinkPacketMetadata = dipP.SubLinkPacketMetadata;
LowPowerListening = dipP.LowPowerListening;
RadioChannel = dipP.RadioChannel;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;
}
