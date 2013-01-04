/*
 *  SENSIRION 11 SHT11 HUMIDITY driver.
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
 * Application: SENSIRION 11 SHT11 HUMIDITY
 * Author: Marcin Szczodrak
 * Date: 8/16/2009
 * Last Modified: 1/4/2013
 */

#include "sht11hum_0_driver.h"

configuration sht11hum_0_driverC_ {
provides interface SensorCtrl[uint8_t id];
provides interface SensorInfo;
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];
}

implementation {

components sht11hum_0_driverP;
SensorInfo = sht11hum_0_driverP.SensorInfo;
SensorCtrl = sht11hum_0_driverP.SensorCtrl;
Read = sht11hum_0_driverP.Read;

components new SensirionSht11C();
sht11hum_0_driverP.Temperature -> SensirionSht11C.Temperature;

components new BatteryC();
sht11hum_0_driverP.Battery -> BatteryC.Read;

components new TimerMilliC() as Timer;
sht11hum_0_driverP.Timer -> Timer;

}

