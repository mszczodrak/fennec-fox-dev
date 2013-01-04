/*
 *  MS320_LP driver.
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
 * Application: MS320_LP driver
 * Author: Marcin Szczodrak
 * Date: 3/16/2012
 * Last Modified: 1/4/2013
 */

#include <Fennec.h>
#include "ms320_lp_0_driver.h"

module ms320_lp_0_driverP @safe() {
  provides interface SensorInfo;
  provides interface SensorCtrl[uint8_t id];
  provides interface Read<ff_sensor_data_t> as Read[uint8_t id];

  uses interface GeneralIO as MotionPin;
  uses interface Timer<TMilli> as Timer;
}

implementation {

norace uint16_t battery = 0;

uint8_t motion_data;
ff_sensor_data_t return_data;
norace error_t status = SUCCESS;
norace uint32_t sequence = 0;
uint32_t freq = 0;

enum {
        NUM_CLIENTS = uniqueCount(UQ_MS320_LP)
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

task void sense_motion() {
	if (call MotionPin.get())
		motion_data = 0;
	else
		motion_data = 1;

	call MotionPin.makeOutput();
	call MotionPin.clr();

	return_data.size = sizeof(uint8_t);
	return_data.seq = ++sequence;
	return_data.raw = &motion_data;
	return_data.calibrated = &motion_data;
	return_data.type = call SensorInfo.getType();
	return_data.id = call SensorInfo.getId();
	status = SUCCESS;
	post readDone();
}

task void getMeasurement() {
	call MotionPin.makeInput();
	post sense_motion();
}

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_MOTION;
}

command sensor_id_t SensorInfo.getId() {
        return FS_MS320_LP;
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
	clients[id].read = 1;
	post getMeasurement();
	return SUCCESS;
}

event void Timer.fired() {
	post getMeasurement();
}

default event void Read.readDone[uint8_t id](error_t err, ff_sensor_data_t data) {}
}

