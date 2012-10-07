#ifndef _FF_DEFAULTS_H_
#define _FF_DEFAULTS_H_

#include <Fennec.h>
#include "ControlUnitAppParams.h"
#include "cuNetParams.h"
#include "cuMacParams.h"
#include "cc2420RadioParams.h"
#include "nullAppParams.h"
#include "nullNetParams.h"
#include "tdmaMacParams.h"

struct ControlUnitApp_params control_ControlUnitApp = {
};
struct cuNet_params control_cuNet = {
};
struct cuMac_params control_cuMac = {
	10,
	10,
	1,
	1,
	1
};
struct cc2420Radio_params control_cc2420Radio = {
	26,
	31,
	1,
	1
};
struct nullApp_params count_nullApp = {
};
struct nullNet_params count_nullNet = {
};
struct tdmaMac_params count_tdmaMac = {
	2,
	100,
	30,
	300,
	10,
	10,
	1,
	1,
	1
};
struct cc2420Radio_params count_cc2420Radio = {
	26,
	31,
	1,
	1
};
#endif

