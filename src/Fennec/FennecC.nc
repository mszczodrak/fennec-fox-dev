/*
 * @author: Marcin Szczodrak
 * @date:   11/24/2009
 *
 */

#include <Fennec.h>

configuration FennecC {
}

implementation {

  components FennecP;

  components MainC;
  FennecP.Boot -> MainC;

  components RandomC;
  FennecP.RandomStart -> RandomC;

  components CachesC;
  FennecP.Caches -> CachesC;

  components ControlUnitC;
  FennecP.PolicyStart -> ControlUnitC;

  components FennecSerialDbgC;
  FennecP.DbgSerial -> FennecSerialDbgC;

#ifdef FENNEC_TOS_PRINTF
  components PrintfC;
  components SerialStartC;
#endif

  components FennecPacketC;
}

