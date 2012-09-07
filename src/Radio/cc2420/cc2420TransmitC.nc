#include "IEEE802154.h"

configuration cc2420TransmitC {

  provides interface Receive;

  provides {
    interface StdControl;
    interface RadioTransmit;
    interface RadioBackoff;
  }

  uses interface cc2420RadioParams;
  uses interface Receive as SubReceive;
  uses interface ReceiveIndicator as EnergyIndicator;

  uses interface StdControl as RadioStdControl;
}

implementation {

  components cc2420TransmitP;
  StdControl = cc2420TransmitP;
  RadioTransmit = cc2420TransmitP;
  RadioBackoff = cc2420TransmitP;
  EnergyIndicator = cc2420TransmitP.EnergyIndicator;

  RadioStdControl = cc2420TransmitP.RadioStdControl;

  cc2420RadioParams = cc2420TransmitP.cc2420RadioParams;

  components new MuxAlarm32khz32C() as Alarm;
  cc2420TransmitP.BackoffTimer -> Alarm;

  Receive = cc2420TransmitP.Receive;
  SubReceive = cc2420TransmitP.SubReceive;

  components cc2420DriverC;
  cc2420TransmitP.RadioInter -> cc2420DriverC;

}
