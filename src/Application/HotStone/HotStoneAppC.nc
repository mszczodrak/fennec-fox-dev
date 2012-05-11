/*
 *  Hot Stone application for Fennec Fox platform.
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
 * Application: Send incremental counter value on the network, and each node
 *              randomly re-broadcast the counter value further
 * Author: Marcin Szczodrak
 * Date: 8/13/2011
 * Last Modified: 8/13/2011
 */

generic configuration HotStoneAppC(uint16_t min_delay, uint16_t max_delay) {
  provides interface Mgmt;
  provides interface Module;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {

  components new HotStoneAppP(min_delay, max_delay);
  Mgmt = HotStoneAppP;
  Module = HotStoneAppP;
  NetworkCall = HotStoneAppP;
  NetworkSignal = HotStoneAppP;

  components LedsC;
  HotStoneAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  HotStoneAppP.Timer0 -> Timer0;

  components RandomC;
  HotStoneAppP.Random -> RandomC;

}
