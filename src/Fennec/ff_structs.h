/*
 *  Fennec Fox structures
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

#ifndef FF_STRUCTURES_H
#define FF_STRUCTURES_H

#include "ff_consts.h"
#include "ff_sensor_ids.h"
#include "ff_sensor_type.h"

typedef uint16_t state_t;
typedef uint16_t conf_t;
typedef uint16_t module_t;
typedef uint16_t layer_t;


typedef nx_struct fennec_header_t {
  nxle_uint8_t length;
  nxle_uint16_t fcf;
  nxle_uint8_t dsn;
  nxle_uint16_t destpan;
  nxle_uint16_t dest;
  nxle_uint16_t src;
} fennec_header_t;



#include <Serial.h>

typedef union message_header {
//  cc2420_header_t cc2420;
  serial_header_t serial;
} message_header_t;


typedef struct ff_sensor_conf {
	uint32_t sensitivity;
	uint32_t rate;
	uint8_t signaling;
	uint8_t channel;
} ff_sensor_conf_t;

typedef struct ff_sensor_data {
	uint8_t size;
	uint32_t seq;
	void *raw;
	void *calibrated;
	sensor_type_t type;
	sensor_id_t id;
} ff_sensor_data_t;

typedef struct ff_sensor_client {
	uint8_t id;
	uint8_t read;
	uint32_t rate;
	uint32_t signaling;
} ff_sensor_client_t;


typedef nx_struct metadata_t {
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t tx_power;
//#ifdef TOSSIM
  nx_uint8_t crc;
  nx_uint8_t ack;
  nx_uint8_t timesync;
#else
  nx_bool crc;
  nx_bool ack;
  nx_bool timesync;
#endif
  nx_uint32_t timestamp;
  nx_uint16_t rxInterval;
  nx_uint16_t maxRetries;
  nx_uint16_t retryDelay;
} metadata_t;


typedef nx_struct message_t {
  nx_uint8_t header[sizeof(message_header_t)];
  nx_uint8_t data[FENNEC_MSG_DATA_LEN];
  nx_uint8_t metadata[sizeof(metadata_t)];
  nx_uint16_t conf;
  nx_uint8_t rssi;
  nx_uint8_t lqi;
  nx_uint8_t crc;
  nx_uint8_t ack;
  nx_uint16_t rxInterval;
} message_t;




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

struct fennec_policy {
	uint8_t  src_conf;
	uint16_t event_mask;
	uint8_t  dst_conf;
};

struct fennec_event {
	uint8_t operation;
	uint16_t value;
	uint8_t scale;
	am_addr_t addr;
};

nx_struct accept_conf {
	fennec_header_t fennec;
	nx_uint8_t vnet_id;
	nx_uint8_t local_conf;
};

#ifdef TOSSIM

#include <TossimRadioMsg.h>

#endif



#endif
