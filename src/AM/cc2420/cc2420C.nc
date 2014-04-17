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
uses interface StdControl as AMQueueControl;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

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
SplitControl = cc2420P.SplitControl;
AMQueueControl = cc2420P.AMQueueControl;

components CC2420ControlP;
cc2420Params = CC2420ControlP;

components CC2420TransmitP;
cc2420Params = CC2420TransmitP;

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

enum {
    CC2420_AM_SEND_ID     = unique(RADIO_SEND_RESOURCE),
};

components CC2420RadioC as Radio;
components CC2420ActiveMessageP as AM;
components ActiveMessageAddressC;
components CC2420CsmaC as CsmaC;
components CC2420ControlC;
components CC2420PacketC;

cc2420P.SubSplitControl -> Radio;
// RadioBackoff = AM;
MacPacket = AM.Packet;
MacAMSend = AM.AMSend;
// SendNotifier = AM;
MacReceive = AM.Receive;
MacSnoop = AM.Snoop;
MacAMPacket = AM.AMPacket;
// PacketLink = Radio;
LowPowerListening = Radio.LowPowerListening;
// CC2420Packet = Radio;
MacPacketAcknowledgements = Radio;
MacLinkPacketMetadata = Radio.LinkPacketMetadata;

// Radio resource for the AM layer
AM.RadioResource -> Radio.Resource[CC2420_AM_SEND_ID];
cc2420P.RadioResource -> Radio.Resource[CC2420_AM_SEND_ID];
AM.SubSend -> Radio.ActiveSend;
AM.SubReceive -> Radio.ActiveReceive;

AM.ActiveMessageAddress -> ActiveMessageAddressC;
AM.CC2420Packet -> CC2420PacketC;
AM.CC2420PacketBody -> CC2420PacketC;
AM.CC2420Config -> CC2420ControlC;

AM.SubBackoff -> CsmaC;

components LedsC;
AM.Leds -> LedsC;

//RadioChannel = CC2420ActiveMessageC.RadioChannel;
//MacPacketTimeStampRadio = CC2420ActiveMessageC.PacketTimeStampRadio;
//MacPacketTimeStampMilli = CC2420ActiveMessageC.PacketTimeStampMilli;
//MacPacketTimeStamp32khz = CC2420ActiveMessageC.PacketTimeStamp32khz;

/* System LowPowerListening Confs */
components SystemLowPowerListeningC;
cc2420P.SystemLowPowerListening -> SystemLowPowerListeningC;
cc2420P.LowPowerListening -> Radio.LowPowerListening;

}
