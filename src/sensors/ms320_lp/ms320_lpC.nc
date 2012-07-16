
configuration ms320_lpC {
  provides interface SplitControl;
  provides interface Read<uint16_t>;
}
implementation {
  
  components ms320_lpP;
  SplitControl = ms320_lpP.SplitControl;
  Read = ms320_lpP.Read;

  components new TimerMilliC() as PIRTimer;
  ms320_lpP.PIRTimer -> PIRTimer;

  components LedsC;
  ms320_lpP.Leds -> LedsC;

  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as PresenceImpl;

  PresenceImpl -> GeneralIOC.Port42; 
  ms320_lpP.PresencePin -> PresenceImpl;
  
}
