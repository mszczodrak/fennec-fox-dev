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

typedef uint16_t state_t;
typedef uint16_t module_t;
typedef uint16_t layer_t;
typedef uint16_t event_t;
typedef uint16_t process_t;

#include <Serial.h>

typedef union message_header {
//  cc2420_header_t cc2420;
  serial_header_t serial;
} message_header_t;


struct state {
        state_t 		state_id;
        uint8_t 		num_processes;
	process_t *		process_list;
	uint8_t 		level;
};


typedef nx_struct metadata_t {
	nx_uint8_t rssi;
	nx_uint8_t lqi;
	nx_uint8_t tx_power;
#ifdef TOSSIM
	nx_uint8_t crc;
	nx_uint8_t ack;
	nx_uint8_t strength;
	nx_uint16_t time;
	nx_uint8_t flags;
#else
	nx_uint8_t flags;
	nx_bool crc;
	nx_bool ack;
#endif
} metadata_t;


typedef nx_struct message_t {
	nx_uint8_t header[sizeof(message_header_t)];
	nx_uint8_t data[FENNEC_MSG_DATA_LEN];
	nx_uint8_t metadata[sizeof(metadata_t)];
//	nx_uint16_t conf;
} message_t;


struct event_module_conf {
	event_t 	event_id;
	module_t 	module_id;
	process_t	process_id;
};

struct network_process {
	process_t process_id;
	uint8_t application;
	uint8_t network;
	uint8_t mac;
	uint8_t radio;
};

struct default_params {
	void 	*application_cache;
	void 	*application_default_params;
	int 	application_default_size;

	void 	*network_cache;
	void 	*network_default_params;
	int 	network_default_size;

	void 	*mac_cache;
	void 	*mac_default_params;
	int 	mac_default_size;

	void 	*radio_cache;
	void 	*radio_default_params;
	int 	radio_default_size;
};


struct fennec_policy {
	uint16_t  src_conf;
	uint16_t event_mask;
	uint16_t  dst_conf;
};



#endif
