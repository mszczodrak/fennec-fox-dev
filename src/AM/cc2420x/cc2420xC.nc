#include <RadioConfig.h>

configuration cc2420xC {

provides interface SplitControl;
provides interface AMSend as MacAMSend[process_t process_id];
provides interface Receive as MacReceive[process_t process_id];
provides interface Receive as MacSnoop[process_t process_id];
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface cc2420xParams;
uses interface StdControl as AMQueueControl;

provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;

}

implementation
{

components cc2420xP;
cc2420xParams = cc2420xP;
SplitControl = cc2420xP.SplitControl;
AMQueueControl = cc2420xP.AMQueueControl;
cc2420xP.SubSplitControl -> CC2420XActiveMessageC;

components CC2420XActiveMessageC;
//SplitControl = CC2420XActiveMessageC;

MacAMSend = CC2420XActiveMessageC.AMSend;
MacReceive = CC2420XActiveMessageC.Receive;
MacSnoop = CC2420XActiveMessageC.Snoop;

MacPacket = CC2420XActiveMessageC.Packet;
MacAMPacket = CC2420XActiveMessageC.AMPacket;

LowPowerListening = CC2420XActiveMessageC.LowPowerListening;
RadioChannel = CC2420XActiveMessageC.RadioChannel;
MacPacketTimeStampRadio = CC2420XActiveMessageC.PacketTimeStampRadio;
MacPacketTimeStampMilli = CC2420XActiveMessageC.PacketTimeStampMilli;
MacPacketTimeStamp32khz = CC2420XActiveMessageC.PacketTimeStamp32khz;
MacPacketAcknowledgements = CC2420XActiveMessageC.PacketAcknowledgements;
MacLinkPacketMetadata = CC2420XActiveMessageC.LinkPacketMetadata;

components CC2420XRadioC;
cc2420xParams = CC2420XRadioC;

components SystemLowPowerListeningC;
cc2420xP.SystemLowPowerListening -> SystemLowPowerListeningC;
cc2420xP.LowPowerListening -> CC2420XActiveMessageC.LowPowerListening;

}
