#include "CC2420.h"

generic configuration cc2420xNewC(process_t process) {

provides interface SplitControl;
uses interface cc2420xNewParams;

provides interface ActiveMessageConfig;
provides interface UniqueConfig;
provides interface LowPowerListeningConfig;
provides interface RandomCollisionConfig;
provides interface SlottedCollisionConfig;
provides interface SoftwareAckConfig;
provides interface TrafficMonitorConfig;
provides interface CsmaConfig;
provides interface DummyConfig;

provides interface RadioState;
provides interface RadioReceive;
provides interface RadioSend;
provides interface RadioPacket;
provides interface RadioCCA;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface Resource as RadioResource;
provides interface RadioAlarm[uint8_t id];
provides interface LocalTime<TRadio> as LocalTimeRadio;
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketFlag as AckReceivedFlag;

uses interface Ieee154PacketLayer;

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

Ieee154PacketLayer = RadioP;
RadioP.RadioAlarm -> cc2420xNewImplC.RadioAlarm[unique(UQ_RADIO_ALARM)];

components cc2420xNewImplC;
RadioResource = cc2420xNewImplC.Resource[process];
RadioAlarm = cc2420xNewImplC;
AckReceivedFlag = cc2420xNewImplC.PacketFlag[ACK_RECEIVED_FLAG];

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
//Alarm = RadioDriverLayerC;


cc2420xNewImplC.CC2420XDriverConfig -> RadioP;

}
