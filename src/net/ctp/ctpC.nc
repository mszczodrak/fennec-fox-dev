#include <Fennec.h>

generic configuration ctpC(process_t process) {
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
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;

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
uses interface PacketField<uint8_t> as SubPacketTimeSyncOffset;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;
}

implementation {

components new ctpP(process);
SplitControl = ctpP.SplitControl;
Param = ctpP;
AMSend = ctpP.AMSend;
Receive = ctpP.Receive;
Snoop = ctpP.Snoop;

PacketAcknowledgements = SubPacketAcknowledgements;
AMPacket = SubAMPacket;
LowPowerListening = ctpP.LowPowerListening;
RadioChannel = ctpP.RadioChannel;

components CollectionC as Collector;

ctpP.RoutingControl -> Collector;
ctpP.RootControl -> Collector;
ctpP.CollectionPacket -> Collector;
ctpP.CtpInfo -> Collector;
ctpP.CtpCongestion -> Collector;

components new CollectionSenderC(process);
ctpP.CtpSend -> CollectionSenderC.Send;
ctpP.CtpReceive -> Collector.Receive[process];
ctpP.CtpSnoop -> Collector.Snoop[process];

Packet = CollectionSenderC.Packet;

components CtpP;
CtpP.RadioControl -> ctpP.FakeRadioControl;
SubAMSend = CtpP.SubAMSend;
SubAMPacket = CtpP.SubAMPacket;
SubPacket = CtpP.SubPacket;
SubLinkPacketMetadata = CtpP.SubLinkPacketMetadata;
SubPacketAcknowledgements = CtpP.SubPacketAcknowledgements;
SubReceive = CtpP.SubReceive;
SubSnoop = CtpP.SubSnoop;

CtpP.Param = Param;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;
PacketTimeSyncOffset = SubPacketTimeSyncOffset;

SubPacketTimeStampMilli = ctpP.SubPacketTimeStampMilli;
SubPacketTimeStamp32khz = ctpP.SubPacketTimeStamp32khz;

}
