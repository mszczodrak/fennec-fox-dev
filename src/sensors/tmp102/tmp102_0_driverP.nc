#include <Fennec.h>
#include "tmp102_0_driver.h"

module tmp102_0_driverP @safe() {
  provides interface SensorCtrl;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
  provides interface Read<bool> as Occurence;

  uses interface Resource;
  uses interface ResourceRequested;
  uses interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;        
  uses interface Read<uint16_t> as Battery;
  uses interface Timer<TMilli> as Timer;   
  uses interface Timer<TMilli> as TimerSensor;
}

implementation {

  norace uint16_t raw_data = 0;
  norace uint16_t battery = 0;

  uint16_t calibrated_data;
  bool occurence_data = 0;

  uint16_t sensitivity = TMP102_0_DEFAULT_SENSITIVITY;
  uint32_t rate = TMP102_0_DEFAULT_RATE;
  uint8_t signaling = TMP102_0_DEFAULT_SIGNALING;

  uint16_t temp;
  uint8_t pointer;
  uint8_t temperaturebuff[2];
  uint16_t tmpaddr;

  norace uint8_t negative_number;
  norace uint8_t mode;  /* Mode   * 0 -> 12-bit format 	 * 1 -> 13-bit format  */

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
    if (call Resource.isOwner()) {
      call Resource.release();
    }
    atomic P5DIR |= 0x01;
    atomic P5OUT |= 0x01;
    call TimerSensor.startOneShot(100);
  }

  event void TimerSensor.fired() {
    error_t i2c_err;
    pointer = TMP102_TEMPREG;
    i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP),
                        TMP102_ADDRESS, 1, &pointer);
    if (i2c_err) {
      call Resource.release();
    }
  }

  event void Resource.granted(){
    accessI2C();
  }

  task void check_event() {
    uint16_t delta = sensitivity * TMP102_0_SENSOR_TEMPERATURE_DEGREE_STEP;

    if ((calibrated_data < (TMP102_0_SENSOR_NO_TEMPERATURE_DIFFERENCE - delta)) ||
        (calibrated_data  > (TMP102_0_SENSOR_NO_TEMPERATURE_DIFFERENCE + delta))) {
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
    calibrated_data = raw_data * 0.0625;
    post check_event();
  }

  async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, 
					uint8_t length, uint8_t *data) {
    uint16_t tmp; 	

    if (!call Resource.isOwner()) {
      return; 
    }

    //for(tmp=0;tmp<0xffff;tmp++);    //delay

    mode = data[1] & 1;
    negative_number = data[0] >> 7;

    if ((mode == TMP102_0_12BIT_MODE) && !negative_number) {
      tmp = data[0];
      tmp = tmp << 8;
      tmp = tmp + data[1];
      tmp = tmp >> 4;
    }
    call Resource.release();
    atomic raw_data = tmp;
    post calibrate();
  }

  async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, 
					uint8_t length, uint8_t *data) {
    if (!call Resource.isOwner()) {
      return; 
    }
    call I2CBasicAddr.read((I2C_START | I2C_STOP),  
			TMP102_ADDRESS, 2, temperaturebuff);
  }   

  event void Battery.readDone(error_t error, uint16_t data){
    if (error == SUCCESS) {
      uint32_t b = data;
      b *= 3000;
      b /= 4096;
      battery = b;
    }
  }
  
  async event void ResourceRequested.requested(){}
  async event void ResourceRequested.immediateRequested(){}

  default event void Raw.readDone(error_t err, uint16_t data) {}
  default event void Calibrated.readDone(error_t err, uint16_t data) {}
  default event void Occurence.readDone(error_t err, bool data) {}

}
