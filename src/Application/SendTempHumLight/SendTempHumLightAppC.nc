generic configuration SendTempHumLightAppC(uint16_t delay, uint16_t root) {
  provides interface Mgmt;
  provides interface Module;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  components new SendTempHumLightAppP(delay, root);
  Mgmt = SendTempHumLightAppP;
  Module = SendTempHumLightAppP;
  NetworkCall = SendTempHumLightAppP;
  NetworkSignal = SendTempHumLightAppP;

  components LedsC;
  SendTempHumLightAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  SendTempHumLightAppP.Timer0 -> Timer0;

  components TemperatureC;
  SendTempHumLightAppP.Temperature -> TemperatureC;

  components HumidityC;
  SendTempHumLightAppP.Humidity -> HumidityC;

  components LightC;
  SendTempHumLightAppP.Light -> LightC;

  components RawSerialC;
  SendTempHumLightAppP.Serial -> RawSerialC;
}
