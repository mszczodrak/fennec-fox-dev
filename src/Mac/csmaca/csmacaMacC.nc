/*
 *  csma/ca MAC module for Fennec Fox platform.
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
 * Module: CSMA/CA MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 2/18/2012
 * Last Modified: 8/29/2012
 */

#include "csmacaMac.h"

//#define LOW_POWER_LISTENING

configuration csmacaMacC {
  provides interface Mgmt;
  provides interface AMSend as MacAMSend;
  provides interface Receive as MacReceive;
  provides interface Receive as MacSnoop;
  provides interface AMPacket as MacAMPacket;
  provides interface Packet as MacPacket;
  provides interface PacketAcknowledgements as MacPacketAcknowledgements;
  provides interface ModuleStatus as MacStatus;

  uses interface csmacaMacParams;

  uses interface AMSend as RadioAMSend;
  uses interface Receive as RadioReceive;
  uses interface Receive as RadioSnoop;
  uses interface AMPacket as RadioAMPacket;
  uses interface Packet as RadioPacket;
  uses interface PacketAcknowledgements as RadioPacketAcknowledgements;
  uses interface ModuleStatus as RadioStatus;

  uses interface RadioConfig;

}

implementation {

  enum {
    U_CC_FF_PORT = unique("CC2420_CC_FF_PORT"),
  };

  components csmacaMacP;
#ifdef TOSSIM
  components ActiveMessageC as AM;
#else
  components CC2420ActiveMessageC as AM;
#endif


  Mgmt = csmacaMacP;
  MacStatus = csmacaMacP;
  MacAMSend = csmacaMacP.MacAMSend;
  MacReceive = csmacaMacP.MacReceive;
  MacSnoop = csmacaMacP.MacSnoop;
  csmacaMacParams = csmacaMacP;

  RadioConfig = csmacaMacP.RadioConfig;

  components ParametersCC2420P;
  csmacaMacP.ParametersCC2420 -> ParametersCC2420P.ParametersCC2420;
  csmacaMacP.RadioControl -> AM;

  csmacaMacP.AMSend -> AM.AMSend[U_CC_FF_PORT];
  csmacaMacP.Receive -> AM.Receive[U_CC_FF_PORT];
  csmacaMacP.Snoop -> AM.Snoop[U_CC_FF_PORT];
  csmacaMacP.AMPacket -> AM.AMPacket;

  MacPacket = AM.Packet;
  MacAMPacket = AM.AMPacket;
  MacPacketAcknowledgements = AM.PacketAcknowledgements;

  RadioAMSend = csmacaMacP.RadioAMSend;
  RadioReceive = csmacaMacP.RadioReceive;
  RadioSnoop = csmacaMacP.RadioSnoop;
  RadioAMPacket = csmacaMacP.RadioAMPacket;
  RadioPacket = csmacaMacP.RadioPacket;
  RadioPacketAcknowledgements = csmacaMacP.RadioPacketAcknowledgements;
  RadioStatus = csmacaMacP.RadioStatus;



}

