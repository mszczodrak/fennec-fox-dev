#include "CapeInput.h"

generic component CapeInputC() {

provides interface Resource;
provides interface Read<uint16_t> as Read16;
//provides interface Read<uint32_t> as Read32;

}

implementation {

enum {
	CAPE_INPUT_ID = unique(CAPE_INPUT_RESOURCE),
};

components new CapeInputP();
Read16 = CapeInputP.Read16[ID];
//Read32 = CapeInputP.Read32[ID];

components new SimpleRoundRobinArbiterC(CAPE_INPUT_RESOURCE) as Arbiter;
Resource = Arbiter.Resource[ID];

}

