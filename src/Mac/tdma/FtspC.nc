#include "Ftsp.h"

configuration FtspC {
}

implementation {
  components MainC, TimeSyncC;

  MainC.SoftwareInit -> TimeSyncC;
  TimeSyncC.Boot -> MainC;

  components FtspP;
  FtspP.Boot -> MainC;

  components ActiveMessageC;
  FtspP.RadioControl -> ActiveMessageC;
  FtspP.Receive -> ActiveMessageC.Receive[111];
  FtspP.AMSend -> ActiveMessageC.AMSend[111];
  FtspP.Packet -> ActiveMessageC;
  FtspP.PacketTimeStamp -> ActiveMessageC;

  FtspP.GlobalTime -> TimeSyncC;
  FtspP.TimeSyncInfo -> TimeSyncC;

}

