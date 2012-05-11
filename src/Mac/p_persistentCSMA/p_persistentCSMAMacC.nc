/*
 *  p-persistent CSMA mac protocol for Fennec Fox platform.
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
 * Application: implementation of p-persistant CSMA
 * Author: Marcin Szczodrak
 * Date: 3/1/2011
 * Last Modified: 6/4/2011
 */

generic configuration p_persistentCSMAMacC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {
  components new p_persistentCSMAMacP();
  Mgmt = p_persistentCSMAMacP;
  Module = p_persistentCSMAMacP;
  MacCall = p_persistentCSMAMacP;
  MacSignal = p_persistentCSMAMacP;
  RadioCall = p_persistentCSMAMacP;
  RadioSignal = p_persistentCSMAMacP;

  components AddressingC;
  p_persistentCSMAMacP.Addressing -> AddressingC.Addressing[F_MAC_ADDRESSING];

  components new TimerMilliC() as BackoffTimer;
  p_persistentCSMAMacP.BackoffTimer -> BackoffTimer;

  components RandomC;
  p_persistentCSMAMacP.Random -> RandomC;

}

