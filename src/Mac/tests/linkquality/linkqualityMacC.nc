/*
 *  linkquality mac module for Fennec Fox platform.
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
 * Network: linkquality Mac Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration linkqualityMacC {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface linkqualityMacParams;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
  uses interface Receive as RadioSnoop;
  uses interface AMPacket as RadioAMPacket;
  uses interface Packet as RadioPacket;
  uses interface PacketAcknowledgements as RadioPacketAcknowledgements;
  uses interface ModuleStatus as RadioStatus;
}

implementation {
  components linkqualityMacP;
  Mgmt = linkqualityMacP;
  Module = linkqualityMacP;
  linkqualityMacParams = linkqualityMacP;
  MacAMSend = linkqualityMacP.MacAMSend;
  MacReceive = linkqualityMacP.MacReceive;
  MacSnoop = linkqualityMacP.MacSnoop;
  MacAMPacket = linkqualityMacP.MacAMPacket;
  MacPacket = linkqualityMacP.MacPacket;
  MacPacketAcknowledgements = linkqualityMacP.MacPacketAcknowledgements;
  MacStatus = linkqualityMacP.MacStatus;
  RadioAMSend = linkqualityMacP.RadioAMSend;
  RadioReceive = linkqualityMacP.RadioReceive;
  RadioSnoop = linkqualityMacP.RadioSnoop;
  RadioAMPacket = linkqualityMacP.RadioAMPacket;
  RadioPacket = linkqualityMacP.RadioPacket;
  RadioPacketAcknowledgements = linkqualityMacP.RadioPacketAcknowledgements;
  RadioStatus = linkqualityMacP.RadioStatus;

  components new TimerMilliC() as Timer;
  linkqualityMacP.Timer -> Timer;

  components SerialActiveMessageC as SerialAM;
  linkqualityMacP.SerialCtrl -> SerialAM;
//  linkqualityMacP.SerialReceive -> SerialAM.Receive[111];
  linkqualityMacP.SerialAMSend -> SerialAM.AMSend[111];
  linkqualityMacP.SerialPacket -> SerialAM;

}

