/*
 *  GOALI-Distributed application for Fennec Fox platform.
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
 * Application: GOALI project centralized application
 * Author: Marcin Szczodrak
 * Date: 8/15/2011
 * Last Modified: 8/15/2011
 */

generic configuration GOALIDistributedJacobiAppC(uint16_t delay) {
  provides interface Mgmt;
  provides interface Module;
  uses interface NetworkCall;
  uses interface NetworkSignal;
}

implementation {
  components new GOALIDistributedJacobiAppP(delay);
  Mgmt = GOALIDistributedJacobiAppP;
  Module = GOALIDistributedJacobiAppP;
  NetworkCall = GOALIDistributedJacobiAppP;
  NetworkSignal = GOALIDistributedJacobiAppP;

  components LedsC;
  GOALIDistributedJacobiAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  GOALIDistributedJacobiAppP.Timer0 -> Timer0;

  components new TimerMilliC() as Timer1;
  GOALIDistributedJacobiAppP.Timer1 -> Timer1;

  components FennecSerialC;
  GOALIDistributedJacobiAppP.Serial -> FennecSerialC;

  components OccupancyC;
  GOALIDistributedJacobiAppP.Occupancy -> OccupancyC;

  components GOALIDistributedAppP;
  GOALIDistributedJacobiAppP.GOALIBuffer -> GOALIDistributedAppP;

}
