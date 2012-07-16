#include <Fennec.h>
#include "adxl345_0_driver.h"

module adxl345_0_driverP @safe() {
  provides interface SensorCtrl;
  provides interface Read<adxl345_t> as Raw;
  provides interface Read<adxl345_t> as Calibrated;
  provides interface Read<bool> as Occurence;

  uses interface Resource;
  uses interface ResourceRequested;
  uses interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;
  uses interface Read<uint16_t> as Battery;
  uses interface Timer<TMilli> as Timer;
}

implementation {

  norace adxl345_t raw_data;
  norace uint16_t battery = 0;

  adxl345_t calibrated_data;
  bool occurence_data = 0;

  norace uint8_t state = S_STOPPED;

  uint16_t sensitivity = ADXL345_0_DEFAULT_SENSITIVITY;
  uint32_t rate = ADXL345_0_DEFAULT_RATE;
  uint8_t signaling = ADXL345_0_DEFAULT_SIGNALING;

  norace uint8_t adxlcmd;
  norace uint8_t databuf[10];
  norace uint8_t pointer;
  norace uint8_t dataformat;

  command error_t SensorCtrl.start() {
    battery = 0;
    occurence_data = 0;
    state = S_STARTING;
    call Timer.startPeriodic(rate);
    signal SensorCtrl.startDone(SUCCESS);

    adxlcmd = ADXLCMD_START;
    call Resource.request();
    return SUCCESS;
  }

  command error_t SensorCtrl.stop() {
    call Timer.stop();
    state = S_STOPPED;
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
    if (state == S_STARTED) {
      state = S_LOADING;
      //call Battery.read();
      adxlcmd = ADXLCMD_READ_X;
      call Resource.request();
    }
  }

  event void Resource.granted(){
    switch(adxlcmd){
      case ADXLCMD_START:
        databuf[0] = ADXL345_POWER_CTL;
        databuf[1] = ADXL345_MEASURE_MODE;
        call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
        break;

      case ADXLCMD_READ_X:
        pointer = ADXL345_DATAX0;
        call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer);
        break;

      case ADXLCMD_READ_Y:
        pointer = ADXL345_DATAY0;
        call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer);
        break;

      case ADXLCMD_READ_Z:
        pointer = ADXL345_DATAZ0;
        call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 1, &pointer);
        break;

      case ADXLCMD_SET_RANGE:
        databuf[0] = ADXL345_DATAFORMAT;
        databuf[1] = dataformat;
        call I2CBasicAddr.write((I2C_START | I2C_STOP), ADXL345_ADDRESS, 2, databuf);
        break;
    }
  }

  async event void ResourceRequested.requested() {}
  async event void ResourceRequested.immediateRequested() {}

  task void check_event() {
    uint16_t delta = sensitivity * ADXL345_0_SENSOR_MOTION_STEP;

    if ((calibrated_data.x < (ADXL345_0_SENSOR_NO_MOTION - delta)) || 
	(calibrated_data.x  > (ADXL345_0_SENSOR_NO_MOTION + delta))) {
      occurence_data = 1;
    } else {
      occurence_data = 0;
    }

    if (signaling) { 
      signal Raw.readDone(SUCCESS, raw_data);
      signal Calibrated.readDone(SUCCESS, calibrated_data);
      signal Occurence.readDone(SUCCESS, occurence_data);
    }
    state = S_STARTED;
  }

  task void calibrate() {
    /* No calibration */
    calibrated_data = raw_data;
    post check_event();
  }

  event void Battery.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      uint32_t b = data;
      b *= 3000;
      b /= 4096;
      battery = b;
    } 
  }


  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    uint16_t tmp;

    if(! call Resource.isOwner()) {
      return;
    }

    tmp = data[1];
    tmp = tmp << 8;
    tmp = tmp + data[0];

    call Resource.release();

    switch(adxlcmd){
      case ADXLCMD_READ_X:
        raw_data.x = tmp;
        adxlcmd = ADXLCMD_READ_Y;
        call Resource.request();
        break;

      case ADXLCMD_READ_Y:
        raw_data.y = tmp;
        adxlcmd = ADXLCMD_READ_Z;
        call Resource.request();
        break;

      case ADXLCMD_READ_Z:
        raw_data.z = tmp;
        post calibrate();
        break;
    }
  }


  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, uint8_t length, uint8_t *data){
    if(! call Resource.isOwner()) {
      return;
    }

    switch(adxlcmd) {
      case ADXLCMD_START:
        state = S_STARTED;
        call Resource.release();
        break;

      case ADXLCMD_READ_X:
        call I2CBasicAddr.read((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 2, databuf);
        break;

      case ADXLCMD_READ_Y:
        call I2CBasicAddr.read((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 2, databuf);
        break;

      case ADXLCMD_READ_Z:
        call I2CBasicAddr.read((I2C_START | I2C_STOP),  ADXL345_ADDRESS, 2, databuf);
        break;

      case ADXLCMD_SET_RANGE:
        call Resource.release();
        break;
    }
  }

  default event void Raw.readDone(error_t err, adxl345_t data) {}
  default event void Calibrated.readDone(error_t err, adxl345_t data) {}
  default event void Occurence.readDone(error_t err, bool data) {}


}

