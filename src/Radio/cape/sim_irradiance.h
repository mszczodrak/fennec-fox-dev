#ifndef SIM_IRRADIANCE_H
#define SIM_IRRADIANCE_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

enum {
	/* one trace per minute */
	IRRADIANCE_MIN_TRACE = 10,
};

typedef struct sim_irradiance_node_t {
	float* irradianceTrace;
	int irradianceTraceLen;
	int irradianceTraceIndex;
	int lastIrradiance;	
} sim_irradiance_node_t;

void sim_irradiance_init();
void sim_irradiance_trace_add(uint16_t node_id, float val);
float sim_irradiance_trace(uint16_t node_id);

#ifdef __cplusplus
}
#endif


#endif // SIM_IRRADIANCE_H
