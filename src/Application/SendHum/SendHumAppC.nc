configuration SendHumAppC {
   provides interface SplitControl;

  uses interface NetworkSend;
  uses interface NetworkReceive;
}

implementation {

  components SendHumAppP;
  SplitControl = SendHumAppP;
  NetworkSend = SendHumAppP;
  NetworkReceive = SendHumAppP;

  components LedsC;
  SendHumAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  SendHumAppP.Timer0 -> Timer0;

  components HumidityC;
  SendHumAppP.Humidity -> HumidityC;
}
