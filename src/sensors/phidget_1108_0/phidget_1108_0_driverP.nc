#include <Fennec.h>
#include "phidget_1108_0_driver.h"

module phidget_1108_0_driverP @safe() {
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
  provides interface Read<bool> as Occurence;

  uses interface Msp430Adc12SingleChannel;
  uses interface Resource;
  uses interface Read<uint16_t> as Battery;
  uses interface Timer<TMilli> as Timer;
}

implementation {

  norace uint16_t raw_data = 0;
  norace uint16_t battery = 0;

  uint16_t calibrated_data;
  bool occurence_data = 0;

  uint16_t sensitivity = PHIDGET_1108_0_DEFAULT_SENSITIVITY;
  uint32_t rate = PHIDGET_1108_0_DEFAULT_RATE;
  uint8_t signaling = PHIDGET_1108_0_DEFAULT_SIGNALING;

  command error_t SensorCtrl.start() {
    battery = 0;
    raw_data = 0;
    occurence_data = 0;
    call Timer.startPeriodic(rate);
    signal SensorCtrl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SensorCtrl.stop() {
    call Timer.stop();
    signal SensorCtrl.stopDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SensorCtrl.set_sensitivity(uint16_t new_sensitivity) {
    sensitivity = new_sensitivity;
    return SUCCESS;
  }

  command error_t SensorCtrl.set_rate(uint32_t new_rate) {
    rate = new_rate;
    call Timer.startPeriodic(rate);
    return SUCCESS;
  }

  command error_t SensorCtrl.set_signaling(bool new_signaling) {
    signaling = new_signaling;
    return SUCCESS;
  }

  command uint16_t SensorCtrl.get_sensitivity() {
    return sensitivity;
  }

  command uint32_t SensorCtrl.get_rate() {
    return rate;
  }

  command bool SensorCtrl.get_signaling() {
    return signaling;
  }

  command error_t Raw.read() {
    signal Raw.readDone(SUCCESS, raw_data);
    return SUCCESS;
  }

  command error_t Calibrated.read() {
    signal Calibrated.readDone(SUCCESS, calibrated_data);
    return SUCCESS;
  }

  command error_t Occurence.read() {
    signal Occurence.readDone(SUCCESS, occurence_data);
    return SUCCESS;
  }

  event void Timer.fired() {
    call Battery.read();
    call Resource.request();
    call Resource.release();
  }

  event void Resource.granted() {
    call Msp430Adc12SingleChannel.configureSingle(&phidget_1108_0_adc_config);
    call Msp430Adc12SingleChannel.getData();
  }

  task void check_event() {
    uint16_t delta = sensitivity * PHIDGET_1108_0_SENSOR_MAGNETIC_STEP;

    if ((calibrated_data < (PHIDGET_1108_0_SENSOR_NO_MAGNETIC - delta)) || 
	(calibrated_data  > (PHIDGET_1108_0_SENSOR_NO_MAGNETIC + delta))) {
      occurence_data = 1;
    } else {
      occurence_data = 0;
    }

    if (signaling) { 
      signal Raw.readDone(SUCCESS, raw_data);
      signal Calibrated.readDone(SUCCESS, calibrated_data);
      signal Occurence.readDone(SUCCESS, occurence_data);
    }
  }

  task void calibrate() {
    /* No calibration for phidget_1108_0 */
    calibrated_data = raw_data;
    post check_event();
  }

  async event error_t Msp430Adc12SingleChannel.singleDataReady(uint16_t data){
    uint32_t s = data;
    s *= battery;
    s /= 4096;    
    raw_data = s;
    post calibrate();
    return 0;
  }

  event void Battery.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      uint32_t b = data;
      b *= 3000;
      b /= 4096;
      battery = b;
    } 
  }

  async event uint16_t *Msp430Adc12SingleChannel.multipleDataReady(uint16_t *buffer, uint16_t numSamples){
    return 0;
  }

  default event void Raw.readDone(error_t err, uint16_t data) {}
  default event void Calibrated.readDone(error_t err, uint16_t data) {}
  default event void Occurence.readDone(error_t err, bool data) {}
}

