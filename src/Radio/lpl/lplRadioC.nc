/*
 *  lpl radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2012 Marcin Szczodrak
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
 * Application: LPL Radio Module
 * Author: Marcin Szczodrak
 * Date: 10/12/2011
 * Last Modified: 2/9/2012
 */

generic configuration lplRadioC(uint8_t radio_channel, /* Channels are 11-26 */
                        	uint8_t tx_power, /* Power is: Max 31, 27, 23, 19, 15, 11, 7, 3 Min */
				bool enable_auto_crc,
				uint16_t sleep_time, 
				uint16_t active_time, 
				uint16_t stay_awake_time) {
  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;
}

implementation {

  components new lplRadioP(sleep_time, active_time, stay_awake_time);
  Mgmt = lplRadioP;
  Module = lplRadioP;
  RadioCall = lplRadioP;
  RadioSignal = lplRadioP;

  components new simpleCC2420RadioC(radio_channel, tx_power, enable_auto_crc,);
  Module = simpleCC2420RadioC;
  lplRadioP.CC2420Mgmt -> simpleCC2420RadioC;
  lplRadioP.CC2420RadioCall -> simpleCC2420RadioC;
  lplRadioP.CC2420RadioSignal -> simpleCC2420RadioC;

  components new TimerMilliC() as Timer;
  lplRadioP.Timer -> Timer;

  components new TimerMilliC() as Receiver;
  lplRadioP.Receiver -> Receiver;

  components new TimerMilliC() as AwakeTimer;
  lplRadioP.AwakeTimer -> AwakeTimer;

  components new TimerMilliC() as PreambleTimer;
  lplRadioP.PreambleTimer -> PreambleTimer;

  components RandomC;
  lplRadioP.Random -> RandomC;
}

