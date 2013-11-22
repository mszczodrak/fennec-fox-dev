/*
 *  tricklePlus network module for Fennec Fox platform.
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
 * Network: tricklePlus Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>

configuration tricklePlusNetC {
provides interface Mgmt;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface tricklePlusNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}

implementation {

components tricklePlusNetP;
Mgmt = tricklePlusNetP;
tricklePlusNetParams = tricklePlusNetP;
NetworkAMSend = tricklePlusNetP.NetworkAMSend;
NetworkReceive = tricklePlusNetP.NetworkReceive;
NetworkSnoop = tricklePlusNetP.NetworkSnoop;
NetworkAMPacket = tricklePlusNetP.NetworkAMPacket;
NetworkPacket = tricklePlusNetP.NetworkPacket;
NetworkPacketAcknowledgements = tricklePlusNetP.NetworkPacketAcknowledgements;

MacAMSend = tricklePlusNetP;
MacReceive = tricklePlusNetP.MacReceive;
MacSnoop = tricklePlusNetP.MacSnoop;
MacAMPacket = tricklePlusNetP.MacAMPacket;
MacPacket = tricklePlusNetP.MacPacket;
MacPacketAcknowledgements = tricklePlusNetP.MacPacketAcknowledgements;

components new TrickleTimerMilliC(1, 1024, 1, 1);
tricklePlusNetP.TrickleTimer[TRICKLE_ID] -> TrickleTimerMilliC.TrickleTimer[TRICKLE_ID];

tricklePlusNetParams = TrickleTimerMilliC;

}
