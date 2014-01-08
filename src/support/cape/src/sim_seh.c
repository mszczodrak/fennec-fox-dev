#include <sim_seh.h>

double sehSolarCellSize = SIM_SEH_CELL_SIZE;
double sehSolarCellEfficiency = SIM_SEH_CELL_EFFICIENCY;


double sim_seh_solar_cell_size() __attribute__ ((C, spontaneous)) {
  return sehSolarCellSize;
}
double sim_seh_solar_cell_efficiency() __attribute__ ((C, spontaneous)) {
  return sehSolarCellEfficiency;
}


void sim_seh_set_solar_cell_size(double val) __attribute__ ((C, spontaneous)) {
  sehSolarCellSize = val;
}
void sim_seh_set_solar_cell_efficiency(double val) __attribute__ ((C, spontaneous)) {
  sehSolarCellEfficiency = val;
}

