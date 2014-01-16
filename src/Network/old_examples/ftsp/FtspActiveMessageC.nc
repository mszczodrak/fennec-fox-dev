#include "AM.h"

configuration FtspActiveMessageC {
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
  components new FtspActiveMessageP();
  SplitControl = FtspActiveMessageP;
  AMSend = FtspActiveMessageP;
  Receive = FtspActiveMessageP.Receive;
  Snoop = FtspActiveMessageP.Snoop;
  AMPacket = FtspActiveMessageP.AMPacket;
  Packet = FtspActiveMessageP.Packet;
  PacketAcknowledgements = FtspActiveMessageP.PacketAcknowledgements;

  MacAMSend = FtspActiveMessageP.MacAMSend;
  MacReceive = FtspActiveMessageP.MacReceive;
  MacSnoop = FtspActiveMessageP.MacSnoop;
  MacPacket = FtspActiveMessageP.MacPacket;
  MacAMPacket = FtspActiveMessageP.MacAMPacket;
  MacPacketAcknowledgements = FtspActiveMessageP.MacPacketAcknowledgements;
  MacStatus = FtspActiveMessageP.MacStatus;
}
