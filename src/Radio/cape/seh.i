%module TOSSIMSEH

%{
#include <seh.h>
%}

class SEH {
 public:
  SEH();
  ~SEH();

  int solarCellSize();
  int solarCellEfficiency();

/*
  int high();
  int low();
  int symbolsPerSec();
  int bitsPerSymbol();
  int preambleLength();
  int exponentBase();
  int maxIterations();
  int minFreeSamples();
  int rxtxDelay();
  int ackTime(); 
*/
  
  void setSolarCellSize(int val);
  void setSolarCellEfficiency(int val);
/*
  void setHigh(int val);
  void setLow(int val);
  void setSymbolsPerSec(int val);
  void setBitsBerSymbol(int val);
  void setPreambleLength(int val);
  void setExponentBase(int val);
  void setMaxIterations(int val);
  void setMinFreeSamples(int val);
  void setRxtxDelay(int val);
  void setAckTime(int val);
*/
};
