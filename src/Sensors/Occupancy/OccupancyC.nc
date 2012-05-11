/*
 *  Occupancy Sensor for Fennec Fox platform.
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
 * Sensor: Occupancy
 * Author: Marcin Szczodrak
 * Date: 8/15/2011
 * Last Modified: 8/15/2011
 */

configuration OccupancyC {
  provides interface Read<uint16_t>;
}

implementation {

  components OccupancyP;
  Read = OccupancyP;

  components VirtualOccupancySensorC;
  OccupancyP.VirtualOccupancy -> VirtualOccupancySensorC;

}
