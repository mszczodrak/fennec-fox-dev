#include <RadioConfig.h>
#include <nullRadioDriverLayer.h>

configuration nullRadioDriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;
		interface LinkPacketMetadata;

		interface LocalTime<TRadio> as LocalTimeRadio;
		interface Alarm<TRadio, tradio_size>;
	}

	uses
	{
		interface nullRadioDriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;

		interface PacketFlag as TransmitPowerFlag;
		interface PacketFlag as RSSIFlag;
		interface PacketFlag as TimeSyncFlag;
		interface RadioAlarm;
	}
}

implementation
{
	components nullRadioDriverLayerP as DriverLayerP,
		BusyWaitMicroC,
		TaskletC,
		MainC,
		HplnullRadioC as HplC;

	MainC.SoftwareInit -> DriverLayerP.SoftwareInit;
	MainC.SoftwareInit -> HplC.Init;

	RadioState = DriverLayerP;
	RadioSend = DriverLayerP;
	RadioReceive = DriverLayerP;
	RadioCCA = DriverLayerP;
	RadioPacket = DriverLayerP;

	LocalTimeRadio = HplC;
	Config = DriverLayerP;

	PacketTransmitPower = DriverLayerP.PacketTransmitPower;
	TransmitPowerFlag = DriverLayerP.TransmitPowerFlag;

	PacketRSSI = DriverLayerP.PacketRSSI;
	RSSIFlag = DriverLayerP.RSSIFlag;

	PacketTimeSyncOffset = DriverLayerP.PacketTimeSyncOffset;
	TimeSyncFlag = DriverLayerP.TimeSyncFlag;

	PacketLinkQuality = DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = DriverLayerP.PacketTimeStamp;
	LinkPacketMetadata = DriverLayerP;

	Alarm = HplC.Alarm;
	RadioAlarm = DriverLayerP.RadioAlarm;

	DriverLayerP.Tasklet -> TaskletC;
	DriverLayerP.BusyWait -> BusyWaitMicroC;

	DriverLayerP.LocalTime-> HplC.LocalTimeRadio;

	components LedsC;
	DriverLayerP.Leds -> LedsC;
}
