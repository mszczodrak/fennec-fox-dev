/*
 *  lpl radio module for Fennec Fox platform.
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
 * Application: LPL Radio Module
 * Author: Marcin Szczodrak
 * Date: 10/12/2011
 * Last Modified: 2/6/2012
 */

#ifndef __H_LPL_
#define __H_LPL_

enum {
	PREAMBLE_RESEND_FREQUENCY	= 2,
	PREAMBLE_MAX_RESEND_DELAY 	= 20,
	MAX_PREAMBLE_RETRIES 		= 600,	
        MAX_LPL_CCA_CHECKS              = 2000,
        MIN_CCA_SAMPLE_TO_DETECT        = 3,
	PREAMBLE_RETRY_OFFSET		= 5,
	LOADED_MESSAGE_AWAKE_DELAY	= 1, /* number of times we extend wakeup 
						period because a message has been
						already loaded */

	LPL_DATA			= 1,
	LPL_WAKEUP			= 2,
	LPL_WAKEUP_ACK			= 4,

	PREAMBLE_REPLY_BACKOFF_FRACTION	= 10, /* 1/4 of active time */
	SUCCESS_WAKEUP_MULTIPLY		= 4,

};

nx_struct lpl_header {
	nx_struct fennec_header fennec;
	nx_uint8_t lpl;
	nx_uint16_t dest;
	nx_uint16_t from;
};

#endif
