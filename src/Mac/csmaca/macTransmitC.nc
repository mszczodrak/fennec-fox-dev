#include "IEEE802154.h"

configuration macTransmitC {

  provides interface StdControl;
  provides interface MacTransmit;
  provides interface RadioBackoff;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;

  uses interface StdControl as RadioControl;
}

implementation {

  components macTransmitP;
  StdControl = macTransmitP.StdControl;
  MacTransmit = macTransmitP;
  RadioBackoff = macTransmitP;
  EnergyIndicator = macTransmitP.EnergyIndicator;

  RadioStdControl = macTransmitP.RadioStdControl;

  RadioControl = macTransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  macTransmitP.BackoffTimer -> Alarm;

  RadioTransmit = macTransmitP.RadioTransmit;

}
