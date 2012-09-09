#include "IEEE802154.h"

configuration cc2420TransmitC {

  provides interface StdControl;
  provides interface MacTransmit;
  provides interface RadioBackoff;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;

  uses interface StdControl as RadioControl;
}

implementation {

  components cc2420TransmitP;
  StdControl = cc2420TransmitP.StdControl;
  MacTransmit = cc2420TransmitP;
  RadioBackoff = cc2420TransmitP;
  EnergyIndicator = cc2420TransmitP.EnergyIndicator;

  RadioStdControl = cc2420TransmitP.RadioStdControl;

  RadioControl = cc2420TransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  cc2420TransmitP.BackoffTimer -> Alarm;

  RadioTransmit = cc2420TransmitP.RadioTransmit;

}
