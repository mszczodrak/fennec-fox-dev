/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The Active Message layer for the CC2420 radio. This configuration
 * just layers the AM dispatch (FFCC2420ActiveMessageM) on top of the
 * underlying CC2420 radio packet (CC2420CsmaCsmaCC), which is
 * inherently an AM packet (acknowledgements based on AM destination
 * addr and group). Note that snooping may not work, due to CC2420
 * early packet rejection if acknowledgements are enabled.
 *
 * @author Philip Levis
 * @author David Moss
 * @version $Revision: 1.16 $ $Date: 2010-06-29 22:07:44 $
 */

#include "CC2420.h"
#include "AM.h"
#include "Ieee154.h"
#include "Lpl.h"
#include "DefaultLpl.h"


#ifdef IEEE154FRAMES_ENABLED
#error "CC2420 AM layer cannot work when IEEE 802.15.4 frames only are used"
#endif

generic configuration FFCC2420ActiveMessageC(am_addr_t sink_addr, uint8_t channel, uint8_t power, uint16_t remote_wakeup, uint16_t delay_after_receive, uint16_t backoff, uint16_t min_backoff) {
  provides interface Mgmt;
  provides interface Module;
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
    interface PacketLink;
    interface State as SendState;
    interface SendNotifier[am_id_t amId];
  }
}
implementation {
  enum {
    CC2420_AM_SEND_ID     = unique(RADIO_SEND_RESOURCE),
  };

  components FFCC2420ActiveMessageP as AM;
  components ActiveMessageAddressC;
  components new FFCC2420ControlC(channel, power);
  components FFCC2420PacketC;
  components new FFPowerCycleP(sink_addr, remote_wakeup, delay_after_receive);
  components LedsC;
  components RandomC;

  components new FFCC2420TransmitC(channel, power);
  components FFCC2420ReceiveC;

  components FFUniqueSendC;
  components FFUniqueReceiveC;
  components FFCC2420TinyosNetworkC;
  components new FFCC2420CsmaP(backoff, min_backoff) as CsmaP;
  components FFCC2420ReceiveP;
  components new FFDefaultLplP(remote_wakeup, delay_after_receive, backoff, min_backoff) as LplP;
  components new TimerMilliC() as OffTimerC;
  components new TimerMilliC() as SendDoneTimerC;
  components new StateC() as SendStateC;
  components FFPacketLinkDummyP as LinkC;
  components new StateC();

  components new StateC() as RadioPowerStateC;
  components new StateC() as SplitControlStateC;
  components new TimerMilliC() as OnTimerC;
  components new TimerMilliC() as CheckTimerC;


  SendState = SendStateC;
  Mgmt = AM;
  Module = AM;
  RadioStatus = AM;
  RadioBackoff = AM;
  Packet = AM;
  AMSend = AM;
  SendNotifier = AM;
  Receive = AM.Receive;
  Snoop = AM.Snoop;
  AMPacket = AM;
  PacketLink = LinkC;
  CC2420Packet = FFCC2420PacketC;
  PacketAcknowledgements = FFCC2420PacketC;
  LinkPacketMetadata = FFCC2420PacketC;

  CsmaP.SubControl -> FFCC2420TransmitC;
  CsmaP.CC2420Transmit -> FFCC2420TransmitC;
  CsmaP.SubBackoff -> FFCC2420TransmitC;
  CsmaP.SubControl -> FFCC2420ReceiveC;
  CsmaP.CC2420Packet -> FFCC2420PacketC;
  CsmaP.CC2420PacketBody -> FFCC2420PacketC;
  CsmaP.Random -> RandomC;
  CsmaP.SplitControlState -> StateC;
  CsmaP.Leds -> LedsC;
  CsmaP.Resource -> FFCC2420ControlC;
  CsmaP.CC2420Power -> FFCC2420ControlC;

  LplP.PacketAcknowledgements -> FFCC2420PacketC;
  LplP.SubSend -> CsmaP;
  LplP.RadioBackoff -> CsmaP;
  LplP.SubControl -> CsmaP;  
  LplP.SubReceive -> FFUniqueReceiveC.Receive;
  LplP.Leds -> LedsC;
  LplP.Random -> RandomC;
  LplP.Resend -> FFCC2420TransmitC;
  LplP.SplitControlState -> SplitControlStateC;
  LplP.RadioPowerState -> RadioPowerStateC;
  LplP.PowerCycle -> FFPowerCycleP;
  LplP.CC2420PacketBody -> FFCC2420PacketC;
  LplP.SendState -> SendStateC;
  LplP.OffTimer -> OffTimerC;
  LplP.SendDoneTimer -> SendDoneTimerC;

  FFPowerCycleP.SendState -> SendStateC;
  FFPowerCycleP.RadioPowerState -> RadioPowerStateC;
  FFPowerCycleP.SplitControlState -> SplitControlStateC;
  FFPowerCycleP.OnTimer -> OnTimerC;

  FFPowerCycleP.EnergyIndicator -> FFCC2420TransmitC.EnergyIndicator;
  FFPowerCycleP.ByteIndicator -> FFCC2420TransmitC.ByteIndicator;
  FFPowerCycleP.PacketIndicator -> FFCC2420ReceiveC.PacketIndicator;
  FFPowerCycleP.SubControl -> CsmaP;
  FFPowerCycleP.Leds -> LedsC;

  FFCC2420TinyosNetworkC.SubReceive -> LplP;
  FFCC2420TinyosNetworkC.SubSend -> FFUniqueSendC;

  FFUniqueSendC.SubSend -> LplP.Send;
  FFUniqueReceiveC.SubReceive ->  FFCC2420ReceiveC.Receive;

  AM.RadioResource -> FFCC2420TinyosNetworkC.Resource[CC2420_AM_SEND_ID];
  AM.SubSend -> FFCC2420TinyosNetworkC.ActiveSend;
  AM.SubReceive -> FFCC2420TinyosNetworkC.ActiveReceive;
  AM.ActiveMessageAddress -> ActiveMessageAddressC;
  AM.CC2420Packet -> FFCC2420PacketC;
  AM.CC2420PacketBody -> FFCC2420PacketC;
  AM.CC2420Config -> FFCC2420ControlC;
  AM.SubBackoff -> CsmaP;
  AM.Leds -> LedsC;
  AM.RadioControl -> FFPowerCycleP;

  LinkC.PacketAcknowledgements -> FFCC2420PacketC;
  FFCC2420ReceiveP.CC2420Config -> FFCC2420ControlC;
}
