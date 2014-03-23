

#include <RadioConfig.h>

generic configuration randomC(process_t process) {

provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface randomParams;

/* new */
provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;


/* to Radio */
uses interface RadioReceive;

uses interface Resource as RadioResource;
uses interface RadioPacket;
uses interface RadioSend;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface PacketFlag as AckReceivedFlag;


uses interface RadioCCA;
uses interface RadioState;
uses interface LinkPacketMetadata as RadioLinkPacketMetadata;


uses interface ActiveMessageConfig;
uses interface UniqueConfig;
uses interface LowPowerListeningConfig;
uses interface RandomCollisionConfig;
uses interface SlottedCollisionConfig;
uses interface SoftwareAckConfig;
uses interface TrafficMonitorConfig;
uses interface CsmaConfig;
uses interface DummyConfig;

uses interface RadioAlarm[uint8_t id];
uses interface LocalTime<TRadio> as LocalTimeRadio;
uses interface PacketTimeStamp<TRadio, uint32_t> as RadioPacketTimeStampRadio;
uses interface PacketTimeStamp<TMilli, uint32_t> as RadioPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as RadioPacketTimeStamp32khz;

}

implementation
{

components new randomP(process);
randomParams = randomP.randomParams;
PacketTransmitPower = randomP.PacketTransmitPower;
PacketRSSI = randomP.PacketRSSI;
PacketLinkQuality = randomP.PacketLinkQuality;
TrafficMonitorConfig = randomP.TrafficMonitorConfig;
LowPowerListeningConfig = randomP.LowPowerListeningConfig;
CsmaConfig = randomP.CsmaConfig;
SlottedCollisionConfig = randomP.SlottedCollisionConfig;
DummyConfig = randomP.DummyConfig;
LocalTimeRadio = randomP.LocalTimeRadio;
SplitControl = randomP.SplitControl;

randomP.SubSplitControl -> LowPowerListeningLayerC;

MacLinkPacketMetadata = RadioLinkPacketMetadata;
MacPacketTimeStampRadio = RadioPacketTimeStampRadio;
MacPacketTimeStampMilli = RadioPacketTimeStampMilli;
MacPacketTimeStamp32khz = RadioPacketTimeStamp32khz;

#define UQ_RADIO_ALARM		"UQ_CC2420X_RADIO_ALARM"

components new ActiveMessageLayerC();
components new AutoResourceAcquireLayerC();
components new UniqueLayerC();

MacAMSend = ActiveMessageLayerC.AMSend[process];
MacReceive = ActiveMessageLayerC.Receive[process];
MacSnoop = ActiveMessageLayerC.Snoop[process];
MacAMPacket = ActiveMessageLayerC.AMPacket;
MacPacket = ActiveMessageLayerC;


ActiveMessageConfig = ActiveMessageLayerC.Config;
ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
ActiveMessageLayerC.SubReceive -> LowPowerListeningLayerC.Receive;
ActiveMessageLayerC.SubPacket -> LowPowerListeningLayerC.RadioPacket;

RadioResource = AutoResourceAcquireLayerC.Resource;
AutoResourceAcquireLayerC.SubSend -> UniqueLayerC;

UniqueConfig = UniqueLayerC.Config;
UniqueLayerC.SubSend -> LowPowerListeningLayerC.Send;

components new LowPowerListeningDummyC() as LowPowerListeningLayerC;
LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
LowPowerListeningLayerC.SubSend -> MessageBufferLayerC;
LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;
RadioPacket = LowPowerListeningLayerC.SubPacket;
LowPowerListening = LowPowerListeningLayerC;

components new MessageBufferLayerC();
MessageBufferLayerC.RadioSend -> CollisionAvoidanceLayerC;
MessageBufferLayerC.RadioReceive -> UniqueLayerC;
RadioState = MessageBufferLayerC.RadioState;
RadioChannel = MessageBufferLayerC;

UniqueLayerC.SubReceive -> CollisionAvoidanceLayerC;

components new RandomCollisionLayerC() as CollisionAvoidanceLayerC;
RandomCollisionConfig = CollisionAvoidanceLayerC.Config;
CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;
RadioAlarm[unique(UQ_RADIO_ALARM)] = CollisionAvoidanceLayerC;

components new SoftwareAckLayerC();
AckReceivedFlag = SoftwareAckLayerC.AckReceivedFlag;
RadioAlarm[unique(UQ_RADIO_ALARM)] = SoftwareAckLayerC.RadioAlarm;
MacPacketAcknowledgements = SoftwareAckLayerC.PacketAcknowledgements;
SoftwareAckConfig = SoftwareAckLayerC.Config;
SoftwareAckLayerC.SubSend -> CsmaLayerC;
SoftwareAckLayerC.SubReceive -> CsmaLayerC;

components new DummyLayerC() as CsmaLayerC;
RadioSend = CsmaLayerC;
RadioReceive = CsmaLayerC;
RadioCCA = CsmaLayerC;


}
