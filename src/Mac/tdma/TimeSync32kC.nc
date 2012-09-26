
#include "TimeSyncMsg.h"

configuration TimeSync32kC
{
  uses interface tdmaMacParams;
  provides interface StdControl;
  provides interface GlobalTime<T32khz>;

  //interfaces for extra functionality: need not to be wired
  provides interface TimeSyncInfo;
  provides interface TimeSyncMode;
  provides interface TimeSyncNotify;
}

implementation
{
  components new TimeSyncP(T32khz) as TimeSyncP;
  tdmaMacParams = TimeSyncP;

  GlobalTime      =   TimeSyncP;
  StdControl      =   TimeSyncP;
  TimeSyncInfo    =   TimeSyncP;
  TimeSyncMode    =   TimeSyncP;
  TimeSyncNotify  =   TimeSyncP;

  components TimeSyncMessageC as ActiveMessageC;
  TimeSyncP.Send            ->  ActiveMessageC.TimeSyncAMSend32khz[TIMESYNC_AM_FTSP];
  TimeSyncP.Receive         ->  ActiveMessageC.Receive[TIMESYNC_AM_FTSP];
  TimeSyncP.TimeSyncPacket  ->  ActiveMessageC;

  components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC;
  LocalTime32khzC.Counter -> Counter32khz32C;
  TimeSyncP.LocalTime     -> LocalTime32khzC;

  components new TimerMilliC() as TimerC;
  TimeSyncP.Timer ->  TimerC;

  components RandomC;
  TimeSyncP.Random -> RandomC;
  
#if defined(TIMESYNC_LEDS)
  components LedsC;
#else
  components NoLedsC as LedsC;
#endif
  TimeSyncP.Leds  ->  LedsC;

}
