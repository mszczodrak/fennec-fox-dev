#include "CC2420.h"
#include "IEEE802154.h"

configuration macTransmitC {

  provides interface StdControl;
  provides interface MacTransmit;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;
  uses interface StdControl as RadioControl;
  uses interface csmacaMacParams;

  provides interface SplitControl;
  provides interface Send;

  uses interface RadioPower;
  uses interface Resource as RadioResource;

//  uses interface StdControl as SubControl;
//  uses interface MacTransmit;

}

implementation {

  components macTransmitP;
  StdControl = macTransmitP.StdControl;
  MacTransmit = macTransmitP;
  EnergyIndicator = macTransmitP.EnergyIndicator;

  RadioStdControl = macTransmitP.RadioStdControl;

  RadioControl = macTransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  macTransmitP.BackoffTimer -> Alarm;

  RadioTransmit = macTransmitP.RadioTransmit;

  csmacaMacParams = macTransmitP.csmacaMacParams;

  components RandomC;
  macTransmitP.Random -> RandomC;



  SplitControl = macTransmitP;
  Send = macTransmitP;
  RadioPower = macTransmitP.RadioPower;
  RadioResource = macTransmitP.RadioResource;

  components new StateC();
  macTransmitP.SplitControlState -> StateC;


}
