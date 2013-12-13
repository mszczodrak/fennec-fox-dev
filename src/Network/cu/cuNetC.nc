/*
 *  cu network module for Fennec Fox platform.
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
 * Network: cu Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>

configuration cuNetC {
provides interface SplitControl;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface cuNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}

implementation {

components cuNetP;
SplitControl = cuNetP;
cuNetParams = cuNetP;
NetworkAMSend = cuNetP.NetworkAMSend;
NetworkReceive = cuNetP.NetworkReceive;
NetworkSnoop = cuNetP.NetworkSnoop;
NetworkAMPacket = cuNetP.NetworkAMPacket;
NetworkPacket = cuNetP.NetworkPacket;
NetworkPacketAcknowledgements = cuNetP.NetworkPacketAcknowledgements;

MacAMSend = cuNetP;
MacReceive = cuNetP.MacReceive;
MacSnoop = cuNetP.MacSnoop;
MacAMPacket = cuNetP.MacAMPacket;
MacPacket = cuNetP.MacPacket;
MacPacketAcknowledgements = cuNetP.MacPacketAcknowledgements;
}
