#include "CC2420.h"

generic configuration cc2420xNewC(process_t process) {

//provides interface CC2420XDriverConfig;
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

RadioState = cc2420xNewImplC.RadioState;
RadioSend = cc2420xNewImplC.RadioSend;
RadioReceive = cc2420xNewImplC.RadioReceive;
RadioCCA = cc2420xNewImplC.RadioCCA;

RadioPacket = cc2420xNewImplC.RadioPacket;

PacketTransmitPower = cc2420xNewImplC.PacketTransmitPower;
PacketRSSI = cc2420xNewImplC.PacketRSSI;
//PacketTimeSyncOffset = cc2420xNewImplC.PacketTimeSyncOffset;
PacketLinkQuality = cc2420xNewImplC.PacketLinkQuality;

LinkPacketMetadata = RadioDriverLayerC;
LocalTimeRadio = RadioDriverLayerC;
Alarm = RadioDriverLayerC;


cc2420xNewImplC.CC2420XDriverConfig -> RadioP;

}
