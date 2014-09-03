#include <Fennec.h>

generic configuration ftspC(process_t process) {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface Param;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
}

implementation {

components new ftspP(process);
SplitControl = ftspP;
Param = ftspP;
NetworkAMSend = ftspP.NetworkAMSend;
NetworkReceive = ftspP.NetworkReceive;
NetworkSnoop = ftspP.NetworkSnoop;
NetworkAMPacket = ftspP.NetworkAMPacket;
NetworkPacket = ftspP.NetworkPacket;
NetworkPacketAcknowledgements = ftspP.NetworkPacketAcknowledgements;

MacAMSend = ftspP;
MacReceive = ftspP.MacReceive;
MacSnoop = ftspP.MacSnoop;
MacAMPacket = ftspP.MacAMPacket;
MacPacket = ftspP.MacPacket;
MacPacketAcknowledgements = ftspP.MacPacketAcknowledgements;
MacLinkPacketMetadata = ftspP.MacLinkPacketMetadata;
}
