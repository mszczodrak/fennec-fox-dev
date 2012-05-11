/*
 *  SimpleAddrMac protocol for Fennec Fox platform.
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
 * Application: implementation of simple MAC protocol, just sends with addressing
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/4/2011
 */

generic configuration simpleAddrMacC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {
  components new simpleAddrMacP();
  Mgmt = simpleAddrMacP;
  Module = simpleAddrMacP;
  MacCall = simpleAddrMacP;
  MacSignal = simpleAddrMacP;
  RadioCall = simpleAddrMacP;
  RadioSignal = simpleAddrMacP;

  components AddressingC;
  simpleAddrMacP.Addressing -> AddressingC.Addressing[F_MAC_ADDRESSING];
}

