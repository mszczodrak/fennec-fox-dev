/* Swift Fox generated code for Fennec Fox caches.h */
#ifndef __FF_CACHES_H__
#define __FF_CACHES_H__

#define NUMBER_OF_CONFIGURATIONS  4
#define INTERNAL_POLICY_CONFIGURATION_ID  -1

#define NUMBER_OF_POLICIES  2

#include <Fennec.h>
#include "ff_defaults.h"

#include "ControlUnitAppParams.h"
#include "cuNetParams.h"
#include "cuMacParams.h"
#include "cc2420RadioParams.h"
#include "BlinkAppParams.h"
#include "nullNetParams.h"
#include "csmacaMacParams.h"

uint16_t active_state = 2;

struct fennec_configuration configurations[NUMBER_OF_CONFIGURATIONS] = {
	{
		.application = 0,
		.network = 0,
		.mac = 0,
		.radio = 0,
		.level = 0
	}
	,
	{
		.application = 1,
		.network = 2,
		.mac = 3,
		.radio = 4,
		.level = F_MINIMUM_STATE_LEVEL
	}
	,
	{
		.application = 5,
		.network = 6,
		.mac = 7,
		.radio = 4,
		.level = F_MINIMUM_STATE_LEVEL
	}
	,
	{
		.application = 5,
		.network = 6,
		.mac = 7,
		.radio = 4,
		.level = F_MINIMUM_STATE_LEVEL
	}
};

struct default_params defaults[NUMBER_OF_CONFIGURATIONS] = {
	{
		.application_cache = NULL,
		.network_cache = NULL,
		.mac_cache = NULL,
		.radio_cache = NULL
	}
	,
	{
		.application_cache = &ControlUnitApp_data,
		.application_default_params = &control_ControlUnitApp,
		.application_default_size = sizeof(struct ControlUnitApp_params),
		.network_cache = &cuNet_data,
		.network_default_params = &control_cuNet,
		.network_default_size = sizeof(struct cuNet_params),
		.mac_cache = &cuMac_data,
		.mac_default_params = &control_cuMac,
		.mac_default_size = sizeof(struct cuMac_params),
		.radio_cache = &cc2420Radio_data,
		.radio_default_params = &control_cc2420Radio,
		.radio_default_size = sizeof(struct cc2420Radio_params)
	}
	,
	{
		.application_cache = &BlinkApp_data,
		.application_default_params = &red_BlinkApp,
		.application_default_size = sizeof(struct BlinkApp_params),
		.network_cache = &nullNet_data,
		.network_default_params = &red_nullNet,
		.network_default_size = sizeof(struct nullNet_params),
		.mac_cache = &csmacaMac_data,
		.mac_default_params = &red_csmacaMac,
		.mac_default_size = sizeof(struct csmacaMac_params),
		.radio_cache = &cc2420Radio_data,
		.radio_default_params = &red_cc2420Radio,
		.radio_default_size = sizeof(struct cc2420Radio_params)
	}
	,
	{
		.application_cache = &BlinkApp_data,
		.application_default_params = &yellow_BlinkApp,
		.application_default_size = sizeof(struct BlinkApp_params),
		.network_cache = &nullNet_data,
		.network_default_params = &yellow_nullNet,
		.network_default_size = sizeof(struct nullNet_params),
		.mac_cache = &csmacaMac_data,
		.mac_default_params = &yellow_csmacaMac,
		.mac_default_size = sizeof(struct csmacaMac_params),
		.radio_cache = &cc2420Radio_data,
		.radio_default_params = &yellow_cc2420Radio,
		.radio_default_size = sizeof(struct cc2420Radio_params)
	}
};

struct fennec_event eventsTable[2] = {
	{
		.operation = EQ,
		.value = 10,
		.scale = TYPE_SECOND,
		.addr = 2
	},
	{
		.operation = EQ,
		.value = 10,
		.scale = TYPE_SECOND,
		.addr = 2
	}
};

struct fennec_policy policies[2] = {
	{
		.src_conf = 2,
		.event_mask = 1,
		.dst_conf = 3

	},
	{
		.src_conf = 3,
		.event_mask = 2,
		.dst_conf = 2

	}
};

bool control_unit_support;

nxle_uint16_t event_mask;

#endif

