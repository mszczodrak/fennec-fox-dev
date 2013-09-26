/*
 *  trickle network module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
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
 * Network: trickle Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#ifndef __trickle_NET_H_
#define __trickle_NET_H_

enum {
	TRICKLE_DATA = 0x01,
	TRICKLE_BEACON = 0x02,
	TRICKLE_MAX_SEND_DELAY = 10,
	TRICKLE_ID = 0,
};


nx_struct trickle_net_header {
	nxle_uint32_t seq;
};

#endif
