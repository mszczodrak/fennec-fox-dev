/*
 *  HAMAMATSU S1087_01 PHOTOSYNTHETICALLY-ACTIVE RADIATION SENSOR  driver.
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
 * Application: HAMAMATSU S1087_01 PHOTOSYNTHETICALLY-ACTIVE RADIATION SENSOR
 * Author: Marcin Szczodrak
 * Date: 8/16/2009
 * Last Modified: 1/4/2013
 */

#include "s1087_0_driver.h"

configuration s1087_0_driverC_ {
provides interface SensorCtrl[uint8_t id];
provides interface SensorInfo;
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];
}

implementation {

components s1087_0_driverP;
SensorInfo = s1087_0_driverP.SensorInfo;
SensorCtrl = s1087_0_driverP.SensorCtrl;
Read = s1087_0_driverP.Read;

components new HamamatsuS1087_01ParC();
s1087_0_driverP.ParticleRead -> HamamatsuS1087_01ParC.Read;

components new TimerMilliC() as Timer;
s1087_0_driverP.Timer -> Timer;

}

