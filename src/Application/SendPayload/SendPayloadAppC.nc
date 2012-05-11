generic configuration SendPayloadAppC() {
  provides interface Mgmt;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  components new SendPayloadAppP();
  Mgmt = SendPayloadAppP;
  NetworkCall = SendPayloadAppP;
  NetworkSignal = SendPayloadAppP;

  components LedsC;
  SendPayloadAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  SendPayloadAppP.Timer0 -> Timer0;

}
