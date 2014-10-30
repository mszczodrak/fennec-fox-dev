#include <Fennec.h>

generic configuration reTrickleC(process_t process) {
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

uses interface Param;

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

components new reTrickleP(process);
SplitControl = reTrickleP;
Param = reTrickleP;
AMSend = reTrickleP.AMSend;
Receive = reTrickleP.Receive;
Snoop = reTrickleP.Snoop;
AMPacket = reTrickleP.AMPacket;
Packet = reTrickleP.Packet;
PacketAcknowledgements = reTrickleP.PacketAcknowledgements;

SubAMSend = reTrickleP;
SubReceive = reTrickleP.SubReceive;
SubSnoop = reTrickleP.SubSnoop;
SubAMPacket = reTrickleP.SubAMPacket;
SubPacket = reTrickleP.SubPacket;
SubPacketAcknowledgements = reTrickleP.SubPacketAcknowledgements;
SubLinkPacketMetadata = reTrickleP.SubLinkPacketMetadata;
LowPowerListening = reTrickleP.LowPowerListening;
RadioChannel = reTrickleP.RadioChannel;

components LedsC;
components new TimerMilliC() as SendTimerC;

reTrickleP.Leds -> LedsC;
reTrickleP.SendTimer -> SendTimerC;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;

components new TimerMilliC() as FinishTimerC;
reTrickleP.FinishTimer -> FinishTimerC;
}
