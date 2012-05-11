#include <Fennec.h>
#include <ff_sensors.h>

module HumidityP {
  provides interface Read<struct ff_sensor_humidity>;

#ifdef _H_msp430hardware_h
  uses interface Read<uint16_t> as TelosBHum;
#else
  uses interface Read<uint16_t> as VirtualHumidity;
#endif

}

implementation {

  struct ff_sensor_humidity smsg;

  command error_t Read.read() {
    smsg.humidity = 0;
    smsg.raw = 0;
#if defined(PLATFORM_TELOSB)
    return call TelosBHum.read();

#elif defined(PLATFORM_Z1)

#else
    return call VirtualHumidity.read();
#endif
    return FAIL;
  }

#if defined(PLATFORM_TELOSB)
  event void TelosBHum.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      smsg.humidity = -4 + 0.0405*val + (-2.8 * 1e-6)*(val)*(val);
      smsg.raw = val;
      signal Read.readDone(SUCCESS, smsg);
    } else {
      signal Read.readDone(FAIL, smsg);
    }
  }
#else
  event void VirtualHumidity.readDone( error_t result, uint16_t val ) {
    smsg.humidity = val;
    smsg.raw = val;
    signal Read.readDone(FAIL, smsg);
  }
#endif

}
