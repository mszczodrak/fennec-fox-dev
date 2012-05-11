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

#define LOW_POWER_LISTENING

generic configuration cc2420RadioC(am_addr_t sink_addr, uint8_t channel, uint8_t power, 
					uint16_t remote_wakeup, uint16_t delay_after_receive,
					uint16_t backoff, uint16_t min_backoff, uint8_t ack, 
					uint8_t cca, uint8_t crc) {
  provides interface Mgmt;
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

  components new cc2420RadioP(sink_addr, channel, power, remote_wakeup, 
				delay_after_receive, backoff, min_backoff, ack, cca, crc);
#ifdef TOSSIM
  components ActiveMessageC as AM;
#else
  components CC2420ActiveMessageC as AM;
#endif

  components ParametersCC2420P;

  Mgmt = cc2420RadioP;
  RadioStatus = cc2420RadioP;
  RadioAMSend = cc2420RadioP.RadioAMSend;
  RadioReceive = cc2420RadioP.RadioReceive;
  RadioSnoop = cc2420RadioP.RadioSnoop;

  cc2420RadioP.ParametersCC2420 -> ParametersCC2420P.ParametersCC2420;
  cc2420RadioP.RadioControl -> AM;

  cc2420RadioP.AMSend -> AM.AMSend[U_CC_FF_PORT];
  cc2420RadioP.Receive -> AM.Receive[U_CC_FF_PORT];
  cc2420RadioP.Snoop -> AM.Snoop[U_CC_FF_PORT];
  cc2420RadioP.AMPacket -> AM.AMPacket;

  RadioPacket = AM.Packet;
  RadioAMPacket = AM.AMPacket;
  RadioPacketAcknowledgements = AM.PacketAcknowledgements;

}

