#include "Msp430Adc12.h"

module phidget_1104_0_driverP @safe() {
  provides interface SplitControl;
  provides interface Read<uint16_t>;

  uses interface Read<uint16_t> as Vibration;
  uses interface Read<uint16_t> as Battery;
}

implementation {

  norace uint16_t sensor_data;
  uint32_t aux = 0;
  uint16_t battery = 0;

  command error_t SplitControl.start() {
    signal SplitControl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t Read.read() {
    return call Battery.read();
  }

  event void Battery.readDone(error_t error, uint16_t batt){
    if (error == SUCCESS) {
      aux = batt;
      aux *= 300;
      aux /= 4096;
      battery = aux;
//      signal Read.readDone(error, battery);
      call Vibration.read();
    } else {
      signal Read.readDone(error, 0);
    } 
  }

  event void Vibration.readDone(error_t error, uint16_t data) {
    uint32_t vibration = (uint32_t)(data * battery)/4096;
    signal Read.readDone(error, vibration);
    //signal Read.readDone(error, data);
  }


}

