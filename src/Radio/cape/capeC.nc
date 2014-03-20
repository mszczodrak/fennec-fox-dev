//#include "CC2420.h"

#include <Fennec.h>

generic configuration capeC(process_t process) {

provides interface SplitControl;
uses interface capeParams;

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

components new capeP(process);

components capeRadioP as RadioP;
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
RadioP.RadioAlarm -> capeImplC.RadioAlarm[unique(UQ_RADIO_ALARM)];

components capeImplC;
RadioResource = capeImplC.Resource[process];
RadioAlarm = capeImplC;
AckReceivedFlag = capeImplC.PacketFlag[ACK_RECEIVED_FLAG];

capeParams = capeP;
SplitControl = capeP;

RadioState = capeImplC.RadioState;
RadioSend = capeImplC.RadioSend;
RadioReceive = capeImplC.RadioReceive;
RadioCCA = capeImplC.RadioCCA;

RadioPacket = capeImplC.RadioPacket;

PacketTransmitPower = capeImplC.PacketTransmitPower;
PacketRSSI = capeImplC.PacketRSSI;
PacketLinkQuality = capeImplC.PacketLinkQuality;

PacketTimeStampRadio = capeImplC.PacketTimeStampRadio;
PacketTimeStampMilli = capeImplC.PacketTimeStampMilli;
PacketTimeStamp32khz = capeImplC.PacketTimeStamp32khz;

RadioLinkPacketMetadata = capeImplC;
LocalTimeRadio = capeImplC;
capeImplC.capeDriverConfig -> RadioP;

}
