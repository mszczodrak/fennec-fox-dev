#ifndef SEH_H_INCLUDED
#define SEH_H_INCLUDED

class SEH {
 public:
  SEH();
  ~SEH();

  double solarCellSize();
  double solarCellEfficiency();
  
  void setSolarCellSize(double val);
  void setSolarCellEfficiency(double val);
};

#endif
