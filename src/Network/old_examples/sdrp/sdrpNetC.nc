#include <Fennec.h>

configuration sdrpNetC {
  provides interface SplitControl;
  provides interface NetworkSend;
  provides interface NetworkReceive;

  uses interface MacCall;
  uses interface MacSignal;
}

implementation {

  components sdrpNetP;
  SplitControl = sdrpNetP;
  NetworkSend = sdrpNetP;
  NetworkReceive = sdrpNetP;
  MacCall = sdrpNetP;
  MacSignal = sdrpNetP;

  components new TimerMilliC() as Timer0;
  sdrpNetP.Timer0 -> Timer0;

  components RandomC;
  sdrpNetP.Random -> RandomC;

  components FennecFunctionsC;
  sdrpNetP.FennecStatus -> FennecFunctionsC;

  components LedsC;
  sdrpNetP.Leds -> LedsC;
}
