#include <Fennec.h>
#include <ff_sensors.h>

module VibrationP {
  provides interface Read<struct ff_sensor_vibration>;

#if defined(PLATFORM_Z1)
  uses interface SplitControl;
  uses interface Read<uint16_t> as SubRead;
#else
  uses interface Read<uint16_t> as VirtualVibration;
#endif

}

implementation {

  uint8_t status = S_STOPPED;
  struct ff_sensor_vibration smsg;
  
  command error_t Read.read() {
    smsg.vibration = 0;
    smsg.raw = 0;
#if defined(PLATFORM_Z1)
    if (status == S_STOPPED) {
      call SplitControl.start();
    }

    if (status == S_STARTED) {
      call SubRead.read();
    }
    return SUCCESS;
#else
    return call VirtualVibration.read();
#endif
    return FAIL;
  }

#if defined(PLATFORM_Z1)

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
    smsg.vibration = data;
    smsg.raw = data;
    signal Read.readDone(result, smsg);
  }

#else
  event void VirtualVibration.readDone( error_t result, uint16_t val ) {
    smsg.vibration = val;
    signal Read.readDone(FAIL, smsg);
  }
#endif

}
