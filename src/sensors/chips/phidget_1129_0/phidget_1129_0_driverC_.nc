/*
 *  Phidget 1129 driver.
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
 * Application: Phidget 1129 driver
 * Author: Marcin Szczodrak
 * Date: 12/28/2010
 * Last Modified: 1/3/2013
 */


#include "phidget_1129_0_driver.h"

configuration phidget_1129_0_driverC_ {

provides interface SensorCtrl[uint8_t id];
provides interface SensorInfo;
provides interface AdcSetup;
provides interface Read<ff_sensor_data_t> as Read[uint8_t id];

}

implementation {

components phidget_1129_0_driverP;
AdcSetup = phidget_1129_0_driverP.AdcSetup;
SensorCtrl = phidget_1129_0_driverP.SensorCtrl;
SensorInfo = phidget_1129_0_driverP.SensorInfo;
Read = phidget_1129_0_driverP.Read;

components new phidget_adc_driverC();
phidget_1129_0_driverP.AdcSensorCtrl -> phidget_adc_driverC.SensorCtrl;
phidget_1129_0_driverP.SubAdcSetup -> phidget_adc_driverC.AdcSetup;
phidget_1129_0_driverP.AdcSensorRead -> phidget_adc_driverC.Read;

components new TimerMilliC() as Timer;
phidget_1129_0_driverP.Timer -> Timer;

}

