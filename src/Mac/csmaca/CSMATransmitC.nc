#include "CC2420.h"
#include "IEEE802154.h"

configuration CSMATransmitC {
  provides interface MacTransmit;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;
  uses interface SplitControl as RadioControl;
  uses interface csmacaMacParams;

  provides interface SplitControl;
  provides interface Send;

  uses interface RadioPower;
  uses interface Resource as RadioResource;
}

implementation {

  components CSMATransmitP;
  MacTransmit = CSMATransmitP;
  EnergyIndicator = CSMATransmitP.EnergyIndicator;

  RadioStdControl = CSMATransmitP.RadioStdControl;
  RadioControl = CSMATransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  CSMATransmitP.BackoffTimer -> Alarm;

  RadioTransmit = CSMATransmitP.RadioTransmit;

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
