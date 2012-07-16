#include <Fennec.h>
#include "ms320_lp_driver.h"

module ms320_lp_driverP @safe() {
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
  provides interface Read<bool> as Occurence;

  uses interface GeneralIO as MotionPin;
  uses interface Timer<TMilli> as Timer;
}

implementation {

  norace uint16_t raw_data = 0;
  uint16_t calibrated_data;
  bool occurence_data = 0;

  uint16_t sensitivity = MS320_LP_DEFAULT_SENSITIVITY;
  uint32_t rate = MS320_LP_DEFAULT_RATE;
  uint8_t signaling = MS320_LP_DEFAULT_SIGNALING;

  command error_t SensorCtrl.start() {
    raw_data = 0;
    occurence_data = 0;
    call MotionPin.makeInput();
    call Timer.startPeriodic(rate);
    signal SensorCtrl.startDone(SUCCESS);
    return SUCCESS;
  }

  command error_t SensorCtrl.stop() {
    call MotionPin.makeOutput();
    call MotionPin.clr();
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

  task void check_event() {
    occurence_data = calibrated_data;
    if (signaling) { 
      signal Raw.readDone(SUCCESS, raw_data);
      signal Calibrated.readDone(SUCCESS, calibrated_data);
      signal Occurence.readDone(SUCCESS, occurence_data);
    }
  }

  task void calibrate() {
    /* No calibration for ms320_lp */
    calibrated_data = raw_data;
    post check_event();
  }

  event void Timer.fired() {
    if (call MotionPin.get())
      raw_data = 0;
    else
      raw_data = 1;
    post calibrate();
  }

  default event void Raw.readDone(error_t err, uint16_t data) {}
  default event void Calibrated.readDone(error_t err, uint16_t data) {}
  default event void Occurence.readDone(error_t err, bool data) {}
}

