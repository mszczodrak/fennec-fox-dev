#include "AM.h"

generic configuration CtpLplAMReceiverC(am_id_t amId) {
  provides {
    interface Receive;
    interface Packet;
    interface AMPacket;
  }
}

implementation {
  components CtpActiveMessageC;

  Receive = CtpActiveMessageC.Receive[amId];
  Packet = CtpActiveMessageC;
  AMPacket = CtpActiveMessageC;
}
