#include <Fennec.h>
#include "DebugMsg.h"

configuration FennecSerialDbgC {
  provides interface SimpleStart;
}

implementation {

  components FennecSerialDbgP;
  SimpleStart = FennecSerialDbgP;

#ifdef __DBGS__
  components SerialActiveMessageC as SerialAM;
  FennecSerialDbgP.SplitControl -> SerialAM;
  FennecSerialDbgP.Receive -> SerialAM.Receive[AM_DEBUG_MSG];
  FennecSerialDbgP.AMSend -> SerialAM.AMSend[AM_DEBUG_MSG];

  components new QueueC(nx_struct debug_msg, DBG_BUFFER_SIZE);
  FennecSerialDbgP.Queue -> QueueC;
#endif

  components LedsC;
  FennecSerialDbgP.Leds -> LedsC;
}

