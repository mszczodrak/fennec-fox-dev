#include <RadioConfig.h>

configuration cc2420C {

provides interface SplitControl;
provides interface AMSend as MacAMSend[process_t process_id];
provides interface Receive as MacReceive[process_t process_id];
provides interface Receive as MacSnoop[process_t process_id];
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface cc2420Params;

provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;

uses interface PacketTimeStamp<TRadio, uint32_t> as UnimplementedPacketTimeStampRadio;
uses interface PacketTimeStamp<TMilli, uint32_t> as UnimplementedPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;

}

implementation
{

components cc2420P;
cc2420Params = cc2420P;

components MultiplexLplC;
cc2420Params = MultiplexLplC;

/* hacking to be cc2420x compatible */
RadioChannel = cc2420P;
/*
MacPacketTimeStampRadio = cc2420P.MacPacketTimeStampRadio;
MacPacketTimeStampMilli = cc2420P.MacPacketTimeStampMilli;
MacPacketTimeStamp32khz = cc2420P.MacPacketTimeStamp32khz;
*/

MacPacketTimeStampRadio = UnimplementedPacketTimeStampRadio;
MacPacketTimeStampMilli = UnimplementedPacketTimeStampMilli;
MacPacketTimeStamp32khz = UnimplementedPacketTimeStamp32khz;

components CC2420ActiveMessageC;
SplitControl = CC2420ActiveMessageC;

MacAMSend = CC2420ActiveMessageC.AMSend;
MacReceive = CC2420ActiveMessageC.Receive;
MacSnoop = CC2420ActiveMessageC.Snoop;

MacPacket = CC2420ActiveMessageC.Packet;
MacAMPacket = CC2420ActiveMessageC.AMPacket;

LowPowerListening = CC2420ActiveMessageC.LowPowerListening;
//RadioChannel = CC2420ActiveMessageC.RadioChannel;
//MacPacketTimeStampRadio = CC2420ActiveMessageC.PacketTimeStampRadio;
//MacPacketTimeStampMilli = CC2420ActiveMessageC.PacketTimeStampMilli;
//MacPacketTimeStamp32khz = CC2420ActiveMessageC.PacketTimeStamp32khz;
MacPacketAcknowledgements = CC2420ActiveMessageC.PacketAcknowledgements;
MacLinkPacketMetadata = CC2420ActiveMessageC.LinkPacketMetadata;

}
