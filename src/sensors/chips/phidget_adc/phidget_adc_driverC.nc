/*
 * Copyright (c) 2012, Columbia University.
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
  * Phidget ADC sensor driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/08/2014
  */

#include <Fennec.h>
#include "phidget_adc_driver.h"

generic configuration phidget_adc_driverC() {
provides interface SensorCtrl;
provides interface AdcSetup;
provides interface SensorInfo;
provides interface Read<ff_sensor_data_t>;
}

implementation {

components new phidget_adc_driverP();
SensorCtrl = phidget_adc_driverP.SensorCtrl;
SensorInfo = phidget_adc_driverP.SensorInfo;
AdcSetup = phidget_adc_driverP.AdcSetup;
Read = phidget_adc_driverP.Read;

components new Msp430Adc12ClientC();
phidget_adc_driverP.Msp430Adc12SingleChannel -> Msp430Adc12ClientC;
phidget_adc_driverP.Resource -> Msp430Adc12ClientC;

components new BatteryC();
phidget_adc_driverP.Battery -> BatteryC.Read;

components new TimerMilliC() as Timer;
phidget_adc_driverP.Timer -> Timer;

components LedsC;
phidget_adc_driverP.Leds -> LedsC;

}

