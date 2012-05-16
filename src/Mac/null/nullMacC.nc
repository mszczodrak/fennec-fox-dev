/*
 *  Null mac module for Fennec Fox platform.
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
 * Network: Null Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration nullMacC {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface nullMacCParams;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
  uses interface Receive as RadioSnoop;
  uses interface AMPacket as RadioAMPacket;
  uses interface Packet as RadioPacket;
  uses interface PacketAcknowledgements as RadioPacketAcknowledgements;
  uses interface ModuleStatus as RadioStatus;
}

implementation {
  components nullMacP;
  Mgmt = nullMacP;
  Module = nullMacP;
  nullMacCParams = nullMacP;
  MacAMSend = nullMacP.MacAMSend;
  MacReceive = nullMacP.MacReceive;
  MacSnoop = nullMacP.MacSnoop;
  MacAMPacket = nullMacP.MacAMPacket;
  MacPacket = nullMacP.MacPacket;
  MacPacketAcknowledgements = nullMacP.MacPacketAcknowledgements;
  MacStatus = nullMacP.MacStatus;
  RadioAMSend = nullMacP;
  RadioReceive = nullMacP.RadioReceive;
  RadioSnoop = nullMacP.RadioSnoop;
  RadioAMPacket = nullMacP.RadioAMPacket;
  RadioPacket = nullMacP.RadioPacket;
  RadioPacketAcknowledgements = nullMacP.RadioPacketAcknowledgements;
  RadioStatus = nullMacP.RadioStatus;
}

