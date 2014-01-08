#ifndef SIM_SEH_H_INCLUDED
#define SIM_SEH_H_INCLUDED

#ifndef SIM_SEH_CELL_SIZE
#define SIM_SEH_CELL_SIZE 0.0008	/* in m^2 */
#endif 

#ifndef SIM_SEH_CELL_EFFICIENCY
#define SIM_SEH_CELL_EFFICIENCY	0.20	/* in % */
#endif

#ifdef __cplusplus
extern "C" {
#endif

  double sim_seh_solar_cell_size();
  double sim_seh_solar_cell_efficiency();
  
  void sim_seh_set_solar_cell_size(double val);
  void sim_seh_set_solar_cell_efficiency(double val);
  
#ifdef __cplusplus
}
#endif
  
#endif // SIM_TOSSIM_H_INCLUDED
