#include <RadioConfig.h>

generic configuration nullMacC(process_t process) {

provides interface SplitControl;
provides interface AMSend as MacAMSend;
provides interface Receive as MacReceive;
provides interface Receive as MacSnoop;
provides interface AMPacket as MacAMPacket;
provides interface Packet as MacPacket;
provides interface PacketAcknowledgements as MacPacketAcknowledgements;
provides interface LinkPacketMetadata as MacLinkPacketMetadata;

uses interface nullMacParams;

/* new */
provides interface LowPowerListening;
provides interface RadioChannel;
provides interface PacketTimeStamp<TRadio, uint32_t> as MacPacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as MacPacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as MacPacketTimeStamp32khz;


/* to Radio */
provides interface Ieee154PacketLayer;

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

components new nullMacP(process);
nullMacParams = nullMacP.nullMacParams;
PacketTransmitPower = nullMacP.PacketTransmitPower;
PacketRSSI = nullMacP.PacketRSSI;
PacketLinkQuality = nullMacP.PacketLinkQuality;
TrafficMonitorConfig = nullMacP.TrafficMonitorConfig;
LowPowerListeningConfig = nullMacP.LowPowerListeningConfig;
CsmaConfig = nullMacP.CsmaConfig;
SlottedCollisionConfig = nullMacP.SlottedCollisionConfig;
RandomCollisionConfig = nullMacP.RandomCollisionConfig;
DummyConfig = nullMacP.DummyConfig;
UniqueConfig = nullMacP.UniqueConfig;
SoftwareAckConfig = nullMacP.SoftwareAckConfig;
LocalTimeRadio = nullMacP.LocalTimeRadio;

Ieee154PacketLayer = Ieee154PacketLayerC;
MacLinkPacketMetadata = RadioLinkPacketMetadata;
MacPacketTimeStampRadio = RadioPacketTimeStampRadio;
MacPacketTimeStampMilli = RadioPacketTimeStampMilli;
MacPacketTimeStamp32khz = RadioPacketTimeStamp32khz;

#define UQ_RADIO_ALARM		"UQ_CC2420X_RADIO_ALARM"
RadioAlarm[unique(UQ_RADIO_ALARM)] = nullMacP.RadioAlarm;

// -------- Active Message

components new ActiveMessageLayerC();
components new AutoResourceAcquireLayerC();
components new Ieee154PacketLayerC();
components new UniqueLayerC();
components new PacketLinkLayerC();

MacAMSend = ActiveMessageLayerC.AMSend[process];
MacReceive = ActiveMessageLayerC.Receive[process];
MacSnoop = ActiveMessageLayerC.Snoop[process];
MacAMPacket = ActiveMessageLayerC.AMPacket;
MacPacket = ActiveMessageLayerC;


ActiveMessageConfig = ActiveMessageLayerC.Config;
ActiveMessageLayerC.SubSend -> AutoResourceAcquireLayerC;
ActiveMessageLayerC.SubReceive -> nullMacP;
RadioPacket = ActiveMessageLayerC.SubPacket;

RadioResource = AutoResourceAcquireLayerC.Resource;
AutoResourceAcquireLayerC.SubSend -> nullMacP;

SplitControl = nullMacP;
LowPowerListening = nullMacP;

RadioChannel = nullMacP;

AckReceivedFlag = nullMacP.AckReceivedFlag;
MacPacketAcknowledgements = nullMacP.PacketAcknowledgements;

RadioCCA = nullMacP;

RadioSend = nullMacP.RadioSend;
RadioReceive = nullMacP.RadioReceive;
RadioState = nullMacP.RadioState;

}
