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

#ifndef FENNEC_H
#define FENNEC_H


#ifdef FENNEC_TOS_PRINTF
#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#ifdef CAPEFOX
#include "printf_cape.h"
#else
#include "printf_default.h"
#endif
#endif

#include "Dbgs.h"
#include "AM.h"

#include "ff_structs.h"
#include "ff_flags.h"
#include "ff_states.h"
#include "ff_sensors.h"
#include "ff_functions.h"
#include "ff_consts.h"

enum {
        OFF                     = 0,
        ON                      = 1,

        UP                      = 0,
        DOWN                    = 1,

        EQ                      = 1,
        NQ                      = 2,
        LT                      = 3,
        LE                      = 4,
        GT                      = 5,
        GE                      = 6,

        CONFIGURATION_SEQ_UNKNOWN = 0,

        MESSAGE_CACHE_LEN       = 25,

	MAX_NUM_EVENTS		= 32,

	NUMBER_OF_ACCEPTING_CONFIGURATIONS = 10,
	ACCEPTING_RESEND	= 2,

        DEFAULT_FENNEC_SENSE_PERIOD = 1024,

	NODE			= 0xfffa,
        BRIDGE                  = 0xfffc,
        UNKNOWN                 = 0xfffd,
        MAX_COST                = 0xfffe,
        BROADCAST               = 0xffff,

	MAX_ADDR_LENGTH		= 8, 		/* in bytes */

	F_MINIMUM_STATE_LEVEL	= 0,


	ANY			= 253,
        UNKNOWN_CONFIGURATION   = 0xfff9,
        UNKNOWN_LAYER           = 255,
	UNKNOWN_ID		= 0xfff0,

                /* Panic Levels */
        PANIC_OK                = 0,
        PANIC_DEAD              = 1,
        PANIC_WARNING           = 2,

	F_NODE			= 20,
	F_BRIDGE		= 21,
	F_BASE_STATION		= 22,

	F_SYSTEM		= 23,
	F_MEMORY		= 24,
	F_SENSOR		= 25,

        FENNEC_SYSTEM_FLAGS_NUM = 30,
	POLICY_CONFIGURATION	= 250,
//	POLICY_CONF_ID		= 1,
};

/* Forces a change in configuration */
void force_new_configuration(uint8_t new_conf);

uint16_t get_next_module(module_t module_id, uint8_t way);

uint16_t get_module_id(module_t module_id, conf_t conf_id, layer_t layer_id);

state_t get_state_id();
conf_t get_conf_id();

conf_t get_active_state();

bool dbgs(uint8_t layer, uint8_t state, uint16_t action, uint16_t d0, uint16_t d1);

metadata_t* getMetadata( message_t* msg );

#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))

#include "message.h"
#include <Ieee154.h>


#endif
