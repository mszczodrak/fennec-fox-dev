
configuration tmp102_0_driverC {
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
  provides interface Read<bool> as Occurence;
}
implementation {
  components tmp102_0_driverP;
  SensorCtrl = tmp102_0_driverP.SensorCtrl;
  Raw = tmp102_0_driverP.Raw;
  Calibrated = tmp102_0_driverP.Calibrated;
  Occurence = tmp102_0_driverP.Occurence;

  components new Msp430I2C1C() as I2C;
  tmp102_0_driverP.Resource -> I2C;
  tmp102_0_driverP.ResourceRequested -> I2C;
  tmp102_0_driverP.I2CBasicAddr -> I2C;    

  components new BatteryC();
  tmp102_0_driverP.Battery -> BatteryC.Read;

  components new TimerMilliC() as Timer;
  tmp102_0_driverP.Timer -> Timer;

  components new TimerMilliC() as TimerSensor;
  tmp102_0_driverP.TimerSensor -> TimerSensor;
}
