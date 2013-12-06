/*
 *  TMP102 driver.
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
 * Application: TMP102 driver
 * Author: Marcin Szczodrak
 * Date: 3/16/2012
 * Last Modified: 1/4/2013
 */
  
#include <Fennec.h>
#include "tmp102_0_driver.h"

module tmp102_0_driverP @safe() {
provides interface SensorInfo;
provides interface SensorCtrl[uint8_t id];
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];

uses interface Resource;
uses interface ResourceRequested;
uses interface I2CPacket<TI2CBasicAddr> as I2CBasicAddr;        
uses interface Read<uint16_t> as Battery;
uses interface Timer<TMilli> as Timer;   
uses interface Timer<TMilli> as TimerSensor;
uses interface Leds;
}

implementation {

uint16_t temp;
uint8_t pointer;
uint8_t temperaturebuff[2];
uint16_t tmpaddr;

norace uint8_t negative_number;
norace uint8_t mode;  /* Mode   * 0 -> 12-bit format 	 * 1 -> 13-bit format  */

norace uint16_t battery = 0;

norace uint16_t raw_data;
uint16_t calibrated_data;
ff_sensor_data_t return_data;
norace error_t status = SUCCESS;
norace uint32_t sequence = 0;
uint32_t freq = 0;
norace bool busy = FALSE;

enum {
        NUM_CLIENTS = uniqueCount(UQ_TMP102)
};

ff_sensor_client_t clients[NUM_CLIENTS];

task void new_freq() {
        uint8_t i;
        freq = 0;
        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].rate == 0) {
                        continue;
                }

                if (freq == 0) {
                        freq = clients[i].rate;
                        continue;
                }

                freq = gcdr(freq, clients[i].rate);
        }
        if (freq) {
                call Timer.startPeriodic(freq);
        } else {
                call Timer.stop();
        }
};

task void readDone() {
        uint8_t i;

        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].read) {
                        signal Read.readDone[i](status, return_data);
                }
        }

        if (freq == 0) {
                return;
        }

        for(i = 0; i < NUM_CLIENTS; i++) {
                if (clients[i].rate == 0) {
                        continue;
                }

                if (sequence % (clients[i].rate / freq) == 0) {
                        signal Read.readDone[i](status, return_data);
                }
        }
}

task void start_sensor_timer() {
}

task void getMeasurement() {
        //call Battery.read();
	call TimerSensor.startOneShot(100);
	busy = TRUE;
	atomic P5DIR |= 0x01;
	atomic P5OUT |= 0x01;
	//post start_sensor_timer();
}

task void data_ready() {
	/* calibrated */
	calibrated_data = raw_data * 0.0625;

        return_data.size = sizeof(uint16_t);
        return_data.seq = ++sequence;
        return_data.raw = &raw_data;
        return_data.calibrated = &calibrated_data;
        return_data.type = call SensorInfo.getType();
        return_data.id = call SensorInfo.getId();
        status = SUCCESS;
        post readDone();
}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_TEMPERATURE;
}

command sensor_id_t SensorInfo.getId() {
        return FS_TI_TMP102;
}

command error_t SensorCtrl.setRate[uint8_t id](uint32_t newRate) {
        clients[id].read = 0;
        clients[id].rate = newRate;
        post new_freq();

        return SUCCESS;
}

command uint32_t SensorCtrl.getRate[uint8_t id]() {
        return clients[id].rate;
}

command error_t Read.read[uint8_t id]() {
	if (busy == TRUE) return EBUSY;
        clients[id].read = 1;
        post getMeasurement();
        return SUCCESS;
}

event void Timer.fired() {
	if (busy == TRUE) return;
	post getMeasurement();
}

void write_to_i2c() {
	error_t i2c_err;
	pointer = TMP102_TEMPREG;
	i2c_err = call I2CBasicAddr.write((I2C_START | I2C_STOP),
                        TMP102_ADDRESS, 1, &pointer);

	if (i2c_err) {
		busy = FALSE;
		call Resource.release();
	}
}

event void TimerSensor.fired() {
	if (call Resource.isOwner()) {
		write_to_i2c();
	} else {
		call Resource.request();
	}
}

event void Resource.granted(){
	write_to_i2c();
}

async event void I2CBasicAddr.readDone(error_t error, uint16_t addr, 
					uint8_t length, uint8_t *data) {
	uint16_t tmp = 0; 	

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
	busy = FALSE;
	call Resource.release();
	atomic raw_data = tmp;
	post data_ready();
}

async event void I2CBasicAddr.writeDone(error_t error, uint16_t addr, 
					uint8_t length, uint8_t *data) {
	error_t i2c_err;
	if (!call Resource.isOwner()) {
		return; 
	}
	i2c_err = call I2CBasicAddr.read((I2C_START | I2C_STOP),  
			TMP102_ADDRESS, 2, temperaturebuff);
	if (i2c_err) {
		busy = FALSE;
		call Resource.release();
	}
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

default event void Read.readDone[uint8_t id](error_t err, ff_sensor_data_t data) {}

}
