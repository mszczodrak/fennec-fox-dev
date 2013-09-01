#ifndef SIM_SEH_H_INCLUDED
#define SIM_SEH_H_INCLUDED

#ifndef SIM_SEH_CELL_SIZE
#define SIM_SEH_CELL_SIZE 8	/* in cm^2 */
#endif 

#ifndef SIM_SEH_CELL_EFFICIENCY
#define SIM_SEH_CELL_EFFICIENCY	20	/* in % */
#endif

#ifdef __cplusplus
extern "C" {
#endif

  int sim_seh_solar_cell_size();
  int sim_seh_solar_cell_efficiency();
  
  void sim_seh_set_solar_cell_size(int val);
  void sim_seh_set_solar_cell_efficiency(int val);
  
#ifdef __cplusplus
}
#endif
  
#endif // SIM_TOSSIM_H_INCLUDED
