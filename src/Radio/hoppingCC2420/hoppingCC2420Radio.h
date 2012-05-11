/*
 *  hoppingCC2420 radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2012 Marcin Szczodrak
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
 * Application: Radio Module for CC2420
 * Author: Marcin Szczodrak
 * Date: 2/9/2012
 * Last Modified: 2/9/2012
 */


#ifndef __H_HOPPING_CC2420_
#define __H_HOPPING_CC2420_

#include "CC2420.h"

#define NUMBER_OF_CHANNELS	16

uint8_t channels[NUMBER_OF_CHANNELS] = {26, 15, 20, 25, 11, 16, 21, 12, 17, 22, 13, 18, 23, 14, 19, 24};
//uint8_t channels[NUMBER_OF_CHANNELS] = {26, 20, 24, 19, 25, 23, 16};
//uint8_t channels[NUMBER_OF_CHANNELS] = {26, 25, 24, 21, 20, 14};
//uint8_t channels[NUMBER_OF_CHANNELS] = {24, 21};
//uint8_t channels[NUMBER_OF_CHANNELS] = {26, 24};
//uint8_t channels[NUMBER_OF_CHANNELS] = {26, 24, 21};

enum {
        HOPPING_CC2420_MIN_MESSAGE_SIZE        	= 5,
        HOPPING_CC2420_MAX_MESSAGE_SIZE        	= 127,
	HOPPING_CC2420_FIRST			= 1,
	HOP_CC_FF_PORT = 33,
};

#endif
