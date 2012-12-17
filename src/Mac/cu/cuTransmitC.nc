#include "CC2420.h"
#include "IEEE802154.h"

configuration cuTransmitC {
  provides interface cuTransmit;
  provides interface SplitControl;
  provides interface Send;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioBuffer;
  uses interface RadioSend;
  uses interface RadioPacket;
  uses interface SplitControl as RadioControl;
  uses interface cuMacParams;
  uses interface RadioPower;
  uses interface Resource as RadioResource;
}

implementation {

  components cuTransmitP;
  cuTransmit = cuTransmitP;
  EnergyIndicator = cuTransmitP.EnergyIndicator;

  RadioStdControl = cuTransmitP.RadioStdControl;
  RadioControl = cuTransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  cuTransmitP.BackoffTimer -> Alarm;

  RadioBuffer = cuTransmitP.RadioBuffer;
  RadioSend = cuTransmitP.RadioSend;
  RadioPacket = cuTransmitP.RadioPacket;

  cuMacParams = cuTransmitP.cuMacParams;

  components RandomC;
  cuTransmitP.Random -> RandomC;

  SplitControl = cuTransmitP;
  Send = cuTransmitP;
  RadioPower = cuTransmitP.RadioPower;
  RadioResource = cuTransmitP.RadioResource;

  components new StateC();
  cuTransmitP.SplitControlState -> StateC;
}
