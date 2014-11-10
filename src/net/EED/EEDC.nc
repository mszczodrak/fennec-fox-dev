#include <Fennec.h>

generic configuration EEDC(process_t process) {
provides interface SplitControl;
provides interface AMSend;
provides interface Receive;
provides interface Receive as Snoop;
provides interface AMPacket;
provides interface Packet;
provides interface PacketAcknowledgements;

provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;

uses interface Param;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;
uses interface LinkPacketMetadata as SubLinkPacketMetadata;
uses interface LowPowerListening;
uses interface RadioChannel;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;

uses interface PacketTimeStamp<TMilli, uint32_t> as SubPacketTimeStampMilli;
uses interface PacketTimeStamp<T32khz, uint32_t> as SubPacketTimeStamp32khz;
}

implementation {

components new EEDP(process);
SplitControl = EEDP;
Param = EEDP;
AMSend = EEDP.AMSend;
Receive = EEDP.Receive;
Snoop = EEDP.Snoop;
AMPacket = EEDP.AMPacket;
Packet = EEDP.Packet;
PacketAcknowledgements = EEDP.PacketAcknowledgements;

SubAMSend = EEDP;
SubReceive = EEDP.SubReceive;
SubSnoop = EEDP.SubSnoop;
SubAMPacket = EEDP.SubAMPacket;
SubPacket = EEDP.SubPacket;
SubPacketAcknowledgements = EEDP.SubPacketAcknowledgements;
SubLinkPacketMetadata = EEDP.SubLinkPacketMetadata;
LowPowerListening = EEDP.LowPowerListening;
RadioChannel = EEDP.RadioChannel;

SubPacketTimeStampMilli = EEDP.SubPacketTimeStampMilli;
SubPacketTimeStamp32khz = EEDP.SubPacketTimeStamp32khz;

PacketLinkQuality = SubPacketLinkQuality;
PacketTransmitPower = SubPacketTransmitPower;
PacketRSSI = SubPacketRSSI;

components LedsC;
components new TimerMilliC() as SendTimerC;

components new MuxAlarm32khz32C();
EEDP.Alarm -> MuxAlarm32khz32C;

EEDP.Leds -> LedsC;
EEDP.SendTimer -> SendTimerC;

components SerialDbgsC;
EEDP.SerialDbgs -> SerialDbgsC.SerialDbgs[process];

components RandomC;
EEDP.Random -> RandomC;

}
