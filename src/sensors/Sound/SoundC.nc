#include <ff_sensors.h>
configuration SoundC {
  provides interface Read<struct ff_sensor_sound>;
}

implementation {

  components SoundP;
  Read = SoundP;

#if defined(PLATFORM_Z1)
  components phidget_1133_0_driverC;
  SoundP.SplitControl -> phidget_1133_0_driverC;
  SoundP.SubRead -> phidget_1133_0_driverC.Read;
#else
  components VirtualSoundSensorC;
  SoundP.VirtualSound -> VirtualSoundSensorC;
#endif

}
