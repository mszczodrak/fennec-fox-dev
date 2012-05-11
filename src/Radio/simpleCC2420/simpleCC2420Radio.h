/*
 *  simpleCC2420 radio module for Fennec Fox platform.
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
 * Date: 9/29/2009
 * Last Modified: 1/29/2012
 */


#ifndef __H_SIMPLE_CC2420_
#define __H_SIMPLE_CC2420_

#include "CC2420.h"

enum {
        SIMPLE_CC2420_MIN_MESSAGE_SIZE        	= 5,
        SIMPLE_CC2420_MAX_MESSAGE_SIZE        	= 127,
	SIMPLE_CC2420_FIRST			= 1,
};

#endif
