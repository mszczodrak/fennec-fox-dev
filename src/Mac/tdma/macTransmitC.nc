#include "CC2420.h"
#include "IEEE802154.h"

configuration macTransmitC {
  provides interface MacTransmit;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;
  uses interface SplitControl as RadioControl;
  uses interface tdmaMacParams;

  provides interface SplitControl;
  provides interface Send;

  uses interface RadioPower;
  uses interface Resource as RadioResource;
}

implementation {

  components macTransmitP;
  MacTransmit = macTransmitP;
  EnergyIndicator = macTransmitP.EnergyIndicator;

  RadioStdControl = macTransmitP.RadioStdControl;
  RadioControl = macTransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  macTransmitP.BackoffTimer -> Alarm;

  RadioTransmit = macTransmitP.RadioTransmit;

  tdmaMacParams = macTransmitP.tdmaMacParams;

  components RandomC;
  macTransmitP.Random -> RandomC;

  SplitControl = macTransmitP;
  Send = macTransmitP;
  RadioPower = macTransmitP.RadioPower;
  RadioResource = macTransmitP.RadioResource;

  components new StateC();
  macTransmitP.SplitControlState -> StateC;
}
