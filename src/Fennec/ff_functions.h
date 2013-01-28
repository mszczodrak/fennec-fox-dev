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

#ifndef FF_FUNCTIONS_H
#define FF_FUNCTIONS_H

#include "message.h"

#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))
/* Forces a change in configuration */
void force_new_configuration(uint8_t new_conf);

uint16_t get_next_module(module_t module_id, uint8_t way);

uint16_t get_module_id(module_t module_id, conf_t conf_id, layer_t layer_id);

state_t get_state_id();
conf_t get_conf_id();

conf_t get_active_state();

void check_configuration(conf_t conf_id);

metadata_t* getMetadata( message_t* msg );


void PacketTimeStampclear(message_t* msg);
void PacketTimeStampset(message_t* msg, uint32_t value);
bool PacketTimeSyncOffsetisSet(message_t* msg);

uint8_t PacketTimeSyncOffsetget(message_t* msg);

uint32_t gcdr (uint32_t a, uint32_t b )@C() {
        if ( a==0 ) return b;
        return gcdr ( b%a, a );
}


/* Debugging functions */
bool dbgs(uint8_t layer, uint8_t state, uint16_t action, uint16_t d0, uint16_t d1);
void insertLog(uint16_t from, uint16_t message);
void cleanLog();
void printLog();



#endif
