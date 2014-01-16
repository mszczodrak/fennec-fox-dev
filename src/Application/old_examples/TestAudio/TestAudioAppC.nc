/*
 * Application: 
 * Author: 
 * Date: 
 */

generic configuration TestAudioAppC() {
   provides interface Mgmt;
   provides interface Module;
   uses interface NetworkCall;
   uses interface NetworkSignal;
}

implementation {

#ifdef PXA27X_HARDWARE_H
  components new TestAudioAppP();
  Mgmt = TestAudioAppP;
  Module = TestAudioAppP;
  NetworkCall = TestAudioAppP;
  NetworkSignal = TestAudioAppP;

  components LedsC;
  TestAudioAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  TestAudioAppP.Timer0 -> Timer0;

  components AudioC;
  TestAudioAppP.Audio -> AudioC.Audio;

#else

  components new DummyAppC();
  Mgmt = DummyAppC;
  Module = DummyAppC;
  NetworkCall = DummyAppC;
  NetworkSignal = DummyAppC;

#endif



}
