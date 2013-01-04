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
 * Last Modified: 1/4/2013
 */

#include "adxl345_0_driver.h"

configuration adxl345_0_driverC_ {

provides interface SensorInfo;
provides interface SensorCtrl[uint8_t id];
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];

}

implementation {

components adxl345_0_driverP;
SensorInfo = adxl345_0_driverP.SensorInfo;
SensorCtrl = adxl345_0_driverP.SensorCtrl;
Read = adxl345_0_driverP.Read;

components new ADXL345C();
adxl345_0_driverP.XYZ -> ADXL345C.XYZ;
adxl345_0_driverP.XYZControl -> ADXL345C.SplitControl;

components new BatteryC();
adxl345_0_driverP.Battery -> BatteryC.Read;

components new TimerMilliC() as Timer;
adxl345_0_driverP.Timer -> Timer;
}

