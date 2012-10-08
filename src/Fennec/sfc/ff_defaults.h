#ifndef _FF_DEFAULTS_H_
#define _FF_DEFAULTS_H_

#include <Fennec.h>
#include "ControlUnitAppParams.h"
#include "cuNetParams.h"
#include "csmacaMacParams.h"
#include "cc2420RadioParams.h"
#include "BlinkAppParams.h"
#include "nullNetParams.h"

struct ControlUnitApp_params control_ControlUnitApp = {
};
struct cuNet_params control_cuNet = {
};
struct csmacaMac_params control_csmacaMac = {
	2,
	0,
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
struct BlinkApp_params red_BlinkApp = {
	1,
	1024
};
struct nullNet_params red_nullNet = {
};
struct csmacaMac_params red_csmacaMac = {
	2,
	0,
	10,
	10,
	1,
	1,
	1
};
struct cc2420Radio_params red_cc2420Radio = {
	26,
	31,
	1,
	1
};
struct BlinkApp_params blue_BlinkApp = {
	4,
	1024
};
struct nullNet_params blue_nullNet = {
};
struct csmacaMac_params blue_csmacaMac = {
	2,
	200,
	10,
	10,
	1,
	1,
	1
};
struct cc2420Radio_params blue_cc2420Radio = {
	26,
	31,
	1,
	1
};
#endif

