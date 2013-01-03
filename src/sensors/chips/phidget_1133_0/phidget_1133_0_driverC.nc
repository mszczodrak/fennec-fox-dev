/*
 *  Phidget 1133 driver.
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
 * Application: Phidget 1133 driver
 * Author: Marcin Szczodrak
 * Date: 12/28/2010
 * Last Modified: 1/3/2013
 */

#include "phidget_1133_0_driver.h"

generic configuration phidget_1133_0_driverC() {

provides interface SensorCtrl;
provides interface SensorInfo;
provides interface AdcSetup;
provides interface Read<ff_sensor_data_t>;
}

implementation {

enum {
        CLIENT_ID = unique(UQ_PHIDGET_1133),
};


components phidget_1133_0_driverC_;
AdcSetup = phidget_1133_0_driverC_.AdcSetup;
SensorCtrl = phidget_1133_0_driverC_.SensorCtrl[CLIENT_ID];
SensorInfo = phidget_1133_0_driverC_.SensorInfo;
Read = phidget_1133_0_driverC_.Read[CLIENT_ID];

}

