
#include <Fennec.h>
#define VIRTUAL_THINFORCE_VALUE	35

module VirtualThinForceSensorP {
  provides interface Read<uint16_t>;
}

implementation {

  void task returnValue() {
    signal Read.readDone(SUCCESS, VIRTUAL_THINFORCE_VALUE);
  }

  command error_t Read.read() {
    post returnValue();
    return SUCCESS;
  }

}

