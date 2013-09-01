#ifndef SEH_H_INCLUDED
#define SEH_H_INCLUDED

class SEH {
 public:
  SEH();
  ~SEH();

  int solarCellSize();
  int solarCellEfficiency();
  
  void setSolarCellSize(int val);
  void setSolarCellEfficiency(int val);
};

#endif
