/*
 *  Dummy radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Network: Dummy Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include "cc2420Radio.h"

generic configuration cc2420RadioC(am_addr_t sink_addr, uint8_t channel, uint8_t power, uint16_t remote_wakeup, uint16_t delay_after_receive,
								uint16_t backoff, uint16_t min_backoff) {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as RadioAMSend;
  provides interface Receive as RadioReceive;
  provides interface Receive as RadioSnoop;
  provides interface AMPacket as RadioAMPacket;
  provides interface Packet as RadioPacket;
  provides interface PacketAcknowledgements as RadioPacketAcknowledgements;
  provides interface ModuleStatus as RadioStatus;
}

implementation {

  enum {
    U_CC_FF_PORT = unique("CC2420_CC_FF_PORT"),
  };

#ifndef TOSSIM
  components new FFCC2420ActiveMessageC(sink_addr, channel, power, remote_wakeup, delay_after_receive, backoff, min_backoff);
  Mgmt = FFCC2420ActiveMessageC;
  Module = FFCC2420ActiveMessageC;
  RadioStatus = FFCC2420ActiveMessageC;
  RadioAMSend = FFCC2420ActiveMessageC.AMSend[U_CC_FF_PORT];
  RadioReceive = FFCC2420ActiveMessageC.Receive[U_CC_FF_PORT];
  RadioSnoop = FFCC2420ActiveMessageC.Snoop[U_CC_FF_PORT];
  RadioPacket = FFCC2420ActiveMessageC.Packet;
  RadioAMPacket = FFCC2420ActiveMessageC.AMPacket;
  RadioPacketAcknowledgements = FFCC2420ActiveMessageC.PacketAcknowledgements;
#else
  components new cc2420RadioP(sink_addr);
  Mgmt = cc2420RadioP;
  Module = cc2420RadioP;
  RadioStatus = cc2420RadioP;

  components ActiveMessageC;
  components new SimActiveMessageP();
  cc2420RadioP.RadioControl -> ActiveMessageC;
  RadioAMSend = SimActiveMessageP.RadioAMSend;
  RadioReceive = SimActiveMessageP.RadioReceive;
  RadioSnoop = SimActiveMessageP.RadioSnoop;

  SimActiveMessageP.AMSend -> ActiveMessageC.AMSend[U_CC_FF_PORT];
  SimActiveMessageP.Receive -> ActiveMessageC.Receive[U_CC_FF_PORT];
  SimActiveMessageP.Snoop -> ActiveMessageC.Snoop[U_CC_FF_PORT];
  SimActiveMessageP.AMPacket -> ActiveMessageC.AMPacket;

  RadioPacket = ActiveMessageC.Packet;
  RadioAMPacket = ActiveMessageC.AMPacket;
  RadioPacketAcknowledgements = ActiveMessageC.PacketAcknowledgements;
#endif

}

