
#include <Fennec.h>
#define VIRTUAL_VIBRATION_VALUE	25

module VirtualVibrationSensorP {
  provides interface Read<uint16_t>;
}

implementation {

  void task returnValue() {
    signal Read.readDone(SUCCESS, VIRTUAL_VIBRATION_VALUE);
  }

  command error_t Read.read() {
    post returnValue();
    return SUCCESS;
  }

}

