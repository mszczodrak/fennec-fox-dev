#include <ff_sensors.h>
configuration TemperatureC {
  provides interface Read<struct ff_sensor_data>;
}

implementation {

  components TemperatureP;
  Read = TemperatureP;

#if defined(PLATFORM_TELOSB)
  components new SensirionSht11C();
  TemperatureP.SensirionSht11Temp -> SensirionSht11C.Temperature;
#elif defined(PLATFORM_Z1)
  components new SimpleTMP102C();
  TemperatureP.SimpleTMP102 -> SimpleTMP102C;
#else
  components VirtualTemperatureSensorC;
  TemperatureP.VirtualTemperature -> VirtualTemperatureSensorC;
#endif

}
