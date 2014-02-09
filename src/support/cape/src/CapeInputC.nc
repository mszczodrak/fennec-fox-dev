#include "CapeInput.h"

generic configuration CapeInputC() {

provides interface Resource;
provides interface Read<uint16_t> as Read16;
//provides interface Read<uint32_t> as Read32;

}

implementation {

enum {
	CAPE_INPUT_ID = unique(CAPE_INPUT_RESOURCE),
};

components CapeInputP;
Read16 = CapeInputP.Read16[CAPE_INPUT_ID];
//Read32 = CapeInputP.Read32[CAPE_INPUT_ID];

components new SimpleRoundRobinArbiterC(CAPE_INPUT_RESOURCE) as Arbiter;
Resource = Arbiter.Resource[CAPE_INPUT_ID];

}

