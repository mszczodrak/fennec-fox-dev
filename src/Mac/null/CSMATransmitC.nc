#include "CC2420.h"
#include "IEEE802154.h"

configuration CSMATransmitC {
  provides interface CSMATransmit;
  provides interface SplitControl;
  provides interface Send;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioTransmit;
  uses interface SplitControl as RadioControl;
  uses interface nullMacParams;
}

implementation {

  components CSMATransmitP;
  CSMATransmit = CSMATransmitP;
  EnergyIndicator = CSMATransmitP.EnergyIndicator;

  RadioStdControl = CSMATransmitP.RadioStdControl;
  RadioControl = CSMATransmitP.RadioControl;

  RadioTransmit = CSMATransmitP.RadioTransmit;

  nullMacParams = CSMATransmitP.nullMacParams;

  SplitControl = CSMATransmitP;
  Send = CSMATransmitP;

  components new StateC();
  CSMATransmitP.SplitControlState -> StateC;
}
