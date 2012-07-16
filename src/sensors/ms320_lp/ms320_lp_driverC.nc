

configuration ms320_lp_driverC {
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
  provides interface Read<bool> as Occurence;
}

implementation {
  components ms320_lp_driverP;
  SensorCtrl = ms320_lp_driverP.SensorCtrl;
  Raw = ms320_lp_driverP.Raw;
  Calibrated = ms320_lp_driverP.Calibrated;
  Occurence = ms320_lp_driverP.Occurence;

  components HplMsp430GeneralIOC as GeneralIOC;
  components new Msp430GpioC() as MotionImpl;

  MotionImpl -> GeneralIOC.Port42;
  ms320_lp_driverP.MotionPin -> MotionImpl;

  components new TimerMilliC() as Timer;
  ms320_lp_driverP.Timer -> Timer;
}

