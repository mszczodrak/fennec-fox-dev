
#include "CC2420.h"

configuration CC2420RadioC {
  provides {
    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface LowPowerListening;
    interface PacketLink;

  }
}
implementation {

  components CC2420CsmaC as CsmaC;
  components UniqueSendC;
  components UniqueReceiveC;
  components CC2420PacketC;
  
  components DefaultLplC as LplC;

  components PacketLinkDummyC as LinkC;
  
  PacketLink = LinkC;
  LowPowerListening = LplC;
  CC2420Packet = CC2420PacketC;
  PacketAcknowledgements = CC2420PacketC;
  LinkPacketMetadata = CC2420PacketC;
  
  // SplitControl Layers
  LplC.SubControl -> CsmaC;
  
  UniqueSendC.SubSend -> LinkC;
  LinkC.SubSend -> LplC.Send;
  LplC.SubSend -> CsmaC;
  
  LplC.SubReceive -> UniqueReceiveC.Receive;
  UniqueReceiveC.SubReceive ->  CsmaC;
  
}
