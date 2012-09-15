/**
 * The Active Message layer for the CC2420 radio with timesync support. This
 * configuration is just layer above CC2420ActiveMessageC that supports
 * TimeSyncPacket and TimeSyncAMSend interfaces (TEP 133)
 *
 * @author: Miklos Maroti
 * @author: Brano Kusy (CC2420 port)
 */

#include <Timer.h>
#include <AM.h>
#include "CC2420TimeSyncMessage.h"

configuration CC2420TimeSyncMessageC
{
    provides
    {
        interface SplitControl;
        interface Receive[am_id_t id];
        interface Receive as Snoop[am_id_t id];
        interface Packet;
        interface AMPacket;
        interface PacketAcknowledgements;
    
        interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz[am_id_t id];
        interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

        interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
        interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
    }
}

implementation
{
        components CC2420TimeSyncMessageP, CC2420PacketC, LedsC;
        components FtspActiveMessageC;

        TimeSyncAMSend32khz = CC2420TimeSyncMessageP;
        TimeSyncPacket32khz = CC2420TimeSyncMessageP;

        TimeSyncAMSendMilli = CC2420TimeSyncMessageP;
        TimeSyncPacketMilli = CC2420TimeSyncMessageP;

        Packet = CC2420TimeSyncMessageP;
        // use the AMSenderC infrastructure to avoid concurrent send clashes
        components new FtspSenderC(AM_TIMESYNCMSG);
        CC2420TimeSyncMessageP.SubSend -> FtspSenderC;
      	CC2420TimeSyncMessageP.SubAMPacket -> FtspSenderC;
        CC2420TimeSyncMessageP.SubPacket -> FtspSenderC;

        CC2420TimeSyncMessageP.PacketTimeStamp32khz -> CC2420PacketC;
        CC2420TimeSyncMessageP.PacketTimeStampMilli -> CC2420PacketC;
        CC2420TimeSyncMessageP.PacketTimeSyncOffset -> CC2420PacketC;
        components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
        LocalTime32khzC.Counter -> Counter32khz32C;
        CC2420TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
        CC2420TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;
        CC2420TimeSyncMessageP.Leds -> LedsC;

        SplitControl = FtspActiveMessageC;
        PacketAcknowledgements = FtspActiveMessageC;
        
        Receive = CC2420TimeSyncMessageP.Receive;
        Snoop = CC2420TimeSyncMessageP.Snoop;
        AMPacket = CC2420TimeSyncMessageP;
        CC2420TimeSyncMessageP.SubReceive -> FtspActiveMessageC.Receive[AM_TIMESYNCMSG];
        CC2420TimeSyncMessageP.SubSnoop -> FtspActiveMessageC.Snoop[AM_TIMESYNCMSG];
}
