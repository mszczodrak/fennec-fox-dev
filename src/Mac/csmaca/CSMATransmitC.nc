#include "IEEE802154.h"

configuration CSMATransmitC {

provides interface CSMATransmit;
provides interface SplitControl;
provides interface Send;

uses interface StdControl as RadioStdControl;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface RadioPacket;
uses interface csmacaMacParams;
uses interface Resource as RadioResource;
uses interface RadioCCA;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketTimeSyncOffset;
uses interface PacketField<uint8_t> as PacketLinkQuality;

uses interface RadioState;

}

implementation {

components CSMATransmitP;
CSMATransmit = CSMATransmitP;
RadioCCA = CSMATransmitP.RadioCCA;
RadioState = CSMATransmitP.RadioState;

RadioStdControl = CSMATransmitP.RadioStdControl;

components new MuxAlarm32khz32C() as Alarm;
CSMATransmitP.BackoffTimer -> Alarm;

RadioBuffer = CSMATransmitP.RadioBuffer;
RadioSend = CSMATransmitP.RadioSend;
RadioPacket = CSMATransmitP.RadioPacket;

csmacaMacParams = CSMATransmitP.csmacaMacParams;

components RandomC;
CSMATransmitP.Random -> RandomC;

SplitControl = CSMATransmitP;
Send = CSMATransmitP;
RadioResource = CSMATransmitP.RadioResource;

components new StateC();
CSMATransmitP.SplitControlState -> StateC;

PacketTransmitPower = CSMATransmitP.PacketTransmitPower;
PacketRSSI = CSMATransmitP.PacketRSSI;
PacketTimeSyncOffset = CSMATransmitP.PacketTimeSyncOffset;
PacketLinkQuality = CSMATransmitP.PacketLinkQuality;

}
