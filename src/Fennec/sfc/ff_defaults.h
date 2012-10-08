#ifndef _FF_DEFAULTS_H_
#define _FF_DEFAULTS_H_

#include <Fennec.h>
#include "ControlUnitAppParams.h"
#include "cuNetParams.h"
#include "cuMacParams.h"
#include "cc2420RadioParams.h"
#include "BlinkAppParams.h"
#include "nullNetParams.h"
#include "csmacaMacParams.h"
#include "tdmaMacParams.h"
#include "nullAppParams.h"
#include "nullMacParams.h"
#include "nullRadioParams.h"

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
struct BlinkApp_params yellow_BlinkApp = {
	2,
	1024
};
struct nullNet_params yellow_nullNet = {
};
struct tdmaMac_params yellow_tdmaMac = {
	2,
	10000,
	300000,
	10,
	10,
	1,
	1,
	1
};
struct cc2420Radio_params yellow_cc2420Radio = {
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
struct nullApp_params dark_nullApp = {
};
struct nullNet_params dark_nullNet = {
};
struct nullMac_params dark_nullMac = {
};
struct nullRadio_params dark_nullRadio = {
};
#endif

