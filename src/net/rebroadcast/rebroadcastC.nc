#include <Fennec.h>

generic configuration rebroadcastC(process_t process) {
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

uses interface rebroadcastParams;

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

components new rebroadcastP(process);
SplitControl = rebroadcastP;
rebroadcastParams = rebroadcastP;
AMSend = rebroadcastP.AMSend;
Receive = rebroadcastP.Receive;
Snoop = rebroadcastP.Snoop;
AMPacket = rebroadcastP.AMPacket;
Packet = rebroadcastP.Packet;
PacketAcknowledgements = rebroadcastP.PacketAcknowledgements;

SubAMSend = rebroadcastP;
SubReceive = rebroadcastP.SubReceive;
SubSnoop = rebroadcastP.SubSnoop;
SubAMPacket = rebroadcastP.SubAMPacket;
SubPacket = rebroadcastP.SubPacket;
SubPacketAcknowledgements = rebroadcastP.SubPacketAcknowledgements;
SubLinkPacketMetadata = rebroadcastP.SubLinkPacketMetadata;
LowPowerListening = rebroadcastP.LowPowerListening;
RadioChannel = rebroadcastP.RadioChannel;

components LedsC;
components new TimerMilliC();

rebroadcastP.Leds -> LedsC;
rebroadcastP.Timer -> TimerMilliC;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;
}
