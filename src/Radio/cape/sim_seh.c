#include <sim_seh.h>

int sehSolarCellSize = SIM_SEH_CELL_SIZE;
int sehSolarCellEfficiency = SIM_SEH_CELL_EFFICIENCY;


int sim_seh_solar_cell_size() __attribute__ ((C, spontaneous)) {
  return sehSolarCellSize;
}
int sim_seh_solar_cell_efficiency() __attribute__ ((C, spontaneous)) {
  return sehSolarCellEfficiency;
}


void sim_seh_set_solar_cell_size(int val) __attribute__ ((C, spontaneous)) {
  sehSolarCellSize = val;
}
void sim_seh_set_solar_cell_efficiency(int val) __attribute__ ((C, spontaneous)) {
  sehSolarCellEfficiency = val;
}

