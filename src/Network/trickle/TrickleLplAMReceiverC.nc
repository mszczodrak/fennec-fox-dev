#include "AM.h"

generic configuration TrickleLplAMReceiverC(am_id_t amId) {
  provides {
    interface Receive;
    interface Packet;
    interface AMPacket;
  }
}

implementation {
  components TrickleActiveMessageC;

  Receive = TrickleActiveMessageC.Receive[amId];
  Packet = TrickleActiveMessageC;
  AMPacket = TrickleActiveMessageC;
}
