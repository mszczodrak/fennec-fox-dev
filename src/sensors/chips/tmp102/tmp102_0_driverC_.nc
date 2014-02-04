/*
 * Copyright (c) 2012 Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * TMP102 sensor driver.
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/08/2014
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
