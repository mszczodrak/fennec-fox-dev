/*
    Phidget ADC Driver for Fennec Fox
    Copyright (C) 2009-2012

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    Authors: Dhananjay Palshikar (dp2575@columbia.edu)
             Marcin Szczodrak  (marcin@ieee.org)

*/

generic configuration phidget_adc_driverC() {
   provides interface SensorCtrl;
   provides interface AdcSetup;
   provides interface SensorInfo;
   provides interface Read<uint16_t> as Raw;
}

implementation {
  components new phidget_adc_driverP();
  SensorCtrl = phidget_adc_driverP.SensorCtrl;
  SensorInfo = phidget_adc_driverP.SensorInfo;
  AdcSetup = phidget_adc_driverP.AdcSetup;
  Raw = phidget_adc_driverP.Raw;

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

