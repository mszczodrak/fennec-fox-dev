#include "IEEE802154.h"

configuration CSMATransmitC {

provides interface CSMATransmit;
provides interface SplitControl;
provides interface Send;

uses interface ReceiveIndicator as EnergyIndicator;
uses interface StdControl as RadioStdControl;
uses interface RadioBuffer;
uses interface RadioSend;
uses interface RadioPacket;
uses interface SplitControl as RadioControl;
uses interface csmacaMacParams;
uses interface RadioPower;
uses interface Resource as RadioResource;
uses interface RadioCCA;
}

implementation {

components CSMATransmitP;
CSMATransmit = CSMATransmitP;
EnergyIndicator = CSMATransmitP.EnergyIndicator;
RadioCCA = CSMATransmitP.RadioCCA;

RadioStdControl = CSMATransmitP.RadioStdControl;
RadioControl = CSMATransmitP.RadioControl;

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
RadioPower = CSMATransmitP.RadioPower;
RadioResource = CSMATransmitP.RadioResource;

components new StateC();
CSMATransmitP.SplitControlState -> StateC;
}
