/*
 *  Sending Counter application for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2011 Marcin Szczodrak
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
 * Application: Sends incremental counter value on the network
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2011
 */

generic configuration KanseiCounterAppC(uint16_t delay, uint16_t src, uint16_t dest) {
  provides interface Mgmt;
  provides interface Module;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  components new KanseiCounterAppP(delay, src, dest);
  Mgmt = KanseiCounterAppP;
  Module = KanseiCounterAppP;
  NetworkCall = KanseiCounterAppP;
  NetworkSignal = KanseiCounterAppP;

  components LedsC;
  KanseiCounterAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  KanseiCounterAppP.Timer0 -> Timer0;

  components FennecSerialC;
  KanseiCounterAppP.Serial -> FennecSerialC;

}
