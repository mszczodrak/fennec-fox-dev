#include "IEEE802154.h"

configuration cc2420TransmitC {

  provides interface StdControl;
  provides interface MacTransmit;
  provides interface RadioBackoff;

  provides interface StdControl as RecControl;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;

  uses interface StdControl as SubControl;
}

implementation {

  components cc2420TransmitP;
  StdControl = cc2420TransmitP.StdControl;
  MacTransmit = cc2420TransmitP;
  RadioBackoff = cc2420TransmitP;
  EnergyIndicator = cc2420TransmitP.EnergyIndicator;

  RadioStdControl = cc2420TransmitP.RadioStdControl;

  SubControl = cc2420TransmitP.SubControl;
  RecControl = cc2420TransmitP.RecControl;

  components new MuxAlarm32khz32C() as Alarm;
  cc2420TransmitP.BackoffTimer -> Alarm;

  RadioTransmit = cc2420TransmitP.RadioTransmit;

}
