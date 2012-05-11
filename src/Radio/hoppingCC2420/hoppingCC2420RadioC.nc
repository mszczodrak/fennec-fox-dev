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

#include "hoppingCC2420Radio.h"

generic configuration hoppingCC2420RadioC(	uint16_t sink,
						uint8_t number_of_channels,
                                                uint16_t channel_lifetime,
                                                bool speedup_receive,
						bool use_ack) {

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

  components new FFHopCC2420ActiveMessageC(sink, number_of_channels, channel_lifetime, speedup_receive, use_ack);
  Mgmt = FFHopCC2420ActiveMessageC;
  RadioStatus = FFHopCC2420ActiveMessageC;
  RadioAMSend = FFHopCC2420ActiveMessageC.AMSend[HOP_CC_FF_PORT];
  RadioReceive = FFHopCC2420ActiveMessageC.Receive[HOP_CC_FF_PORT];
  RadioSnoop = FFHopCC2420ActiveMessageC.Snoop[HOP_CC_FF_PORT];
  RadioPacket = FFHopCC2420ActiveMessageC.Packet;
  RadioAMPacket = FFHopCC2420ActiveMessageC.AMPacket;
  RadioPacketAcknowledgements = FFHopCC2420ActiveMessageC.PacketAcknowledgements;
}

