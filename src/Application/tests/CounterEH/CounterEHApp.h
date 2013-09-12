/*
 *  Counter test application module for Fennec Fox platform.
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
 * Network: Counter test Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#ifndef __CounterEH_APP_H_
#define __CounterEH_APP_H_

#define COUNTER_DATA_LENGTH 100

#include <AM.h>

enum {
 AM_TESTNETWORKMSG = 0x05,
 SAMPLE_RATE_KEY = 0x1,
 CL_TEST = 0xee,
 TEST_NETWORK_QUEUE_SIZE = 8,
};

typedef nx_struct CounterMsg {
  nx_am_addr_t source;
  nx_uint16_t seqno;
  nx_uint8_t data[COUNTER_DATA_LENGTH];
} CounterMsg;

#endif
