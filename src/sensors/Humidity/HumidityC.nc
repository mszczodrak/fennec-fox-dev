#include <ff_sensors.h>
configuration HumidityC {
  provides interface Read<struct ff_sensor_humidity>;
}

implementation {

  components HumidityP;
  Read = HumidityP;

#if defined(PLATFORM_TELOSB)

  components new SensirionSht11C();
  HumidityP.TelosBHum -> SensirionSht11C.Humidity;

#elif defined(PLATFORM_Z1)



#else
  components VirtualHumiditySensorC;
  HumidityP.VirtualHumidity -> VirtualHumiditySensorC;
#endif

}
