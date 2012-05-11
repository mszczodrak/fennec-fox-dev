#include <Fennec.h>
#include <ff_sensors.h>

module SoundP {
  provides interface Read<struct ff_sensor_sound>;

#if defined(PLATFORM_Z1)
  uses interface SplitControl;
  uses interface Read<uint16_t> as SubRead;
#else
  uses interface Read<uint16_t> as VirtualSound;
#endif

}

implementation {

  uint8_t status = S_STOPPED;
  struct ff_sensor_sound smsg;
  
  command error_t Read.read() {
    smsg.sound = 0;
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
    return call VirtualSound.read();
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
    smsg.sound = 16.801 * data + 9.872;
    smsg.raw = data;
    signal Read.readDone(result, smsg);
  }

#else
  event void VirtualSound.readDone( error_t result, uint16_t val ) {
    smsg.sound = val;
    signal Read.readDone(FAIL, smsg);
  }
#endif

}
