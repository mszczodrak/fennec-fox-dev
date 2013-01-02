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

#include "adxl345_0_driver.h"

configuration adxl345_0_driverC {

provides interface SensorCtrl;
provides interface SensorInfo;
provides interface Read<ff_sensor_data_t>;

}

implementation {

components adxl345_0_driverP;
SensorCtrl = adxl345_0_driverP.SensorCtrl;
SensorInfo = adxl345_0_driverP.SensorInfo;
Read = adxl345_0_driverP.Read;

components new Msp430I2C1C() as I2C;
adxl345_0_driverP.Resource -> I2C;
adxl345_0_driverP.ResourceRequested -> I2C;
adxl345_0_driverP.I2CBasicAddr -> I2C;

components new BatteryC();
adxl345_0_driverP.Battery -> BatteryC.Read;

components new TimerMilliC() as Timer;
adxl345_0_driverP.Timer -> Timer;
}

