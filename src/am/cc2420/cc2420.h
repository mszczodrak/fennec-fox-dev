#ifndef __cc2420_H_
#define __cc2420_H_

#if defined(PLATFORM_Z1)
typedef TMicro TRadio;
typedef uint16_t tradio_size;
#else
#include <RadioConfig.h>
#endif

#endif
