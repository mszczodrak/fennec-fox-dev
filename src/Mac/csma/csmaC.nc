#include "csma.h"

generic configuration csmaC(process_t process) {
provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface csmaParams;
uses interface RadioReceive;

uses interface Resource as RadioResource;
uses interface SplitControl as RadioControl;
uses interface RadioPacket;
uses interface RadioBuffer;
uses interface RadioSend;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint32_t> as PacketTimeSync;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface RadioCCA;
uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;

}

implementation {

components new csmaP(process);

components new AutoResourceAcquireLayerC();
components new Ieee154PacketLayerC();
components new UniqueLayerC();
components new PacketLinkLayerC();
components new LowPowerListeningLayerC();
components new MessageBufferLayerC();
components new RandomCollisionLayerC() as CollisionAvoidanceLayerC;
components new SoftwareAckLayerC();
components new DummyLayerC() as CsmaLayerC;
components new TimeStampingLayerC();

SplitControl = csmaP;
MacAMSend = csmaP.MacAMSend;
MacReceive = csmaP.MacReceive;
MacSnoop = csmaP.MacSnoop;
MacPacket = csmaP.MacPacket;
MacAMPacket = csmaP.MacAMPacket;
MacLinkPacketMetadata = csmaP.MacLinkPacketMetadata;
csmaParams = csmaP;


csmaP.SubSend -> AutoResourceAcquireLayerC;
csmaP.SubSplitControl -> LowPowerListeningLayerC;
csmaP.SubReceive -> PacketLinkLayerC;
csmaP.SubPacket -> Ieee154PacketLayerC;





AutoResourceAcquireLayerC.Resource = RadioResourceC.Resource[process];


MacPacketAcknowledgements = SoftwareAckLayerC;



Ieee154PacketLayerC.SubPacket -> PacketLinkLayerC;

UniqueLayerC.SubSend -> PacketLinkLayerC;

//PacketLink = PacketLinkLayerC;
PacketLinkLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
PacketLinkLayerC -> LowPowerListeningLayerC.Send;
PacketLinkLayerC -> LowPowerListeningLayerC.Receive;
PacketLinkLayerC -> LowPowerListeningLayerC.RadioPacket;

LowPowerListeningLayerC.Config -> RadioP;
LowPowerListeningLayerC.PacketAcknowledgements -> SoftwareAckLayerC;
LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
LowPowerListeningLayerC.SubPacket -> TimeStampingLayerC;
//LowPowerListening = LowPowerListeningLayerC;

MessageBufferLayerC.RadioSend -> CollisionAvoidanceLayerC;
MessageBufferLayerC.RadioReceive -> UniqueLayerC;
MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;
//RadioChannel = MessageBufferLayerC;

CollisionAvoidanceLayerC.Config -> RadioP;
CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
CollisionAvoidanceLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];


SoftwareAckLayerC.AckReceivedFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
PacketAcknowledgements = SoftwareAckLayerC;
SoftwareAckLayerC.Config -> RadioP;
SoftwareAckLayerC.SubSend -> CsmaLayerC;
SoftwareAckLayerC.SubReceive -> CsmaLayerC;

CsmaLayerC.Config -> RadioP;
CsmaLayerC -> TrafficMonitorLayerC.RadioSend;
CsmaLayerC -> TrafficMonitorLayerC.RadioReceive;
CsmaLayerC -> RadioDriverLayerC.RadioCCA;


TimeStampingLayerC.LocalTimeRadio -> RadioDriverLayerC;
TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
PacketTimeStampRadio = TimeStampingLayerC;
PacketTimeStampMilli = TimeStampingLayerC;
TimeStampingLayerC.TimeStampFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];

MetadataFlagsLayerC.SubPacket -> RadioDriverLayerC;





/*
RadioResource = csmaP.RadioResource;
RadioPacket = csmaP.RadioPacket;
RadioBuffer = csmaP.RadioBuffer;
RadioSend = csmaP.RadioSend;
RadioControl = csmaP.RadioControl;
RadioReceive = csmaP.RadioReceive;

RadioState = csmaP.RadioState;
RadioLinkPacketMetadata = csmaP.RadioLinkPacketMetadata;
RadioCCA = csmaP.RadioCCA;

components RandomC;
csmaP.Random -> RandomC;

PacketTransmitPower = csmaP.PacketTransmitPower;
PacketRSSI = csmaP.PacketRSSI;
PacketTimeSync = csmaP.PacketTimeSync;
PacketLinkQuality = csmaP.PacketLinkQuality;

components new TimerMilliC();
csmaP.Timer -> TimerMilliC;
*/

}

