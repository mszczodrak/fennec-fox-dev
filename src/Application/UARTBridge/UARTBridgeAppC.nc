/*
 *  UARTBridge application module for Fennec Fox platform.
 *
 *  Copyright (C) 2013 Marcin Szczodrak
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
 * Application: UARTBridge Application Module
 * Author: Marcin Szczodrak
 * Date: 10/01/2013
 * Last Modified: 10/09/2013
 */

configuration UARTBridgeAppC {
provides interface Mgmt;

uses interface UARTBridgeAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components UARTBridgeAppP;
Mgmt = UARTBridgeAppP;

UARTBridgeAppParams = UARTBridgeAppP;

NetworkAMSend = UARTBridgeAppP.NetworkAMSend;
NetworkReceive = UARTBridgeAppP.NetworkReceive;
NetworkSnoop = UARTBridgeAppP.NetworkSnoop;
NetworkAMPacket = UARTBridgeAppP.NetworkAMPacket;
NetworkPacket = UARTBridgeAppP.NetworkPacket;
NetworkPacketAcknowledgements = UARTBridgeAppP.NetworkPacketAcknowledgements;
}
