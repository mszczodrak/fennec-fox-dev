/*
 *  ADXL345 driver.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */
  
/*
 * Application: ADXL345 driver
 * Author: Marcin Szczodrak
 * Date: 3/14/2012
 * Last Modified: 1/2/2013
 */


#include <Fennec.h>
#include "adxl345_0_driver.h"

module adxl345_0_driverP @safe() {

provides interface SensorCtrl;
provides interface SensorInfo;
provides interface Read<ff_sensor_data_t>;

uses interface Resource;
uses interface ResourceRequested;
uses interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;
uses interface Read<uint16_t> as Battery;
uses interface Timer<TMilli> as Timer;
}

implementation {

norace adxl345_t raw_data;
norace uint16_t battery = 0;

ff_sensor_data_t data;

adxl345_t calibrated_data;

uint16_t sensitivity = ADXL345_0_DEFAULT_SENSITIVITY;
uint32_t rate = ADXL345_0_DEFAULT_RATE;
uint8_t signaling = ADXL345_0_DEFAULT_SIGNALING;

norace uint8_t adxlcmd;
norace uint8_t databuf[10];
norace uint8_t pointer;
norace uint8_t dataformat;

command error_t SensorCtrl.start() {
	battery = 0;
	adxlcmd = ADXLCMD_START;
	call Resource.request();
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

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_ACCELEROMETER;
}

command sensor_id_t SensorInfo.getId() {
        return FS_ADXL345;
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

void write_to_i2c() {
	error_t i2c_err = FAIL;
	switch(adxlcmd){
	case ADXLCMD_START:
		databuf[0] = ADXL345_POWER_CTL;
		databuf[1] = ADXL345_MEASURE_MODE;
		i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP), 
					ADXL345_ADDRESS, 2, databuf);
		break;

	case ADXLCMD_READ_X:
		pointer = ADXL345_DATAX0;
		i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP), 
					ADXL345_ADDRESS, 1, &pointer);
		break;

	case ADXLCMD_READ_Y:
		pointer = ADXL345_DATAY0;
		i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP), 
					ADXL345_ADDRESS, 1, &pointer);
		break;

	case ADXLCMD_READ_Z:
		pointer = ADXL345_DATAZ0;
		i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP), 
					ADXL345_ADDRESS, 1, &pointer);
		break;

	case ADXLCMD_SET_RANGE:
		databuf[0] = ADXL345_DATAFORMAT;
		databuf[1] = dataformat;
		i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP), 
					ADXL345_ADDRESS, 2, databuf);
		break;
	}

	if (i2c_err) {
		call Resource.release();
	}
}

event void Timer.fired() {
	adxlcmd = ADXLCMD_READ_X;
	//call Battery.read();

	if (call Resource.isOwner()) {
		write_to_i2c();
	} else {
		call Resource.request();
	}
}

event void Resource.granted() {
	write_to_i2c();
}

async event void ResourceRequested.requested() {}
async event void ResourceRequested.immediateRequested() {}

task void check_event() {
	uint16_t delta = sensitivity * ADXL345_0_SENSOR_MOTION_STEP;

	if ((calibrated_data.x < (ADXL345_0_SENSOR_NO_MOTION - delta)) || 
		(calibrated_data.x  > (ADXL345_0_SENSOR_NO_MOTION + delta))) {
	} else {
	}

	if (signaling) { 
		signal Raw.readDone(SUCCESS, raw_data);
		signal Calibrated.readDone(SUCCESS, calibrated_data);
	}
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


async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, 
					uint8_t length, uint8_t *data){
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


async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, 
					uint8_t length, uint8_t *data){

    error_t erro = FAIL;

    if(! call Resource.isOwner()) {
      return;
    }

    switch(adxlcmd) {
      case ADXLCMD_READ_X:
        erro = call I2CBasicAddr.read((I2C_START | I2C_STOP),  
					ADXL345_ADDRESS, 2, databuf);
        break;

      case ADXLCMD_READ_Y:
        erro = call I2CBasicAddr.read((I2C_START | I2C_STOP),  
					ADXL345_ADDRESS, 2, databuf);
        break;

      case ADXLCMD_READ_Z:
        erro = call I2CBasicAddr.read((I2C_START | I2C_STOP),  
					ADXL345_ADDRESS, 2, databuf);
        break;
    }
    if (erro) {
      call Resource.release();
    }
}

default event void Raw.readDone(error_t err, adxl345_t data) {}
default event void Calibrated.readDone(error_t err, adxl345_t data) {}

}

