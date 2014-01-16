#include "AM.h"

generic configuration CtpLplAMSenderC(am_id_t AMId)
{
provides interface AMSend;
provides interface Packet;
provides interface AMPacket;
provides interface PacketAcknowledgements as Acks;
}

implementation
{

components new CtpAMQueueEntryP(AMId) as CtpAMQueueEntryP;
components CtpActiveMessageC;

CtpAMQueueEntryP.AMPacket -> CtpActiveMessageC;

AMSend = CtpAMQueueEntryP;
Packet = CtpActiveMessageC;
AMPacket = CtpActiveMessageC;
Acks = CtpActiveMessageC;

CtpAMQueueEntryP.Send -> CtpAMQueueImplP.Send[unique(UQ_AMQUEUE_SEND)];

enum {
    NUM_CLIENTS = uniqueCount(UQ_AMQUEUE_SEND)
};

components new CtpAMQueueImplP(NUM_CLIENTS);

CtpAMQueueImplP.AMSend -> CtpActiveMessageC;
CtpAMQueueImplP.AMPacket -> CtpActiveMessageC;
CtpAMQueueImplP.Packet -> CtpActiveMessageC;

}
