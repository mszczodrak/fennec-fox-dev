#include "CC2420.h"

generic configuration cc2420xNewC(process_t process) {

provides interface SplitControl;

provides interface SoftwareAckConfig;
provides interface UniqueConfig;
provides interface CsmaConfig;
provides interface TrafficMonitorConfig;
provides interface RandomCollisionConfig;
provides interface SlottedCollisionConfig;
provides interface ActiveMessageConfig;
provides interface DummyConfig;

provides interface LowPowerListeningConfig;

//provides interface PacketFlag<uint8_t>;

provides interface Resource;

provides interface RadioState;
provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;

provides interface LocalTime<TRadio> as LocalTimeRadio;
provides interface Alarm<TRadio, tradio_size>;

provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;

uses interface cc2420xNewParams;

}

implementation {

components new cc2420xNewP(process);

components CC2420XRadioP as RadioP;
SoftwareAckConfig = RadioP;
UniqueConfig = RadioP;
CsmaConfig = RadioP;
TrafficMonitorConfig = RadioP;
RandomCollisionConfig = RadioP;
SlottedCollisionConfig = RadioP;
ActiveMessageConfig = RadioP;
DummyConfig = RadioP;
LowPowerListeningConfig = RadioP;

components cc2420xNewImplC;
Resource = cc2420xNewImplC.Resource[process];

cc2420xNewParams = cc2420xNewP;
SplitControl = cc2420xNewP;

components CC2420XDriverLayerC as RadioDriverLayerC;

RadioState = cc2420xNewImplC.RadioState;
RadioSend = cc2420xNewImplC.RadioSend;
RadioReceive = cc2420xNewImplC.RadioReceive;
RadioCCA = cc2420xNewImplC.RadioCCA;

RadioPacket = cc2420xNewImplC.RadioPacket;

PacketTransmitPower = cc2420xNewImplC.PacketTransmitPower;
PacketRSSI = cc2420xNewImplC.PacketRSSI;
//PacketTimeSyncOffset = cc2420xNewImplC.PacketTimeSyncOffset;
PacketLinkQuality = cc2420xNewImplC.PacketLinkQuality;

PacketTimeStampRadio = cc2420xNewImplC.PacketTimeStampRadio;
PacketTimeStampMilli = cc2420xNewImplC.PacketTimeStampMilli;
PacketTimeStamp32khz = cc2420xNewImplC.PacketTimeStamp32khz;

RadioLinkPacketMetadata = RadioDriverLayerC;
LocalTimeRadio = RadioDriverLayerC;
Alarm = RadioDriverLayerC;


cc2420xNewImplC.CC2420XDriverConfig -> RadioP;

}
