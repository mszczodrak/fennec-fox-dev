#ifndef SIM_IRRADIANCE_H
#define SIM_IRRADIANCE_H

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void sim_irradiance_init();
void sim_irradiance_trace_add(uint16_t node_id, double val);
double sim_irradiance_trace(uint16_t node_id);

#ifdef __cplusplus
}
#endif


#endif // SIM_IRRADIANCE_H
