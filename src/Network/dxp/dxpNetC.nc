/*
 *  dxp network module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
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
 * Network: dxp Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>

configuration dxpNetC {
provides interface Mgmt;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface dxpNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}

implementation {

components dxpNetP;
Mgmt = dxpNetP;
dxpNetParams = dxpNetP;
NetworkAMSend = dxpNetP.NetworkAMSend;
NetworkReceive = dxpNetP.NetworkReceive;
NetworkSnoop = dxpNetP.NetworkSnoop;
NetworkAMPacket = dxpNetP.NetworkAMPacket;
NetworkPacket = dxpNetP.NetworkPacket;
NetworkPacketAcknowledgements = dxpNetP.NetworkPacketAcknowledgements;

MacAMSend = dxpNetP;
MacReceive = dxpNetP.MacReceive;
MacSnoop = dxpNetP.MacSnoop;
MacAMPacket = dxpNetP.MacAMPacket;
MacPacket = dxpNetP.MacPacket;
MacPacketAcknowledgements = dxpNetP.MacPacketAcknowledgements;
}
