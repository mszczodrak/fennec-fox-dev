/*
 *  fixedPath network module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2011 Marcin Szczodrak
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
 * Network: Sends message over multi-hop fixed path
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/5/2011
 */

#include <Fennec.h>

generic configuration fixedPathNetC(uint16_t addr1, uint16_t addr2,
				    uint16_t addr3, uint16_t addr4,
				    uint16_t addr5, uint16_t addr6,
				    uint16_t addr7, uint16_t addr8,
				    uint16_t addr9, uint16_t addr10) {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as NetworkAMSend;
  provides interface Receive as NetworkReceive;
  provides interface Receive as NetworkSnoop;
  provides interface AMPacket as NetworkAMPacket;
  provides interface Packet as NetworkPacket;
  provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  provides interface ModuleStatus as NetworkStatus;

  uses interface AMSend as MacAMSend;
  uses interface Receive as MacReceive;
  uses interface Receive as MacSnoop;
  uses interface AMPacket as MacAMPacket;
  uses interface Packet as MacPacket;
  uses interface PacketAcknowledgements as MacPacketAcknowledgements;
  uses interface ModuleStatus as MacStatus;
}

implementation {

  components new fixedPathNetP(addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9, addr10);
  Mgmt = fixedPathNetP;
  Module = fixedPathNetP;
  NetworkAMSend = fixedPathNetP.NetworkAMSend;
  NetworkReceive = fixedPathNetP.NetworkReceive;
  NetworkSnoop = fixedPathNetP.NetworkSnoop;
  NetworkAMPacket = fixedPathNetP.NetworkAMPacket;
  NetworkPacket = fixedPathNetP.NetworkPacket;
  NetworkPacketAcknowledgements = fixedPathNetP.NetworkPacketAcknowledgements;
  NetworkStatus = fixedPathNetP.NetworkStatus;

  MacAMSend = fixedPathNetP;
  MacReceive = fixedPathNetP.MacReceive;
  MacSnoop = fixedPathNetP.MacSnoop;
  MacAMPacket = fixedPathNetP.MacAMPacket;
  MacPacket = fixedPathNetP.MacPacket;
  MacPacketAcknowledgements = fixedPathNetP.MacPacketAcknowledgements;
  MacStatus = fixedPathNetP.MacStatus;
}
