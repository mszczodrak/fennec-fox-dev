#include <ff_sensors.h>
configuration LightC {
  provides interface Read<struct ff_sensor_light>;
}

implementation {

  components LightP;
  Read = LightP;

#if defined(PLATFORM_TELOSB)
  components new HamamatsuS10871TsrC();
  LightP.HamamatsuTotal -> HamamatsuS10871TsrC; 

#elif defined(PLATFORM_Z1)
  components phidget_1127_0_driverC;
  LightP.SplitControl -> phidget_1127_0_driverC;
  LightP.SubRead -> phidget_1127_0_driverC.Read;
#else
  components VirtualLightSensorC;
  LightP.VirtualLight -> VirtualLightSensorC;
#endif




}
