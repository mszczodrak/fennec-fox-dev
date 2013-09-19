/*
 *  null application module for Fennec Fox platform.
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
 * Application: null Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration nullAppC {
provides interface Mgmt;

uses interface nullAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components nullAppP;
Mgmt = nullAppP;

nullAppParams = nullAppP;

NetworkAMSend = nullAppP.NetworkAMSend;
NetworkReceive = nullAppP.NetworkReceive;
NetworkSnoop = nullAppP.NetworkSnoop;
NetworkAMPacket = nullAppP.NetworkAMPacket;
NetworkPacket = nullAppP.NetworkPacket;
NetworkPacketAcknowledgements = nullAppP.NetworkPacketAcknowledgements;
}
