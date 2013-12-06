/*
 *  UARTBridge application module for Fennec Fox platform.
 *
 *  Copyright (C) 2013 Marcin Szczodrak
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
 * Application: UARTBridge Application Module
 * Author: Marcin Szczodrak
 * Date: 10/01/2013
 * Last Modified: 10/09/2013
 */

#ifndef __UARTBridge_APP_H_
#define __UARTBridge_APP_H_

#define APP_SERIAL_QUEUE_SIZE           10
#define BRIDGE_MAX_PAYLOAD_SIZE		120

typedef struct msg_queue_t {
	uint8_t len;
	uint8_t data[BRIDGE_MAX_PAYLOAD_SIZE];
} msg_queue_t;



#endif
