#include <Fennec.h>

module LightP {
  provides interface Read<struct ff_sensor_light>;

#if defined(PLATFORM_TELOSB)
  uses interface Read<uint16_t> as HamamatsuTotal;
#elif defined(PLATFORM_Z1)
  uses interface SplitControl;
  uses interface Read<uint16_t> as SubRead;
#else
  uses interface Read<uint16_t> as VirtualLight;
#endif

}

implementation {

  struct ff_sensor_light smsg;

#if defined(PLATFORM_Z1)
  uint8_t status;
#endif

  command error_t Read.read() {
    smsg.light = 0;
    smsg.raw = 0;
#if defined(PLATFORM_TELOSB)
    return call HamamatsuTotal.read();
#elif defined(PLATFORM_Z1)
    if (status == S_STOPPED) {
      call SplitControl.start();
    }

    if (status == S_STARTED) {
      call SubRead.read();
    }
    return SUCCESS;
#else
    return call VirtualLight.read();
#endif
  }

#if defined(PLATFORM_TELOSB)
  event void HamamatsuTotal.readDone( error_t result, uint16_t val ) {
    smsg.light = val;
    smsg.raw = val;
    signal Read.readDone(result, smsg);
  }
#elif defined(PLATFORM_Z1)

  event void SplitControl.startDone(error_t err) {
    if (err == SUCCESS) {
      status = S_STARTED;
      call SubRead.read();
    } else {
      call SplitControl.start();
    }
  }

  event void SplitControl.stopDone(error_t err) {}

  event void SubRead.readDone( error_t result, uint16_t data) {
    smsg.light = data;
    smsg.raw = data;
    signal Read.readDone(result, smsg);
  }

#else
  event void VirtualLight.readDone( error_t result, uint16_t val ) {
    smsg.light = val;
    smsg.raw = val;
    signal Read.readDone(result, smsg);
  }
#endif

}
