/*
 *  Phidget 1129 driver.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
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
 * Date: 12/28/2012
 * Last Modified: 12/28/2012
 */


configuration phidget_1129_0_driverC {
  provides interface SensorCtrl;
  provides interface AdcSetup;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;
}

implementation {
  components phidget_1129_0_driverP;
  AdcSetup = phidget_1129_0_driverP.AdcSetup;
  SensorCtrl = phidget_1129_0_driverP.SensorCtrl;
  Raw = phidget_1129_0_driverP.Raw;
  Calibrated = phidget_1129_0_driverP.Calibrated;

  components new phidget_adc_driverC();
  phidget_1129_0_driverP.AdcSensorCtrl -> phidget_adc_driverC.SensorCtrl;
  phidget_1129_0_driverP.SubAdcSetup -> phidget_adc_driverC.AdcSetup;
  phidget_1129_0_driverP.AdcSensorRaw -> phidget_adc_driverC.Raw;

  components new TimerMilliC() as Timer;
  phidget_1129_0_driverP.Timer -> Timer;
}

