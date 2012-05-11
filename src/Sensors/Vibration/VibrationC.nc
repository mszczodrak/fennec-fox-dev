#include <ff_sensors.h>
configuration VibrationC {
  provides interface Read<struct ff_sensor_vibration>;
}

implementation {

  components VibrationP;
  Read = VibrationP;

#if defined(PLATFORM_Z1)
  components phidget_1104_0_driverC;
  VibrationP.SplitControl -> phidget_1104_0_driverC;
  VibrationP.SubRead -> phidget_1104_0_driverC.Read;
#else
  components VirtualVibrationSensorC;
  VibrationP.VirtualVibration -> VirtualVibrationSensorC;
#endif

}
