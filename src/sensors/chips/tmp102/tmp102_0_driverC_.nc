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

#include "tmp102_0_driver.h"

configuration tmp102_0_driverC_ {
provides interface SensorInfo;
provides interface SensorCtrl[uint8_t id];
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];
}
implementation {
components tmp102_0_driverP;
SensorInfo = tmp102_0_driverP.SensorInfo;
SensorCtrl = tmp102_0_driverP.SensorCtrl;
Read = tmp102_0_driverP.Read;

components new Msp430I2C1C() as I2C;
tmp102_0_driverP.Resource -> I2C;
tmp102_0_driverP.ResourceRequested -> I2C;
tmp102_0_driverP.I2CBasicAddr -> I2C;    

components new BatteryC();
tmp102_0_driverP.Battery -> BatteryC.Read;

components new TimerMilliC() as Timer;
tmp102_0_driverP.Timer -> Timer;

components new TimerMilliC() as TimerSensor;
tmp102_0_driverP.TimerSensor -> TimerSensor;

components LedsC;
tmp102_0_driverP.Leds -> LedsC;
}
