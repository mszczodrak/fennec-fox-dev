#include <Fennec.h>

generic configuration ftspC(process_t process) {
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;
provides interface AMPacket as AMPacket;
provides interface Packet as Packet;
provides interface PacketAcknowledgements as PacketAcknowledgements;

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

components new ftspP(process);
SplitControl = ftspP;
Param = ftspP;
AMSend = ftspP.AMSend;
Receive = ftspP.Receive;
Snoop = ftspP.Snoop;
AMPacket = ftspP.AMPacket;
Packet = ftspP.Packet;
PacketAcknowledgements = ftspP.PacketAcknowledgements;
LowPowerListening = ftspP.LowPowerListening;
RadioChannel = ftspP.RadioChannel;


components CC2420TimeSyncMessageC;
SubReceive = CC2420TimeSyncMessageC.SubReceive;
SubSnoop = CC2420TimeSyncMessageC.SubSnoop;

//SubReceive = ftspP.SubReceive;
//SubSnoop = ftspP.SubSnoop;
//SubAMSend = ftspP;
//SubAMPacket = ftspP.SubAMPacket;
//SubPacket = ftspP.SubPacket;

SubAMSend = CC2420TimeSyncMessageC.SubAMSend;
SubAMPacket = CC2420TimeSyncMessageC.SubAMPacket;
SubPacket = CC2420TimeSyncMessageC.SubPacket;
SubPacketAcknowledgements = ftspP.SubPacketAcknowledgements;
SubLinkPacketMetadata = ftspP.SubLinkPacketMetadata;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;

components MainC, TimeSyncC;
MainC.SoftwareInit -> TimeSyncC;
TimeSyncC.Boot -> MainC;


}
