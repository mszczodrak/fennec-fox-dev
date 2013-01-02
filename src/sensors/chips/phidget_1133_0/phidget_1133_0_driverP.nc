/*
 *  Phidget 1133 driver.
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
 * Application: Phidget 1133 driver
 * Author: Marcin Szczodrak
 * Date: 12/28/2012
 * Last Modified: 12/28/2012
 */

#include <Fennec.h>
#include "phidget_1133_0_driver.h"

module phidget_1133_0_driverP @safe() {
  provides interface AdcSetup;
  provides interface SensorCtrl;
  provides interface SensorInfo;
  provides interface Read<uint16_t> as Raw;
  provides interface Read<uint16_t> as Calibrated;

  uses interface SensorCtrl as AdcSensorCtrl;
  uses interface AdcSetup as SubAdcSetup;
  uses interface Read<uint16_t> as AdcSensorRaw;

  uses interface Timer<TMilli> as Timer;
}

implementation {

  uint16_t calibrated_data[PHIDGET_1133_0_SENSOR_HIST_LEN] = {0};
  uint8_t index = 0;

  norace bool signaling = PHIDGET_1133_0_DEFAULT_SIGNALING;
  norace bool read_request = FALSE;
  norace bool adc_channel_set = FALSE;

  command error_t SensorCtrl.start() {
    read_request = FALSE;
    if (adc_channel_set == FALSE) {
      call SubAdcSetup.set_input_channel(PHIDGET_1133_0_DEFAULT_ADC_CHANNEL);
    }
    return call AdcSensorCtrl.start();
  }

  event void AdcSensorCtrl.startDone(error_t error) {
    signal SensorCtrl.startDone(error);
  }

  command error_t SensorCtrl.stop() {
    call Timer.stop();
    return call AdcSensorCtrl.stop();
  }

  event void AdcSensorCtrl.stopDone(error_t error) {
    signal SensorCtrl.stopDone(error);
  }

  command error_t SensorCtrl.set_sensitivity(uint16_t new_sensitivity) {
    return call AdcSensorCtrl.set_sensitivity(new_sensitivity);
  }

  command error_t SensorCtrl.set_rate(uint32_t new_rate) {
    return call AdcSensorCtrl.set_rate(new_rate);
  }

  command error_t SensorCtrl.set_signaling(bool new_signaling) {
    call AdcSensorCtrl.set_signaling(new_signaling);
    signaling = new_signaling;
    return SUCCESS;
  }

  command uint16_t SensorCtrl.get_sensitivity() {
    return call AdcSensorCtrl.get_sensitivity();
  }

  command uint32_t SensorCtrl.get_rate() {
    return call AdcSensorCtrl.get_rate();
  }

  command bool SensorCtrl.get_signaling() {
    return signaling;
  }

command sensor_type_t SensorInfo.getType() {
        return F_SENSOR_SOUND;
}

command sensor_id_t SensorInfo.getId() {
        return FS_PHIDGET_1133_0;
}

  command uint8_t AdcSetup.get_input_channel() {
    return call SubAdcSetup.get_input_channel();
  }

  command error_t AdcSetup.set_input_channel(uint8_t new_channel) {
    adc_channel_set = TRUE;
    return call SubAdcSetup.set_input_channel(new_channel);
  }

  command error_t Raw.read() {
    read_request = TRUE;
    return call AdcSensorRaw.read();
  }

  command error_t Calibrated.read() {
    read_request = TRUE;
    return call AdcSensorRaw.read();
  }

  event void AdcSensorRaw.readDone(error_t error, uint16_t data) {
    if (error == SUCCESS) {
      /* No calibration for phidget_1133_0 */
      index++;
      index %= PHIDGET_1133_0_SENSOR_HIST_LEN;
      calibrated_data[index] = data * 16.801;
      calibrated_data[index] += 9.872;
      if (read_request || signaling) {
        signal Raw.readDone(error, data);
        signal Calibrated.readDone(error, calibrated_data[index]);
        read_request = 0;
      }
    }
  }

  event void Timer.fired() {}

  default event void Raw.readDone(error_t err, uint16_t data) {}
  default event void Calibrated.readDone(error_t err, uint16_t data) {}
}

