#include "CC2420.h"
#include "AM.h"
#include "Ieee154.h"

#ifdef IEEE154FRAMES_ENABLED
#error "CC2420 AM layer cannot work when IEEE 802.15.4 frames only are used"
#endif

configuration CC2420ActiveMessageC {
  provides {
    interface SplitControl;
    interface AMSend;
    interface Receive;
    interface Receive as Snoop;
    interface AMPacket;
    interface Packet;
    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface LowPowerListening;
    interface PacketLink;
  }
}
implementation {
  enum {
    CC2420_AM_SEND_ID     = unique(RADIO_SEND_RESOURCE),
  };

  components CC2420RadioC as Radio;
  components CC2420ActiveMessageP as AM;
  components ActiveMessageAddressC;
  components CC2420CsmaC as CsmaC;
  components CC2420PacketC;
  
  SplitControl = Radio;
  Packet = AM;
  AMSend = AM;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;
  PacketLink = Radio;
  LowPowerListening = Radio;
  CC2420Packet = Radio;
  PacketAcknowledgements = Radio;
  LinkPacketMetadata = Radio;
  
  // Radio resource for the AM layer
  AM.RadioResource -> Radio.Resource[CC2420_AM_SEND_ID];
  AM.SubSend -> Radio.ActiveSend;
  AM.SubReceive -> Radio.ActiveReceive;

  AM.ActiveMessageAddress -> ActiveMessageAddressC;
  AM.CC2420Packet -> CC2420PacketC;
  AM.CC2420PacketBody -> CC2420PacketC;
  
  AM.SubBackoff -> CsmaC;

  components LedsC;
  AM.Leds -> LedsC;
}
