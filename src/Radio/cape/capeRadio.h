/*
 *  Null radio module for Fennec Fox platform.
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
 * Network: Null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#ifndef __H_cape_RADIO__
#define __H_cape_RADIO___


nx_struct cape_radio_header_t {
        nxle_uint8_t length;
};

typedef nx_struct cape_hdr_t {
        nxle_uint8_t length;
        nxle_uint16_t fcf;
        nxle_uint8_t dsn;
        nxle_uint16_t destpan;
        nxle_uint16_t dest;
        nxle_uint16_t src;
} cape_hdr_t;



enum {
        CAPE_MIN_MESSAGE_SIZE         = 10,
        CAPE_MAX_MESSAGE_SIZE         = 128,
        CAPE_MAX_FAILED_LOADS         = 3,
        CAPE_FOOTER                   = 2,
        CAPE_SIZEOF_CRC               = 2,
};

typedef uint32_t timesync_radio_t;

#endif
