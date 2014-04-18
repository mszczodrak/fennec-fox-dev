#include <RadioConfig.h>

configuration cc2420xC {

provides interface SplitControl;
provides interface AMSend[process_t process_id];
provides interface Receive[process_t process_id];
provides interface Receive as Snoop[process_t process_id];
provides interface AMPacket;
provides interface Packet;
provides interface PacketAcknowledgements;
provides interface LinkPacketMetadata;

uses interface cc2420xParams;
uses interface StdControl as AMQueueControl;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;

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

AMSend = CC2420XActiveMessageC.AMSend;
Receive = CC2420XActiveMessageC.Receive;
Snoop = CC2420XActiveMessageC.Snoop;

Packet = CC2420XActiveMessageC.Packet;
AMPacket = CC2420XActiveMessageC.AMPacket;

LowPowerListening = CC2420XActiveMessageC.LowPowerListening;
RadioChannel = CC2420XActiveMessageC.RadioChannel;
PacketTimeStampRadio = CC2420XActiveMessageC.PacketTimeStampRadio;
PacketTimeStampMilli = CC2420XActiveMessageC.PacketTimeStampMilli;
PacketTimeStamp32khz = CC2420XActiveMessageC.PacketTimeStamp32khz;
PacketAcknowledgements = CC2420XActiveMessageC.PacketAcknowledgements;
LinkPacketMetadata = CC2420XActiveMessageC.LinkPacketMetadata;

components CC2420XRadioC;
cc2420xParams = CC2420XRadioC;

components SystemLowPowerListeningC;
cc2420xP.SystemLowPowerListening -> SystemLowPowerListeningC;
cc2420xP.LowPowerListening -> CC2420XActiveMessageC.LowPowerListening;

}
