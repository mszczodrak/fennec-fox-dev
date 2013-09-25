#include "AM.h"

configuration TrickleActiveMessageC {
provides interface SplitControl;
provides interface AMSend[am_id_t id];
provides interface Receive[am_id_t id];
provides interface Receive as Snoop[am_id_t id];
provides interface AMPacket;
provides interface Packet;
provides interface PacketAcknowledgements;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}
implementation {
components new TrickleActiveMessageP();
SplitControl = TrickleActiveMessageP;
AMSend = TrickleActiveMessageP;
Receive = TrickleActiveMessageP.Receive;
Snoop = TrickleActiveMessageP.Snoop;
AMPacket = TrickleActiveMessageP.AMPacket;
Packet = TrickleActiveMessageP.Packet;
PacketAcknowledgements = TrickleActiveMessageP.PacketAcknowledgements;

MacAMSend = TrickleActiveMessageP.MacAMSend;
MacReceive = TrickleActiveMessageP.MacReceive;
MacSnoop = TrickleActiveMessageP.MacSnoop;
MacPacket = TrickleActiveMessageP.MacPacket;
MacAMPacket = TrickleActiveMessageP.MacAMPacket;
MacPacketAcknowledgements = TrickleActiveMessageP.MacPacketAcknowledgements;
}
