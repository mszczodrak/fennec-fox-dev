#include "AM.h"

generic configuration TrickleLplAMSenderC(am_id_t AMId)
{
  provides {
    interface AMSend;
    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements as Acks;
  }
}

implementation
{
  components new TrickleDirectAMSenderC(AMId);
  components new TrickleLplAMSenderP();
  components TrickleActiveMessageC;
//  components SystemLowPowerListeningC;

  AMSend = TrickleLplAMSenderP;
  Packet = TrickleDirectAMSenderC;
  AMPacket = TrickleDirectAMSenderC;
  Acks = TrickleDirectAMSenderC;

  TrickleLplAMSenderP.SubAMSend -> TrickleDirectAMSenderC;
//  TrickleLplAMSenderP.Lpl -> TrickleActiveMessageC;
//  TrickleLplAMSenderP.SystemLowPowerListening -> SystemLowPowerListeningC;
}
