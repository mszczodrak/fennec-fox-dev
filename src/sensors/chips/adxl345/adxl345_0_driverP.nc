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
#include "ADXL345.h"

module adxl345_0_driverP @safe() {

provides interface SensorInfo;
provides interface Read<ff_sensor_data_t>;

uses interface Read<adxl345_readxyt_t> as XYZ;
uses interface SplitControl as XYZControl;
uses interface Read<uint16_t> as Battery;
uses interface Timer<TMilli> as Timer;
}

implementation {

norace uint16_t battery = 0;

uint32_t rate = ADXL345_0_DEFAULT_RATE;
uint8_t signaling = ADXL345_0_DEFAULT_SIGNALING;

adxl345_readxyt_t xyz_data;
ff_sensor_data_t return_data;

task void getMeasurement() {
	//call Battery.read();

	if (call XYZControl.start() == FAIL) { 
		signal Read.readDone(FAIL, return_data);
	}
}


event void XYZControl.startDone(error_t error) {
	if ((error != SUCCESS) || (call XYZ.read() != SUCCESS)) {
		signal Read.readDone(FAIL, return_data);
	}
}


event void XYZControl.stopDone(error_t error) {

}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_ACCELEROMETER;
}

command sensor_id_t SensorInfo.getId() {
        return FS_ADXL345;
}

command error_t Read.read() {
	post getMeasurement();
	return SUCCESS;
}

event void Timer.fired() {
}

event void Battery.readDone(error_t error, uint16_t data){
	if (error == SUCCESS) {
		uint32_t b = data;
		b *= 3000;
		b /= 4096;
		battery = b;
	} 
}

event void XYZ.readDone(error_t error, adxl345_readxyt_t data){
	call XYZControl.stop();

	if (error != SUCCESS) {
		signal Read.readDone(FAIL, return_data);
		return;
	}

	return_data.size = sizeof(adxl345_readxyt_t);
	return_data.raw = &return_data;
	return_data.calibrated = &return_data;
	return_data.type = call SensorInfo.getType();
	return_data.id = call SensorInfo.getId();

	signal Read.readDone(SUCCESS, return_data);
}

default event void Read.readDone(error_t error, ff_sensor_data_t data) {}

}

