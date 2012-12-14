#include "CC2420.h"
#include "IEEE802154.h"

configuration TDMATransmitC {
  provides interface TDMATransmit;
  provides interface SplitControl;
  provides interface Send;

  uses interface ReceiveIndicator as EnergyIndicator;
  uses interface StdControl as RadioStdControl;
  uses interface RadioBuffer;
  uses interface RadioSend;
  uses interface SplitControl as RadioControl;
  uses interface tdmaMacParams;
  uses interface RadioPower;
  uses interface Resource as RadioResource;
}

implementation {

  components TDMATransmitP;
  TDMATransmit = TDMATransmitP;
  EnergyIndicator = TDMATransmitP.EnergyIndicator;

  RadioStdControl = TDMATransmitP.RadioStdControl;
  RadioControl = TDMATransmitP.RadioControl;

  components new MuxAlarm32khz32C() as Alarm;
  TDMATransmitP.BackoffTimer -> Alarm;

  RadioBuffer = TDMATransmitP.RadioBuffer;
  RadioSend = TDMATransmitP.RadioSend;

  tdmaMacParams = TDMATransmitP.tdmaMacParams;

  components RandomC;
  TDMATransmitP.Random -> RandomC;

  SplitControl = TDMATransmitP;
  Send = TDMATransmitP;
  RadioPower = TDMATransmitP.RadioPower;
  RadioResource = TDMATransmitP.RadioResource;

  components new StateC();
  TDMATransmitP.SplitControlState -> StateC;
}
