
generic configuration nullRadioC(process_t process) {

provides interface SplitControl;
uses interface nullRadioParams;

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

components new nullRadioP(process);

components nullRadioConfigP as RadioP;
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
RadioP.RadioAlarm -> nullRadioImplC.RadioAlarm[unique(UQ_RADIO_ALARM)];

components nullRadioImplC;
RadioResource = nullRadioImplC.Resource[process];
RadioAlarm = nullRadioImplC;
AckReceivedFlag = nullRadioImplC.PacketFlag[ACK_RECEIVED_FLAG];

nullRadioParams = nullRadioP;
SplitControl = nullRadioP;

RadioState = nullRadioImplC.RadioState;
RadioSend = nullRadioImplC.RadioSend;
RadioReceive = nullRadioImplC.RadioReceive;
RadioCCA = nullRadioImplC.RadioCCA;

RadioPacket = nullRadioImplC.RadioPacket;

PacketTransmitPower = nullRadioImplC.PacketTransmitPower;
PacketRSSI = nullRadioImplC.PacketRSSI;
PacketLinkQuality = nullRadioImplC.PacketLinkQuality;

PacketTimeStampRadio = nullRadioImplC.PacketTimeStampRadio;
PacketTimeStampMilli = nullRadioImplC.PacketTimeStampMilli;
PacketTimeStamp32khz = nullRadioImplC.PacketTimeStamp32khz;

RadioLinkPacketMetadata = nullRadioImplC;
LocalTimeRadio = nullRadioImplC;
nullRadioImplC.nullRadioConfig -> RadioP;

}
