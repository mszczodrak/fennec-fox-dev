#include <ff_sensors.h>
configuration ThinForceC {
  provides interface Read<struct ff_sensor_thinforce>;
}

implementation {

  components ThinForceP;
  Read = ThinForceP;

#if defined(PLATFORM_Z1)
  components phidget_1131_0_driverC;
  ThinForceP.SplitControl -> phidget_1131_0_driverC;
  ThinForceP.SubRead -> phidget_1131_0_driverC.Read;
#else
  components VirtualThinForceSensorC;
  ThinForceP.VirtualThinForce -> VirtualThinForceSensorC;
#endif

}
