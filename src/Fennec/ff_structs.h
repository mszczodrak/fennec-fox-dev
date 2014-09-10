/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox structs
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#ifndef FF_STRUCTURES_H
#define FF_STRUCTURES_H

#include "ff_consts.h"
#include "platform_message.h"
#include "global_data.h"
#include "local_data.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 127
#endif

#ifndef TOS_BCAST_ADDR
#define TOS_BCAST_ADDR 0xFFFF
#endif

#define RADIO_SEND_RESOURCE "RADIO_SEND_RESOURCE"

typedef uint8_t state_t;
typedef uint8_t module_t;
typedef uint8_t layer_t;
typedef uint8_t event_t;
typedef uint8_t process_t;

struct variable_reference {
	uint8_t	var_id;
	void*	ptr;
}; 

struct variable_info {
	uint8_t var_id;
	uint8_t offset;
	uint8_t size;
};

struct network_process {
	process_t process_id;
	uint8_t application;
	uint8_t network;
	uint8_t am;
	uint8_t application_module;
	uint8_t application_variables_number;
	uint8_t application_variables_offset;
	uint8_t network_module;
	uint8_t network_variables_number;
	uint8_t network_variables_offset;
	uint8_t am_module;
	uint8_t am_variables_number;
	uint8_t am_variables_offset;
	bool am_level;
};

struct state {
        state_t 		state_id;
	struct network_process **processes;
	uint8_t 		level;
};

struct event_process {
	event_t 	event_id;
	process_t	process_id;
};

struct fennec_policy {
	uint16_t  src_conf;
	uint16_t event_mask;
	uint16_t  dst_conf;
};

#endif
