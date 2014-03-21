configuration nullRadioImplC {
provides interface Resource[uint8_t id];
provides interface PacketFlag[uint8_t bit];
provides interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
provides interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
provides interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LocalTime<TRadio> as LocalTimeRadio;
provides interface RadioAlarm[uint8_t id];

provides interface RadioState;
provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;

provides interface LinkPacketMetadata as RadioLinkPacketMetadata;

uses interface CC2420XDriverConfig;

uses interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;

}

implementation {

components new SimpleFcfsArbiterC("cc2420xNew");
Resource = SimpleFcfsArbiterC.Resource;

components new MetadataFlagsLayerC();
PacketFlag = MetadataFlagsLayerC;
MetadataFlagsLayerC.SubPacket -> RadioDriverLayerC;

components new TimeStampingLayerC();
TimeStampingLayerC.LocalTimeRadio -> RadioDriverLayerC;
RadioPacket = TimeStampingLayerC;


TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
PacketTimeStampRadio = TimeStampingLayerC;
PacketTimeStampMilli = TimeStampingLayerC;
TimeStampingLayerC.TimeStampFlag -> MetadataFlagsLayerC.PacketFlag[TIME_STAMP_FLAG];


components CC2420XDriverLayerC as RadioDriverLayerC;

components new RadioAlarmC();
RadioAlarm = RadioAlarmC;

RadioAlarmC.Alarm -> RadioDriverLayerC;

RadioState = RadioDriverLayerC;
RadioSend = RadioDriverLayerC;
RadioReceive = RadioDriverLayerC;
RadioCCA = RadioDriverLayerC;

CC2420XDriverConfig = RadioDriverLayerC.Config;
PacketTransmitPower = RadioDriverLayerC.PacketTransmitPower;
PacketLinkQuality = RadioDriverLayerC.PacketLinkQuality;
PacketRSSI = RadioDriverLayerC.PacketRSSI;
RadioLinkPacketMetadata = RadioDriverLayerC;
LocalTimeRadio = RadioDriverLayerC;

RadioDriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
RadioDriverLayerC.TransmitPowerFlag -> MetadataFlagsLayerC.PacketFlag[TRANSMIT_POWER_FLAG];
RadioDriverLayerC.RSSIFlag -> MetadataFlagsLayerC.PacketFlag[RSSI_FLAG];
RadioDriverLayerC.TimeSyncFlag -> MetadataFlagsLayerC.PacketFlag[TIME_SYNC_FLAG];
RadioDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];


PacketTimeStamp32khz = UnimplementedPacketTimeStamp32khz;

}
