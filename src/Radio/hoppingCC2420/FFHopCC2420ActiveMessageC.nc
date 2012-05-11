#include "CC2420.h"
#include "AM.h"
#include "Ieee154.h"
#include "hoppingCC2420Radio.h"

generic configuration FFHopCC2420ActiveMessageC(am_addr_t sink,
						uint8_t number_of_channels,
                                                uint16_t channel_lifetime,
                                                bool speedup_receive,
						bool use_ack) {

  provides interface Mgmt;
  provides interface ModuleStatus as RadioStatus;

  provides {
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface CC2420Packet;
    interface PacketAcknowledgements;
    interface LinkPacketMetadata;
    interface RadioBackoff[am_id_t amId];
    interface LowPowerListening;
    interface PacketLink;
    interface SendNotifier[am_id_t amId];
  }
}
implementation {
  enum {
    CC2420_AM_SEND_ID     = unique(RADIO_SEND_RESOURCE),
  };

  components new FFHopCC2420ActiveMessageP(sink) as AM;
  components ActiveMessageAddressC;
  components new FFHopCC2420ControlC(number_of_channels, channel_lifetime, speedup_receive, use_ack);
  components FFCC2420PacketC;
  components LedsC;
  components RandomC;

  components new FFHopCC2420TransmitC();
  components new FFHopCC2420ReceiveC(sink, speedup_receive);

  components new FFHopCC2420CsmaP(use_ack) as CsmaP;
  components FFDummyLplP;

  components FFPacketLinkDummyP as LinkC;
  components new StateC();

  Mgmt = AM;
  RadioStatus = AM;
  RadioBackoff = AM;
  Packet = AM;
  AMSend = AM;
  SendNotifier = AM;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;
  PacketLink = LinkC;
  LowPowerListening = FFDummyLplP;
  CC2420Packet = FFCC2420PacketC;
  PacketAcknowledgements = FFCC2420PacketC;
  LinkPacketMetadata = FFCC2420PacketC;
 
  CsmaP.SubControl -> FFHopCC2420TransmitC;
  CsmaP.CC2420Transmit -> FFHopCC2420TransmitC;
  CsmaP.SubControl -> FFHopCC2420ReceiveC;
  CsmaP.CC2420Packet -> FFCC2420PacketC;
  CsmaP.CC2420PacketBody -> FFCC2420PacketC;
  CsmaP.Random -> RandomC;
  CsmaP.SplitControlState -> StateC;
  CsmaP.Leds -> LedsC;
  CsmaP.Resource -> FFHopCC2420ControlC;
  CsmaP.CC2420Power -> FFHopCC2420ControlC;
 
  AM.SubSend -> CsmaP;
  AM.SubReceive -> FFHopCC2420ReceiveC.Receive;

  AM.ActiveMessageAddress -> ActiveMessageAddressC;
  AM.CC2420Packet -> FFCC2420PacketC;
  AM.CC2420PacketBody -> FFCC2420PacketC;
  AM.HopCC2420Config -> FFHopCC2420ControlC;
  AM.SubBackoff -> CsmaP;
  AM.Leds -> LedsC;
  AM.RadioControl -> CsmaP;

  LinkC.PacketAcknowledgements -> FFCC2420PacketC;
  FFHopCC2420ReceiveC.HopCC2420Config -> FFHopCC2420ControlC;
  FFHopCC2420TransmitC.HopCC2420Config -> FFHopCC2420ControlC;
  FFHopCC2420TransmitC.CC2420Receive -> FFHopCC2420ReceiveC;
}
