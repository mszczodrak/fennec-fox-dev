configuration simplePreloadACKOKMacC{
  provides interface SplitControl;
  provides interface MacSend;
  provides interface MacReceive;
  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {
  components simplePreloadACKOKMacP;
  SplitControl = simplePreloadACKOKMacP;
  MacSend = simplePreloadACKOKMacP;
  MacReceive = simplePreloadACKOKMacP;
  RadioCall = simplePreloadACKOKMacP;
  RadioSignal = simplePreloadACKOKMacP;

  components new TimerMilliC() as Timer0;
  simplePreloadACKOKMacP.Timer0 -> Timer0;

}

