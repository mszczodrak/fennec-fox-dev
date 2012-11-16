#include <Fennec.h>
#include <ff_sensors.h>

module PIRP {
  provides interface Read<struct ff_sensor_pir>;

#if defined(PLATFORM_Z1)
  uses interface SplitControl;
  uses interface Read<uint16_t> as SubRead;
#else
  uses interface Read<uint16_t> as VirtualPIR;
#endif

}

implementation {

  uint8_t status = S_STOPPED;
  struct ff_sensor_pir smsg;
  
  command error_t Read.read() {
    smsg.presence = 0;
#if defined(PLATFORM_Z1)
    if (status == S_STOPPED) {
      call SplitControl.start();
    }

    if (status == S_STARTED) {
      call SubRead.read();
    }
    return SUCCESS;
#else
    return call VirtualPIR.read();
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
    smsg.presence = data;
    signal Read.readDone(result, smsg);
  }

#else
  event void VirtualPIR.readDone( error_t result, uint16_t val ) {
    smsg.presence = val;
    signal Read.readDone(SUCCESS, smsg);
  }
#endif

}
