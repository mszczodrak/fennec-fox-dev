/*
 *  clusterMedium mac protocol for Fennec Fox platform.
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
 * Application: implementation of clusterMedium
 * Author: Marcin Szczodrak
 * Date: 9/28/2011
 * Last Modified: 9/30/2011
 */

/* p - p-persistent value ; 1 is 0.01 and 100 for 1
 * cluster id - nodes with the same id are in the same cluster
 */
generic configuration clusterMediumMacC(uint8_t p, uint8_t cluster_id) {
  provides interface Mgmt;
  provides interface Module;
  provides interface MacCall;
  provides interface MacSignal;

  uses interface RadioCall;
  uses interface RadioSignal;
}

implementation {
  components new clusterMediumMacP(p, cluster_id);
  Mgmt = clusterMediumMacP;
  Module = clusterMediumMacP;
  MacCall = clusterMediumMacP;
  MacSignal = clusterMediumMacP;
  RadioCall = clusterMediumMacP;
  RadioSignal = clusterMediumMacP;

  components AddressingC;
  clusterMediumMacP.Addressing -> AddressingC.Addressing[F_MAC_ADDRESSING];

  components new TimerMilliC() as BackoffTimer;
  clusterMediumMacP.BackoffTimer -> BackoffTimer;

  components RandomC;
  clusterMediumMacP.Random -> RandomC;

}

