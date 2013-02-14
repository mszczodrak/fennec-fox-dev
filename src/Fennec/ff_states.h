/*
 *  Fennec Fox platform.
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
 * author: 	Marcin Szczodrak
 * date:   	10/02/2009
 * last update:	07/16/2012
 */

#ifndef FF_STATES_H
#define FF_STATES_H

typedef enum {
        /* States */
        S_NONE                  = 0,
        S_STOPPED               = 1,
        S_STARTING              = 2,
        S_STARTED               = 3,
        S_STOPPING              = 4,
        S_TRANSMITTING          = 5,
        S_LOADING               = 6,
        S_LOADED                = 7,
        S_CANCEL                = 8,
        S_ACK_WAIT              = 9,
        S_SAMPLE_CCA            = 10,
        S_SENDING_ACK           = 11,
        S_NOT_ACKED             = 12,
        S_BROADCASTING          = 13,
        S_HALTED                = 14,
        S_BRIDGE_DELAY          = 15,
        S_DISCOVER_DELAY        = 16,
        S_INIT                  = 17,
        S_SYNC                  = 18,
        S_SYNC_SEND             = 19,
        S_SYNC_RECEIVE          = 20,
        S_SEND_DONE             = 21,
        S_SLEEPING              = 22,
        S_OPERATIONAL           = 23,
        S_TURN_ON               = 24,
        S_TURN_OFF              = 25,
        S_PREAMBLE              = 26,
        S_RECEIVING             = 27,
	S_BEGIN_TRANSMIT        = 28,
	S_LOAD                  = 29,
	S_RECONFIGURING		= 30,
	S_RECONF_ENABLED	= 31,
        S_COMPLETED		= 32,
	S_BUSY			= 33,
	S_SERIAL		= 34,
	S_NEW_STATE		= 35,
	S_RESET			= 36,


                /* tx */
        S_SFD                   = 40,
        S_EFD                   = 41,

                /* rx */
        S_RX_LENGTH             = 42,
        S_RX_FCF                = 43,
        S_RX_PAYLOAD            = 44,
} fennec_state_t;


#endif
