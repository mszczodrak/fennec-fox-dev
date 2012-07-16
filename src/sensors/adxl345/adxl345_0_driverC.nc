#include "adxl345_0_driver.h"

configuration adxl345_0_driverC {
  provides interface SensorCtrl;
  provides interface Read<adxl345_t> as Raw;
  provides interface Read<adxl345_t> as Calibrated;
  provides interface Read<bool> as Occurence;
}

implementation {
  components adxl345_0_driverP;
  SensorCtrl = adxl345_0_driverP.SensorCtrl;
  Raw = adxl345_0_driverP.Raw;
  Calibrated = adxl345_0_driverP.Calibrated;
  Occurence = adxl345_0_driverP.Occurence;

  components new Msp430I2C1C() as I2C;
  adxl345_0_driverP.Resource -> I2C;
  adxl345_0_driverP.ResourceRequested -> I2C;
  adxl345_0_driverP.I2CBasicAddr -> I2C;

  components new BatteryC();
  adxl345_0_driverP.Battery -> BatteryC.Read;

  components new TimerMilliC() as Timer;
  adxl345_0_driverP.Timer -> Timer;
}

