#include <Fennec.h>

generic configuration ftspC(process_t process) {
provides interface SplitControl;
provides interface AMSend as AMSend;
provides interface Receive as Receive;
provides interface Receive as Snoop;
provides interface AMPacket as AMPacket;
provides interface Packet as Packet;
provides interface PacketAcknowledgements as PacketAcknowledgements;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;

}

implementation {

components new ftspP(process);


Param = ftspP;
AMSend = ftspP.AMSend;
Receive = ftspP.Receive;
Snoop = ftspP.Snoop;
AMPacket = ftspP.AMPacket;
Packet = ftspP.Packet;
PacketAcknowledgements = ftspP.PacketAcknowledgements;
LowPowerListening = ftspP.LowPowerListening;
RadioChannel = ftspP.RadioChannel;

SubAMSend = TimeSyncMessageC.SubAMSend;
SubAMPacket = TimeSyncMessageC.SubAMPacket;
SubPacket = TimeSyncMessageC.SubPacket;
SubPacketAcknowledgements = ftspP.SubPacketAcknowledgements;
SubLinkPacketMetadata = ftspP.SubLinkPacketMetadata;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;

#define TMILLI_SYNC
#ifdef TMILLI_SYNC
components new TimeSyncP(TMilli);
TimeSyncP.Send ->  TimeSyncMessageC.TimeSyncAMSendMilli;
components LocalTimeMilliC;
TimeSyncP.LocalTime       ->  LocalTimeMilliC;
#else
//components new TimeSyncP(T32khz);
//TimeSyncP.Send ->  TimeSyncMessageC.TimeSyncAMSend32khz;
//components Counter32khz32C;
//components new CounterToLocalTimeC(T32khz) as LocalTime32khzC;
//LocalTime32khzC.Counter -> Counter32khz32C;
//TimeSyncP.LocalTime     -> LocalTime32khzC;
#endif

SplitControl = TimeSyncP;
components TimeSyncMessageC;
SubReceive = TimeSyncMessageC.SubReceive;
SubSnoop = TimeSyncMessageC.SubSnoop;

TimeSyncP.Receive -> TimeSyncMessageC.Receive;

//GlobalTime      =   TimeSyncP;
SplitControl      =   TimeSyncP;
//TimeSyncInfo    =   TimeSyncP;
//TimeSyncMode    =   TimeSyncP;
//TimeSyncNotify  =   TimeSyncP;

TimeSyncP.TimeSyncPacket  ->  TimeSyncMessageC;

components new TimerMilliC() as TimerC;
TimeSyncP.Timer ->  TimerC;

components RandomC;
TimeSyncP.Random -> RandomC;

}
