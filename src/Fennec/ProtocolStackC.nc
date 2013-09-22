/*
 *  Fennec Fox platform.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
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
 * author:      Marcin Szczodrak
 * date:        10/02/2009
 * last update: 02/14/2013
 */


configuration ProtocolStackC {
//provides interface Mgmt;
provides interface ProtocolStack;
}

implementation {

components ProtocolStackP;
//Mgmt = ProtocolStackP.Mgmt;
ProtocolStack = ProtocolStackP;

components FennecEngineC;
ProtocolStackP.ModuleCtrl -> FennecEngineC;

components new TimerMilliC() as Timer;
ProtocolStackP.Timer -> Timer;

components LedsC;
ProtocolStackP.Leds -> LedsC;

components CachesC;
ProtocolStackP.Fennec -> CachesC;


}
