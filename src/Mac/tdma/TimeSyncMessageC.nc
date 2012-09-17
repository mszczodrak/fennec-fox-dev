/**
 * The Active Message layer for the  radio with timesync support. This
 * configuration is just layer above ActiveMessageC that supports
 * TimeSyncPacket and TimeSyncAMSend interfaces (TEP 133)
 *
 * @author: Miklos Maroti
 * @author: Brano Kusy ( port)
 */

#include <Timer.h>
#include <AM.h>
#include "TimeSyncMessage.h"

configuration TimeSyncMessageC
{
    provides
    {
        interface SplitControl;
        interface Receive[am_id_t id];
        interface Packet;
        interface AMPacket;
        interface PacketAcknowledgements;
    
        interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

        interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;

	interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    	interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    }
}

implementation
{
        components TimeSyncMessageP, FennecPacketC, LedsC;
        components FtspActiveMessageC;

        TimeSyncAMSend32khz = TimeSyncMessageP;
        TimeSyncPacket32khz = TimeSyncMessageP;

        TimeSyncAMSendMilli = TimeSyncMessageP;
        TimeSyncPacketMilli = TimeSyncMessageP;

        Packet = TimeSyncMessageP;
        // use the AMSenderC infrastructure to avoid concurrent send clashes
        components new FtspSenderC(AM_TIMESYNCMSG);
        TimeSyncMessageP.SubSend -> FtspSenderC;
      	TimeSyncMessageP.SubAMPacket -> FtspSenderC;
        TimeSyncMessageP.SubPacket -> FtspSenderC;

        TimeSyncMessageP.PacketTimeStamp32khz -> FennecPacketC;
        TimeSyncMessageP.PacketTimeStampMilli -> FennecPacketC;
        TimeSyncMessageP.PacketTimeSyncOffset -> FennecPacketC;
        components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
        LocalTime32khzC.Counter -> Counter32khz32C;
        TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
        TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;
        TimeSyncMessageP.Leds -> LedsC;

        SplitControl = FtspActiveMessageC;
        PacketAcknowledgements = FtspActiveMessageC;
        
        Receive = TimeSyncMessageP.Receive;
        AMPacket = TimeSyncMessageP;
        TimeSyncMessageP.SubReceive -> FtspActiveMessageC.Receive[AM_TIMESYNCMSG];

  	PacketTimeStamp32khz = FennecPacketC;
  	PacketTimeStampMilli = FennecPacketC;

}
