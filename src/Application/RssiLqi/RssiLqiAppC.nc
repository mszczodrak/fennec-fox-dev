/*
 * Application: 
 * Author: 
 * Date: 
 */

generic configuration RssiLqiAppC() {
   provides interface SplitControl;

   uses interface NetworkCall;
   uses interface NetworkSignal;
}

implementation {

  components new RssiLqiAppP();
  SplitControl = RssiLqiAppP;
  NetworkCall = RssiLqiAppP;
  NetworkSignal = RssiLqiAppP;

  components LedsC;
  RssiLqiAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  RssiLqiAppP.Timer0 -> Timer0;

}
