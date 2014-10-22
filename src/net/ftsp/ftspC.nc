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
components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
components TimeSyncMessageP;
components CC2420PacketC;


Param = ftspP;
AMSend = ftspP.AMSend;
Receive = ftspP.Receive;
Snoop = ftspP.Snoop;
AMPacket = ftspP.AMPacket;
Packet = ftspP.Packet;
PacketAcknowledgements = ftspP.PacketAcknowledgements;
LowPowerListening = ftspP.LowPowerListening;
RadioChannel = ftspP.RadioChannel;
SubAMPacket = ftspP.SubAMPacket;


SubPacketAcknowledgements = ftspP.SubPacketAcknowledgements;
SubLinkPacketMetadata = ftspP.SubLinkPacketMetadata;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;

#define TMILLI_SYNC
#ifdef TMILLI_SYNC
components new TimeSyncP(TMilli);
TimeSyncP.Send ->  TimeSyncMessageP.TimeSyncAMSendMilli;
TimeSyncP.LocalTime       ->  LocalTimeMilliC;
#else
//components new TimeSyncP(T32khz);
//TimeSyncP.Send ->  TimeSyncMessageP.TimeSyncAMSend32khz;
//LocalTime32khzC.Counter -> Counter32khz32C;
//TimeSyncP.LocalTime     -> LocalTime32khzC;
#endif

SubReceive = TimeSyncMessageP.SubReceive;
SubSnoop = TimeSyncMessageP.SubSnoop;
SubAMSend = TimeSyncMessageP.SubAMSend;
SubPacket = TimeSyncMessageP.SubPacket;


//GlobalTime      =   TimeSyncP;
SplitControl      =   TimeSyncP;
//TimeSyncInfo    =   TimeSyncP;
//TimeSyncNotify  =   TimeSyncP;

TimeSyncP.Receive -> TimeSyncMessageP.Receive;
TimeSyncP.TimeSyncPacket  ->  TimeSyncMessageP;

components new TimerMilliC() as TimerC;
TimeSyncP.Timer ->  TimerC;

components RandomC;
TimeSyncP.Random -> RandomC;

TimeSyncMessageP.PacketTimeStamp32khz -> CC2420PacketC;
TimeSyncMessageP.PacketTimeStampMilli -> CC2420PacketC;
TimeSyncMessageP.PacketTimeSyncOffset -> CC2420PacketC;

LocalTime32khzC.Counter -> Counter32khz32C;
TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;

}
