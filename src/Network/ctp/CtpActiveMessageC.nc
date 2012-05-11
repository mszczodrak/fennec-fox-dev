#include "AM.h"

configuration CtpActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface PacketAcknowledgements;
  }

  uses interface AMSend as MacAMSend;
  uses interface Receive as MacReceive;
  uses interface Receive as MacSnoop;
  uses interface AMPacket as MacAMPacket;
  uses interface Packet as MacPacket;
  uses interface PacketAcknowledgements as MacPacketAcknowledgements;
  uses interface ModuleStatus as MacStatus;
}
implementation {
  components new CtpActiveMessageP();
  SplitControl = CtpActiveMessageP;
  AMSend = CtpActiveMessageP;
  Receive = CtpActiveMessageP.Receive;
  Snoop = CtpActiveMessageP.Snoop;
  AMPacket = CtpActiveMessageP.AMPacket;
  Packet = CtpActiveMessageP.Packet;
  PacketAcknowledgements = CtpActiveMessageP.PacketAcknowledgements;

  MacAMSend = CtpActiveMessageP.MacAMSend;
  MacReceive = CtpActiveMessageP.MacReceive;
  MacSnoop = CtpActiveMessageP.MacSnoop;
  MacPacket = CtpActiveMessageP.MacPacket;
  MacAMPacket = CtpActiveMessageP.MacAMPacket;
  MacPacketAcknowledgements = CtpActiveMessageP.MacPacketAcknowledgements;
  MacStatus = CtpActiveMessageP.MacStatus;
}
