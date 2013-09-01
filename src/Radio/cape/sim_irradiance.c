

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <time.h>

#include "sim_irradiance.h"

sim_irradiance_node_t irradianceData[TOSSIM_MAX_NODES];

void sim_irradiance_init()__attribute__ ((C, spontaneous))
{
  int j;

  printf("Starting\n");

  for (j=0; j< TOSSIM_MAX_NODES; j++) {
//    irradianceData[j].irradianceTable = create_hashtable(NOISE_HASHTABLE_SIZE, sim_irradiance_hash, sim_irradiance_eq);
//    irradianceData[j].irradianceGenTime = 0;
    irradianceData[j].irradianceTrace = (float*)(malloc(sizeof(float) * IRRADIANCE_MIN_TRACE));
    irradianceData[j].irradianceTraceLen = IRRADIANCE_MIN_TRACE;
    irradianceData[j].irradianceTraceIndex = 0;
  }
  printf("Done with sim_irradiance_init()\n");
}

void sim_irradiance_trace_add(uint16_t node_id, float irradianceVal)__attribute__ ((C, spontaneous)) {
  // Need to double size of trace arra
  if (irradianceData[node_id].irradianceTraceIndex ==
      irradianceData[node_id].irradianceTraceLen) {
    float* data = (float*)(malloc(sizeof(float) * irradianceData[node_id].irradianceTraceLen * 2));
    memcpy(data, irradianceData[node_id].irradianceTrace, irradianceData[node_id].irradianceTraceLen);
    free(irradianceData[node_id].irradianceTrace);
    irradianceData[node_id].irradianceTraceLen *= 2;
    irradianceData[node_id].irradianceTrace = data;
  }
  irradianceData[node_id].irradianceTrace[irradianceData[node_id].irradianceTraceIndex] = irradianceVal;
  irradianceData[node_id].irradianceTraceIndex++;
  dbg("Insert", "Adding irradiance value %i for %i of %i\n", (int)irradianceData[node_id].irradianceTraceIndex, (int)node_id, (int)irradianceVal);
}

