#include <Fennec.h>

generic configuration ftspC(process_t process) {
provides interface SplitControl;

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

components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
components TimeSyncMessageP;
components CC2420PacketC;

components new ftspP(process);
components new TimerMilliC() as ftspTimerC;
ftspP.Timer -> ftspTimerC;
Param = ftspP.Param;
SplitControl = ftspP.SplitControl;
ftspP.SubSplitControl -> TimeSyncP.SplitControl;
ftspP.GlobalTime -> TimeSyncP.GlobalTime;
//TimeSyncInfo    =   TimeSyncP;


Param = TimeSyncP.Param;
SubPacketAcknowledgements = TimeSyncP.SubPacketAcknowledgements;
SubLinkPacketMetadata = TimeSyncP.SubLinkPacketMetadata;
LowPowerListening = TimeSyncP.LowPowerListening;
RadioChannel = TimeSyncP.RadioChannel;
SubPacketLinkQuality = TimeSyncP.SubPacketLinkQuality;
SubPacketTransmitPower = TimeSyncP.SubPacketTransmitPower;
SubPacketRSSI = TimeSyncP.SubPacketRSSI;

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
SubAMPacket = TimeSyncMessageP.SubAMPacket;


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
