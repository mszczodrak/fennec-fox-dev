#ifndef SIM_IRRADIANCE_H
#define SIM_IRRADIANCE_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
	IRRADIANCE_MIN_TRACE = 86400,
	IRRADIANCE_HISTORY_SIZE = 86400,	/* requires 24 hours, with one trace per minute */
};

typedef struct sim_irradiance_node_t {
	float* irradianceTrace;
	int irradianceTraceLen;
	int lastIrradiance;	
	int irradianceTraceIndex;
} sim_irradiance_node_t;

void sim_irradiance_init();
void sim_irradiance_trace_add(uint16_t node_id, float val);

#ifdef __cplusplus
}
#endif


#endif // SIM_IRRADIANCE_H
