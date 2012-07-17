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

/* States */
#define S_NONE			0
#define S_STOPPED               1
#define S_STARTING              2
#define S_STARTED               3
#define S_STOPPING              4
#define S_TRANSMITTING          5
#define S_LOADING               6
#define S_LOADED                7
#define S_CANCEL                8
#define S_ACK_WAIT              9
#define S_SAMPLE_CCA            10
#define S_SENDING_ACK           11
#define S_NOT_ACKED             12
#define S_BROADCASTING          13
#define S_HALTED                14
#define S_BRIDGE_DELAY          15
#define S_DISCOVER_DELAY        16
#define S_INIT        		17
#define S_SYNC       		18
#define S_SYNC_SEND       	19
#define S_SYNC_RECEIVE  	20
#define S_SEND_DONE		21
#define S_SLEEPING		22
#define S_OPERATIONAL		23
#define S_TURN_ON		24
#define S_TURN_OFF		25
#define S_PREAMBLE		26
#define S_RECEIVING          	27

/* tx */
#define S_SFD                   28
#define S_EFD                   29

/* rx */
#define S_RX_LENGTH             30 
#define S_RX_FCF                31
#define S_RX_PAYLOAD            32

#endif
