configuration ActiveMessageC {
  provides {
    interface SplitControl;

    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];

    interface Packet;
    interface AMPacket;
    interface PacketAcknowledgements;
  }
}
implementation {
  components CapeActiveMessageC as AM;
  components TossimPacketModelC as Network;

  components CpmModelC as Model;

  SplitControl = Network;
  
  AMSend       = AM;
  Receive      = AM.Receive;
  Snoop        = AM.Snoop;
  Packet       = AM;
  AMPacket     = AM;
  PacketAcknowledgements = Network;

  //AM.Model -> Network.Packet;
  
  //Network.GainRadioModel -> Model;
}

