configuration cc2420xImplC {
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

provides interface RadioCCA;
provides interface RadioPacket;

provides interface LinkPacketMetadata as RadioLinkPacketMetadata;

uses interface PacketTimeStamp<T32khz, uint32_t> as UnimplementedPacketTimeStamp32khz;

}

implementation {

components CC2420XRadioP as RadioP;
RadioP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

components new SimpleFcfsArbiterC("cc2420x");
Resource = SimpleFcfsArbiterC.Resource;

components new MetadataFlagsLayerC();
PacketFlag = MetadataFlagsLayerC;
MetadataFlagsLayerC.SubPacket -> RadioDriverLayerC;

components new TimeStampingLayerC();
TimeStampingLayerC.LocalTimeRadio -> RadioDriverLayerC;


TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
PacketTimeStampRadio = TimeStampingLayerC;
PacketTimeStampMilli = TimeStampingLayerC;
TimeStampingLayerC.TimeStampFlag -> MetadataFlagsLayerC.PacketFlag[TIME_STAMP_FLAG];

components new Ieee154PacketLayerC();
RadioPacket = Ieee154PacketLayerC.RadioPacket;
Ieee154PacketLayerC.SubPacket -> TimeStampingLayerC.RadioPacket;

RadioP.Ieee154PacketLayer -> Ieee154PacketLayerC.Ieee154PacketLayer;


components CC2420XDriverLayerC as RadioDriverLayerC;

components new RadioAlarmC();
RadioAlarm = RadioAlarmC;

RadioAlarmC.Alarm -> RadioDriverLayerC;

components cc2420xMultiC;
cc2420xMultiC.SubRadioReceive -> RadioDriverLayerC.RadioReceive;
cc2420xMultiC.SubRadioSend -> RadioDriverLayerC.RadioSend;
cc2420xMultiC.SubRadioState -> RadioDriverLayerC.RadioState;

RadioCCA = RadioDriverLayerC;

RadioDriverLayerC.Config -> RadioP.CC2420XDriverConfig;
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
