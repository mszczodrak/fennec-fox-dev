

configuration phidget_1127_0_driverC {
  provides interface SplitControl;
  provides interface Read<uint16_t>;
}

implementation {
  components phidget_1127_0_driverP;
  SplitControl = phidget_1127_0_driverP;
  Read = phidget_1127_0_driverP;

  //components new Msp430Adc12ClientC() as Adc;
  //components new AdcReadClientC() as Adc;

  components new BatteryC();
  phidget_1127_0_driverP.Battery -> BatteryC.Read;

  components new AdcReadClientC();
  phidget_1127_0_driverP.Light -> AdcReadClientC;

  components phidget_1127_0_confP;
  AdcReadClientC.AdcConfigure -> phidget_1127_0_confP;

}

