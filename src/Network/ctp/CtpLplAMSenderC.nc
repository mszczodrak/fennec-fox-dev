#include "AM.h"

generic configuration CtpLplAMSenderC(am_id_t AMId)
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
  components new CtpDirectAMSenderC(AMId);
  components new CtpLplAMSenderP();
  components CtpActiveMessageC;
//  components SystemLowPowerListeningC;

  AMSend = CtpLplAMSenderP;
  Packet = CtpDirectAMSenderC;
  AMPacket = CtpDirectAMSenderC;
  Acks = CtpDirectAMSenderC;

  CtpLplAMSenderP.SubAMSend -> CtpDirectAMSenderC;
//  CtpLplAMSenderP.Lpl -> CtpActiveMessageC;
//  CtpLplAMSenderP.SystemLowPowerListening -> SystemLowPowerListeningC;
}
