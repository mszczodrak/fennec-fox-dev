/*
 *  IDEP (Iterative Data Exchane Protocol) network module for Fennec Fox platform.
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
 * Network: IDEP protocol
 * Author: Marcin Szczodrak
 * Date: 9/7/2011
 * Last Modified: 9/12/2011
 */

#include <Fennec.h>

/* entry len: size of a data payload that a single application sents over the network 
 * cluster_size: number of nodes that exchange application data among each other
 */  

generic configuration idepNetC(uint8_t entry_len, uint8_t cluster_size) {
  provides interface Mgmt;
  provides interface Module;
  provides interface NetworkCall;
  provides interface NetworkSignal;

  uses interface MacCall;
  uses interface MacSignal;
}

implementation {

  components new idepNetP(entry_len, cluster_size);
  Mgmt = idepNetP;
  Module = idepNetP;
  NetworkCall = idepNetP;
  NetworkSignal = idepNetP;
  MacCall = idepNetP;
  MacSignal = idepNetP;

  components AddressingC;
  idepNetP.Addressing -> AddressingC.Addressing[F_NETWORK_ADDRESSING];

  components RandomC;
  idepNetP.Random -> RandomC;

  components new TimerMilliC() as Timer0;
  idepNetP.Timer0 -> Timer0;

  components new TimerMilliC() as Timer1;
  idepNetP.Timer1 -> Timer1;
}
