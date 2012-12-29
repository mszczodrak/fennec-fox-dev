
configuration phidget_1142_0_driverC {
  provides interface SensorCtrl;
  provides interface AdcSetup;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
}

implementation {
  components phidget_1142_0_driverP;
  AdcSetup = phidget_1142_0_driverP.AdcSetup;
  SensorCtrl = phidget_1142_0_driverP.SensorCtrl;
  Raw = phidget_1142_0_driverP.Raw;
  Calibrated = phidget_1142_0_driverP.Calibrated;

  components new phidget_adc_driverC();
  phidget_1142_0_driverP.AdcSensorCtrl -> phidget_adc_driverC.SensorCtrl;
  phidget_1142_0_driverP.SubAdcSetup -> phidget_adc_driverC.AdcSetup;
  phidget_1142_0_driverP.AdcSensorRaw -> phidget_adc_driverC.Raw;

  components new TimerMilliC() as Timer;
  phidget_1142_0_driverP.Timer -> Timer;
}

