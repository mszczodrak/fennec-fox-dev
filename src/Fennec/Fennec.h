/*
 * Copyright (c) 2008-2011 Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Columbia University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COLUMBIA
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * author: Marcin Szczodrak
 * date:   1/1/2011
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

typedef uint16_t state_t;
typedef uint16_t conf_t;
typedef uint16_t module_t;
typedef uint16_t layer_t;

nx_struct fennec_header {
  nx_uint8_t len;
  nx_uint8_t conf;
};


typedef nx_struct msg_t {
  nx_uint8_t data[128];
  nx_uint8_t len;
  nx_uint16_t next_hop;
  nx_uint8_t ack;
  nx_uint8_t crc;
  nx_uint8_t asap;
  nx_struct fennec_header fennec;
  nx_uint8_t channel;
  nx_uint8_t vnet_id;
  nx_uint8_t last_layer;
  nx_uint8_t rssi;
  nx_uint8_t lqi;
} msg_t;


nx_struct FFControl {
  /* source of the of the configuration - variable based on Addressing */
  nx_uint16_t crc;
  nx_uint16_t seq;            /* sequence number of the configuration */
//  nx_uint8_t vnet_id;         /* virtual network id */
  nx_uint16_t conf_id;
//  nx_uint8_t accepts;         /* number of new additional accepting configurations */
  /* array of new accepts */
};

struct fennec_configuration {
  uint8_t application;
  uint8_t network;
  uint8_t mac;
  uint8_t radio;
  uint8_t level;
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


struct configuration_cache {
  uint8_t *app;
  uint32_t app_len;
  uint8_t *net;
  uint32_t net_len;
  uint8_t *qoi;
  uint32_t qoi_len;
  uint8_t *mac;
  uint32_t mac_len;
  uint8_t *radio;
  uint32_t radio_len;
};

nx_struct fennec_policy {
  nxle_uint8_t  src_conf;
  nxle_uint16_t event_mask;
  nxle_uint8_t  dst_conf;
};

struct fennec_event {
  uint8_t operation;
  uint16_t value;
  char *scale;
  am_addr_t addr;
};

nx_struct accept_conf {
  nx_struct fennec_header fennec;
  nx_uint8_t vnet_id;
  nx_uint8_t local_conf;
};

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

        /* States */
	S_NONE			= 0,
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
        S_INIT        		= 17,
        S_SYNC       		= 18,
        S_SYNC_SEND       	= 19,
        S_SYNC_RECEIVE  	= 20,
	S_SEND_DONE		= 21,
	S_SLEEPING		= 22,
	S_OPERATIONAL		= 23,
	S_TURN_ON		= 24,
	S_TURN_OFF		= 25,
	S_PREAMBLE		= 26,
        S_RECEIVING          	= 27,

                /* tx */
        S_SFD                   = 28,
        S_EFD                   = 29,

                /* rx */
        S_RX_LENGTH             = 30, 
        S_RX_FCF                = 31,
        S_RX_PAYLOAD            = 32,


                /* Panic Levels */
        PANIC_OK                = 0,
        PANIC_DEAD              = 1,
        PANIC_WARNING           = 2,

                /* Fennec System Flags */
        F_RADIO                 = 1,
        F_ADDRESSING		= 2,
        F_MAC                   = 3,
        F_QOI                   = 4,
        F_NETWORK               = 5,
        F_APPLICATION           = 6,
        F_EVENTS                = 7,
        F_MAC_ADDRESSING	= 8,
        F_NETWORK_ADDRESSING	= 9,

        F_ENGINE                = 10,
	F_CONTROL_UNIT		= 11,
        F_PRINTING              = 12,
        F_SENDING               = 13,
        F_BRIDGING              = 14,
        F_DATA_SRC              = 15,
	F_NEW_ADDR		= 16,

	F_NODE			= 20,
	F_BRIDGE		= 21,
	F_BASE_STATION		= 22,

	F_SYSTEM		= 23,
	F_MEMORY		= 24,

        FENNEC_SYSTEM_FLAGS_NUM = 30,
	POLICY_CONFIGURATION	= 250,
};

/* Forces a change in configuration */
void force_new_configuration(uint8_t new_conf);

uint16_t get_next_module(module_t module_id, uint8_t way);

uint16_t get_module_id(state_t state_id, conf_t conf_id, layer_t layer_id);

state_t get_state_id();
conf_t get_conf_id();

conf_t get_active_state();

bool dbgs(uint8_t layer, uint8_t state, uint16_t action, uint16_t d0, uint16_t d1);


#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))



#endif
