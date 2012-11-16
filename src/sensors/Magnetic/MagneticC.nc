#include <ff_sensors.h>
configuration MagneticC {
  provides interface Read<struct ff_sensor_magnetic>;
}

implementation {

  components MagneticP;
  Read = MagneticP;

#if defined(PLATFORM_Z1)
  components phidget_1108_0_driverC;
  MagneticP.SplitControl -> phidget_1108_0_driverC;
  MagneticP.SubRead -> phidget_1108_0_driverC.Read;
#else
  components VirtualMagneticSensorC;
  MagneticP.VirtualMagnetic -> VirtualMagneticSensorC;
#endif

}
