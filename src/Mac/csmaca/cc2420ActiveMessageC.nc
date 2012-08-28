#include "CC2420.h"
#include "AM.h"
#include "Ieee154.h"

#ifdef IEEE154FRAMES_ENABLED
#error "CC2420 AM layer cannot work when IEEE 802.15.4 frames only are used"
#endif

configuration cc2420ActiveMessageC {
  provides {
    interface AMSend;
  }

  uses interface Packet as MacPacket;
  uses interface AMPacket as MacAMPacket;
}
implementation {
  enum {
    CC2420_AM_SEND_ID     = unique(RADIO_SEND_RESOURCE),
  };

  components CC2420RadioC as Radio;
  components cc2420ActiveMessageP as AM;
  components CC2420CsmaC as CsmaC;
  
  MacPacket = AM;
  AMSend = AM;
  MacAMPacket = AM;
  
  AM.RadioResource -> Radio.Resource[CC2420_AM_SEND_ID];

  components CC2420TinyosNetworkC;
  AM.SubSend -> CC2420TinyosNetworkC.ActiveSend;

  components LedsC;
  AM.Leds -> LedsC;

  components CC2420PacketC;
  AM.CC2420Packet -> CC2420PacketC;
  AM.CC2420PacketBody -> CC2420PacketC;

}
