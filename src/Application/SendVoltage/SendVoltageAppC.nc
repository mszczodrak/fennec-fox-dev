configuration SendVoltageAppC {
  provides interface SplitControl;

  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  components SendVoltageAppP;
  SplitControl = SendVoltageAppP;
  NetworkCall = SendVoltageAppP;
  NetworkSignal = SendVoltageAppP;

  components LedsC;
  SendVoltageAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  SendVoltageAppP.Timer0 -> Timer0;

  components VoltageC;
  SendVoltageAppP.Voltage -> VoltageC;

}
