/*
 *  Trickle network module for Fennec Fox platform.
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
 * Network: Trickle Dissemination Protocol
 * Author: Marcin Szczodrak
 * Date: 9/18/2011
 * Last Modified: 9/19/2011
 */

#include <Fennec.h>

generic configuration trickleNetC(uint16_t short_period, uint16_t long_period,
                                uint16_t period_threshold, uint16_t scale) {
  provides interface Mgmt;
  provides interface Module;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface MacCall;
  uses interface MacSignal;
}

implementation {

  components new trickleNetP(short_period, long_period, period_threshold, scale);
  Mgmt = trickleNetP;
  Module = trickleNetP;
  NetworkCall = trickleNetP;
  NetworkSignal = trickleNetP;
  MacCall = trickleNetP;
  MacSignal = trickleNetP;

  components AddressingC;
  trickleNetP.Addressing -> AddressingC.Addressing[F_NETWORK_ADDRESSING];

  components RandomC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  trickleNetP.Timer0 -> Timer0;
  trickleNetP.Timer1 -> Timer1;
  trickleNetP.Random -> RandomC;

}
