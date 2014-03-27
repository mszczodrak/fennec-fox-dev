#include <Fennec.h>

generic configuration rebroadcastC(process_t process) {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface rebroadcastParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
uses interface LinkPacketMetadata as MacLinkPacketMetadata;
}

implementation {

components new rebroadcastP(process);
SplitControl = rebroadcastP;
rebroadcastParams = rebroadcastP;
NetworkAMSend = rebroadcastP.NetworkAMSend;
NetworkReceive = rebroadcastP.NetworkReceive;
NetworkSnoop = rebroadcastP.NetworkSnoop;
NetworkAMPacket = rebroadcastP.NetworkAMPacket;
NetworkPacket = rebroadcastP.NetworkPacket;
NetworkPacketAcknowledgements = rebroadcastP.NetworkPacketAcknowledgements;

MacAMSend = rebroadcastP;
MacReceive = rebroadcastP.MacReceive;
MacSnoop = rebroadcastP.MacSnoop;
MacAMPacket = rebroadcastP.MacAMPacket;
MacPacket = rebroadcastP.MacPacket;
MacPacketAcknowledgements = rebroadcastP.MacPacketAcknowledgements;
MacLinkPacketMetadata = rebroadcastP.MacLinkPacketMetadata;
}
