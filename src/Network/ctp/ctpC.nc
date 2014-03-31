#include <Fennec.h>

generic configuration ctpC(process_t process) {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface ctpParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;
}

implementation {

components new ctpP(process);
SplitControl = ctpP.SplitControl;
ctpParams = ctpP;
NetworkAMSend = ctpP.NetworkAMSend;
NetworkReceive = ctpP.NetworkReceive;
NetworkSnoop = ctpP.NetworkSnoop;
NetworkAMPacket = ctpP.NetworkAMPacket;
NetworkPacket = ctpP.NetworkPacket;
NetworkPacketAcknowledgements = ctpP.NetworkPacketAcknowledgements;

MacAMSend = ctpP;
MacReceive = ctpP.MacReceive;
MacSnoop = ctpP.MacSnoop;
MacAMPacket = ctpP.MacAMPacket;
MacPacket = ctpP.MacPacket;
MacPacketAcknowledgements = ctpP.MacPacketAcknowledgements;
MacLinkPacketMetadata = ctpP.MacLinkPacketMetadata;
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
//ctpP.CtpReveive -> Collector.Receive[process];


components CtpP;
CtpP.RadioControl -> ctpP.FakeRadioControl;
MacAMPacket = CtpP.MacAMPacket;
MacPacket = CtpP.MacPacket;
MacLinkPacketMetadata = CtpP.MacLinkPacketMetadata;
MacPacketAcknowledgements = CtpP.MacPacketAcknowledgements;

}
