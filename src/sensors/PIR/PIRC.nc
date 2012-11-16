#include <ff_sensors.h>
configuration PIRC {
  provides interface Read<struct ff_sensor_pir>;
}

implementation {

  components PIRP;
  Read = PIRP;

#if defined(PLATFORM_Z1)
//  components ms320_lpC;
//  PIRP.SplitControl -> ms320_lpC;
//  PIRP.SubRead -> ms320_lpC.Read;

  components phidget_1111_0_driverC;
  PIRP.SplitControl -> phidget_1111_0_driverC;
  PIRP.SubRead -> phidget_1111_0_driverC.Read;
#else
  components VirtualPIRSensorC;
  PIRP.VirtualPIR -> VirtualPIRSensorC;
#endif

}
