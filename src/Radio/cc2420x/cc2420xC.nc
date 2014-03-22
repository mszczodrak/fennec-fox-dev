#include "CC2420.h"

generic configuration cc2420xC(process_t process) {

provides interface SplitControl;
uses interface cc2420xParams;

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

components new CC2420XRadioP() as RadioP;
SplitControl = RadioP;
SoftwareAckConfig = RadioP;
UniqueConfig = RadioP;
CsmaConfig = RadioP;
TrafficMonitorConfig = RadioP;
RandomCollisionConfig = RadioP;
SlottedCollisionConfig = RadioP;
ActiveMessageConfig = RadioP;
DummyConfig = RadioP;
LowPowerListeningConfig = RadioP;
cc2420xParams = RadioP;

Ieee154PacketLayer = RadioP;
RadioP.RadioAlarm -> cc2420xImplC.RadioAlarm[unique(UQ_RADIO_ALARM)];

components cc2420xImplC;
RadioResource = cc2420xImplC.Resource[process];
RadioAlarm = cc2420xImplC;
AckReceivedFlag = cc2420xImplC.PacketFlag[ACK_RECEIVED_FLAG];


RadioState = cc2420xImplC.RadioState;
RadioSend = cc2420xImplC.RadioSend;
RadioReceive = cc2420xImplC.RadioReceive;
RadioCCA = cc2420xImplC.RadioCCA;

RadioPacket = cc2420xImplC.RadioPacket;

PacketTransmitPower = cc2420xImplC.PacketTransmitPower;
PacketRSSI = cc2420xImplC.PacketRSSI;
PacketLinkQuality = cc2420xImplC.PacketLinkQuality;

PacketTimeStampRadio = cc2420xImplC.PacketTimeStampRadio;
PacketTimeStampMilli = cc2420xImplC.PacketTimeStampMilli;
PacketTimeStamp32khz = cc2420xImplC.PacketTimeStamp32khz;

RadioLinkPacketMetadata = cc2420xImplC;
LocalTimeRadio = cc2420xImplC;
cc2420xImplC.CC2420XDriverConfig -> RadioP;

}
