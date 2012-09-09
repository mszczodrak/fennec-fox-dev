
#include "CC2420.h"
#include "IEEE802154.h"

configuration CsmaC {

  provides interface SplitControl;
  provides interface Send;

  uses interface RadioPower;
  uses interface Resource as RadioResource;

  uses interface StdControl as SubControl;
  uses interface csmacaMacParams;
  uses interface MacTransmit;
}

implementation {

  components CsmaP;
  SplitControl = CsmaP;
  Send = CsmaP;
  RadioPower = CsmaP.RadioPower;
  RadioResource = CsmaP.RadioResource;

  csmacaMacParams = CsmaP.csmacaMacParams;

  SubControl = CsmaP.SubControl;
  MacTransmit = CsmaP.MacTransmit;
  
  components new StateC();
  CsmaP.SplitControlState -> StateC;
  
}
