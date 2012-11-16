/*
 * author: Marcin Szczodrak
 * date: 12/8/2009
 */

#include <ff_sensors.h>
#include <Fennec.h>

module TemperatureP {
  provides interface Read<struct ff_sensor_temperature>;

#if defined(PLATFORM_TELOSB)
  uses interface Read<uint16_t> as SensirionSht11Temp;
#elif defined(PLATFORM_Z1)
  uses interface Read<uint16_t> as SimpleTMP102;
#else
  uses interface Read<uint16_t> as VirtualTemperature;
#endif

}

implementation {

  struct ff_sensor_temperature smsg;

  command error_t Read.read() {
    smsg.temp = 0;
    smsg.raw = 0;

#if defined(PLATFORM_TELOSB )
    return call SensirionSht11Temp.read();
#elif defined(PLATFORM_Z1)
    return call SimpleTMP102.read();
#else
    return call VirtualTemperature.read();
#endif
    return FAIL;
  }

#if defined(PLATFORM_TELOSB )
  event void SensirionSht11Temp.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      smsg.temp = -39.60 + val * 0.01;
      smsg.raw = val;
      signal Read.readDone(result, smsg);
    } else {
      signal Read.readDone(result, smsg);
    }
  }
#elif defined(PLATFORM_Z1)
  event void SimpleTMP102.readDone( error_t result, uint16_t val ) {
    smsg.temp = val * 0.0625;
    smsg.raw = val;
    signal Read.readDone(result, smsg);
  }
#else
  event void VirtualTemperature.readDone( error_t result, uint16_t val) {
    smsg.temp = val;
    smsg.raw = val;
    signal Read.readDone(result, smsg);
  }
#endif

}
