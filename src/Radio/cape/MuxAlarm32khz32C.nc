#include <MicaTimer.h>

generic configuration MuxAlarm32khz32C()
{
  provides interface Alarm<T32khz, uint32_t>;
}
implementation
{
  components new TimerMilliC();
  components new MuxAlarm32khz32P();

  Alarm = MuxAlarm32khz32P;
  MuxAlarm32khz32P.Timer -> TimerMilliC;
}
