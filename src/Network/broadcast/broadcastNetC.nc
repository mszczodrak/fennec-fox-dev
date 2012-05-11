/*
 *  Broadcast network module for Fennec Fox platform.
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
 * Network: Broadcast message
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/5/2011
 */

#include <Fennec.h>

generic configuration broadcastNetC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface MacCall;
  uses interface MacSignal;
}

implementation {

  components new broadcastNetP();
  Mgmt = broadcastNetP;
  Module = broadcastNetP;
  NetworkCall = broadcastNetP;
  NetworkSignal = broadcastNetP;
  MacCall = broadcastNetP;
  MacSignal = broadcastNetP;

  components AddressingC;
  broadcastNetP.Addressing -> AddressingC.Addressing[F_NETWORK_ADDRESSING];
}
