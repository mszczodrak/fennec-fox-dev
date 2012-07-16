

configuration phidget_1127_0_driverC {
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
  provides interface Read<bool> as Occurence;
}

implementation {
  components phidget_1127_0_driverP;
  SensorCtrl = phidget_1127_0_driverP.SensorCtrl;
  Raw = phidget_1127_0_driverP.Raw;
  Calibrated = phidget_1127_0_driverP.Calibrated;
  Occurence = phidget_1127_0_driverP.Occurence;

  components new Msp430Adc12ClientC();
  phidget_1127_0_driverP.Msp430Adc12SingleChannel -> Msp430Adc12ClientC;
  phidget_1127_0_driverP.Resource -> Msp430Adc12ClientC;

  components new BatteryC();
  phidget_1127_0_driverP.Battery -> BatteryC.Read;

  components new TimerMilliC() as Timer;
  phidget_1127_0_driverP.Timer -> Timer;
}

