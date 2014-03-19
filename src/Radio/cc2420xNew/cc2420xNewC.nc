generic configuration cc2420xNewC(process_t process) {

provides interface CC2420XDriverConfig;
provides interface SoftwareAckConfig;
provides interface UniqueConfig;
provides interface CsmaConfig;
provides interface TrafficMonitorConfig;
provides interface RandomCollisionConfig;
provides interface SlottedCollisionConfig;
provides interface ActiveMessageConfig;
provides interface DummyConfig;

#ifdef LOW_POWER_LISTENING
provides interface LowPowerListeningConfig;
#endif

provides interface Resource;

provides interface RadioState;
provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LinkPacketMetadata;

provides interface LocalTime<TRadio> as LocalTimeRadio;
provides interface Alarm<TRadio, tradio_size>;

uses interface cc2420xNewParams;

}

implementation {


components CC2420XRadioP as RadioP;
CC2420XDriverConfig = RadioP;
SoftwareAckConfig = RadioP;
UniqueConfig = RadioP;
CsmaConfig = RadioP;
TrafficMonitorConfig = RadioP;
RandomCollisionConfig = RadioP;
SlottedCollisionConfig = RadioP;
ActiveMessageConfig = RadioP;
DummyConfig = RadioP;

#ifdef LOW_POWER_LISTENING
LowPowerListeningConfig = RadioP;
#endif

components cc2420xNewImplC;
Resource = cc2420xNewImplC.Resource[process];


components CC2420XDriverLayerC as RadioDriverLayerC;

RadioState = RadioDriverLayerC;
RadioSend = RadioDriverLayerC;
RadioReceive = RadioDriverLayerC;
RadioCCA = RadioDriverLayerC;
RadioPacket = RadioDriverLayerC;


PacketTransmitPower = RadioDriverLayerC.PacketTransmitPower;
PacketRSSI = RadioDriverLayerC.PacketRSSI;
PacketTimeSyncOffset = RadioDriverLayerC.PacketTimeSyncOffset;
PacketLinkQuality = RadioDriverLayerC.PacketLinkQuality;

LinkPacketMetadata = RadioDriverLayerC;
LocalTimeRadio = RadioDriverLayerC;
Alarm = RadioDriverLayerC;


RadioDriverLayerC.Config -> RadioP;
/*
RadioDriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
*/

/*
RadioDriverLayerC.TransmitPowerFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
RadioDriverLayerC.RSSIFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
RadioDriverLayerC.TimeSyncFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
RadioDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
*/




}
