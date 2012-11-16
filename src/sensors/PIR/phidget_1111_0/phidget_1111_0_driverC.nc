

configuration phidget_1111_0_driverC {
  provides interface SplitControl;
  provides interface Read<uint16_t>;
}

implementation {
  components phidget_1111_0_driverP;
  SplitControl = phidget_1111_0_driverP;
  Read = phidget_1111_0_driverP;

  //components new Msp430Adc12ClientC() as Adc;
  //components new AdcReadClientC() as Adc;

  components new BatteryC();
  phidget_1111_0_driverP.Battery -> BatteryC.Read;

  components new AdcReadClientC();
  phidget_1111_0_driverP.Motion -> AdcReadClientC;

  components phidget_1111_0_confP;
  AdcReadClientC.AdcConfigure -> phidget_1111_0_confP;

}

