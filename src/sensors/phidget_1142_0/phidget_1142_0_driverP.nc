#include <Fennec.h>
#include "phidget_1142_0_driver.h"

module phidget_1142_0_driverP @safe() {
  provides interface AdcSetup;
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;

  uses interface SensorCtrl as AdcSensorCtrl;
  uses interface AdcSetup as SubAdcSetup;
  uses interface Read<uint16_t> as AdcSensorRaw;

  uses interface Timer<TMilli> as Timer;
}

implementation {

  uint16_t calibrated_data[PHIDGET_1142_0_SENSOR_HIST_LEN] = {0};
  uint8_t index = 0;

  norace bool signaling = PHIDGET_1142_0_DEFAULT_SIGNALING;
  norace bool read_request = FALSE;
  norace bool adc_channel_set = FALSE;

  command error_t SensorCtrl.start() {
    read_request = FALSE;
    if (adc_channel_set == FALSE) {
      call SubAdcSetup.set_input_channel(PHIDGET_1142_DEFAULT_ADC_CHANNEL);
    }
    return call AdcSensorCtrl.start();
  }

  event void AdcSensorCtrl.startDone(error_t error) {
    signal SensorCtrl.startDone(error);
  }

  command error_t SensorCtrl.stop() {
    call Timer.stop();
    return call AdcSensorCtrl.stop();
  }

  event void AdcSensorCtrl.stopDone(error_t error) {
    signal SensorCtrl.stopDone(error);
  }

  command error_t SensorCtrl.set_sensitivity(uint16_t new_sensitivity) {
    return call AdcSensorCtrl.set_sensitivity(new_sensitivity);
  }

  command error_t SensorCtrl.set_rate(uint32_t new_rate) {
    return call AdcSensorCtrl.set_rate(new_rate);
  }

  command error_t SensorCtrl.set_signaling(bool new_signaling) {
    call AdcSensorCtrl.set_signaling(new_signaling);
    signaling = new_signaling;
    return SUCCESS;
  }

  command uint16_t SensorCtrl.get_sensitivity() {
    return call AdcSensorCtrl.get_sensitivity();
  }

  command uint32_t SensorCtrl.get_rate() {
    return call AdcSensorCtrl.get_rate();
  }

  command bool SensorCtrl.get_signaling() {
    return signaling;
  }

  command uint8_t AdcSetup.get_input_channel() {
    return call SubAdcSetup.get_input_channel();
  }

  command error_t AdcSetup.set_input_channel(uint8_t new_channel) {
    adc_channel_set = TRUE;
    return call SubAdcSetup.set_input_channel(new_channel);
  }

  command error_t Raw.read() {
    read_request = TRUE;
    return call AdcSensorRaw.read();
  }

  command error_t Calibrated.read() {
    read_request = TRUE;
    return call AdcSensorRaw.read();
  }

  event void AdcSensorRaw.readDone(error_t error, uint16_t data) {
    if (error == SUCCESS) {
      /* No calibration for phidget_1142_0 */
      index++;
      index %= PHIDGET_1142_0_SENSOR_HIST_LEN;
      calibrated_data[index] = data;
      if (read_request || signaling) {
        signal Raw.readDone(error, data);
        signal Calibrated.readDone(error, calibrated_data[index]);
        read_request = 0;
      }
    }
  }

  event void Timer.fired() {}



/*
  task void check_event() {
    uint16_t delta = sensitivity * PHIDGET_1127_0_SENSOR_LIGHT_STEP;

    uint32_t avg = 0;
    uint8_t i = 0;
    for (i = 0; i < PHIDGET_1127_0_SENSOR_LIGHT_HIST; i++) {
      if (i != index) avg += calibrated_data[i];
    }

    avg /= (PHIDGET_1127_0_SENSOR_LIGHT_HIST - 1);
    
    if ((calibrated_data[index] < (avg - delta)) || 
	(calibrated_data[index]  > (avg + delta))) {
      occurence_data = 1;
    } else {
      occurence_data = 0;
    }

    if (signaling) { 
      signal Raw.readDone(SUCCESS, raw_data);
      signal Calibrated.readDone(SUCCESS, calibrated_data[index]);
    }
  }
*/

  default event void Raw.readDone(error_t err, uint16_t data) {}
  default event void Calibrated.readDone(error_t err, uint16_t data) {}
}

