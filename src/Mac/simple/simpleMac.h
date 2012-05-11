/*
 *  SimpleMac protocol for Fennec Fox platform.
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
 * Application: implementation of simple MAC protocol, just sends
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/4/2011
 */

#ifndef __SIMPLE_MAC_H__
#define __SIMPLE_MAC_H__


/*
  Simple Mac header
  
  +----------------+-------+
  |  fennec_header |  len  |
  +----------------+-------+

*/

nx_struct simpleMac_mac_footer {
  nx_uint16_t footer;
};

#endif
