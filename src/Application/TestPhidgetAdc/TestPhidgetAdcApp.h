/*
 *  ADC Test Application module for Fennec Fox platform.
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
 * Application: ADC Test Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 12/7/2012
 */

#ifndef __TestPhidgetAdc_APP_H_
#define __TestPhidgetAdc_APP_H_

#define GENERIC_APP_ID 1
#define SAMPLE_COUNT_DEFAULT 2
#define SAMPLE_COUNT_MAX  5
#define DEFAULT_FREQ 50

#define APP_NETWORK_QUEUE_SIZE 4
#define APP_SERIAL_QUEUE_SIZE 4

/* this is the application structure that we send across the network */
typedef nx_struct app_network_t {
//  nx_uint16_t src;    	/* address of the node sending sensor samples */
				/* we do not need to send the source address;
				 * we can ask the Network protocol to tell us
				 * from where the message has arrived */
  nx_uint32_t seqno;		/* message sequence number */
  nx_uint8_t sid;		/* sensor ID */
				/* IDs are encoded following the declarations 
				 * from the file src/Fennec/ff_sensors.h */
  nx_uint32_t freq;		/* sampling frequency (ms) */
  nx_uint16_t (COUNT(0) data)[0]; /* place-holder for data */
} app_network_t;


/* this is the application structure that we send across the serial (UART) */
typedef nx_struct app_serial_t {
  nx_uint16_t src;    		/* address of the node sending sensor samples */
  nx_uint32_t seqno;		/* message sequence number */
  nx_uint8_t sid;		/* sensor ID */
				/* IDs are encoded following the declarations 
				 * from the file src/Fennec/ff_sensors.h */
  nx_uint32_t freq;		/* sampling frequency (ms) */
  nx_uint16_t (COUNT(0) data)[0]; /* place-holder for data */
} app_serial_t;


#endif
