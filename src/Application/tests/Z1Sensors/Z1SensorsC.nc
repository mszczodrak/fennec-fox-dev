generic configuration Z1SensorsC() {
provides interface SplitControl;

uses interface Z1SensorsParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components new Z1SensorsP();
SplitControl = Z1SensorsP;

Z1SensorsParams = Z1SensorsP;

NetworkAMSend = Z1SensorsP.NetworkAMSend;
NetworkReceive = Z1SensorsP.NetworkReceive;
NetworkSnoop = Z1SensorsP.NetworkSnoop;
NetworkAMPacket = Z1SensorsP.NetworkAMPacket;
NetworkPacket = Z1SensorsP.NetworkPacket;
NetworkPacketAcknowledgements = Z1SensorsP.NetworkPacketAcknowledgements;
}
