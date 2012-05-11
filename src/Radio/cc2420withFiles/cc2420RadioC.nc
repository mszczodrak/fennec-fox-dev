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

generic configuration cc2420RadioC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as RadioAMSend;
  provides interface Receive as RadioReceive;
  provides interface Receive as RadioSnoop;
  provides interface Packet as RadioPacket;
  provides interface AMPacket as RadioAMPacket;
  provides interface PacketAcknowledgements as RadioPacketAcknowledgements;
}

implementation {
  enum {
    CC_PORT = 33,
  };

  components new cc2420RadioP();
  Mgmt = cc2420RadioP;
  Module = cc2420RadioP;
  //RadioAMSend = cc2420RadioP;

#ifndef TOSSIM
  components CC2420ActiveMessageC;
  cc2420RadioP.RadioControl -> CC2420ActiveMessageC;
  cc2420RadioP.LowPowerListening -> CC2420ActiveMessageC;

  RadioAMSend = CC2420ActiveMessageC.AMSend[CC_PORT];
  RadioReceive = CC2420ActiveMessageC.Receive[CC_PORT];
  RadioSnoop = CC2420ActiveMessageC.Snoop[CC_PORT];
  RadioPacket = CC2420ActiveMessageC.Packet;
  RadioAMPacket = CC2420ActiveMessageC.AMPacket;
  RadioPacketAcknowledgements = CC2420ActiveMessageC.PacketAcknowledgements;

#else
  components ActiveMessageC;
  cc2420RadioP.RadioControl -> ActiveMessageC;
//  cc2420RadioP.LowPowerListening -> CC2420ActiveMessageC;
  RadioAMSend = ActiveMessageC.AMSend[CC_PORT];
  RadioReceive = ActiveMessageC.Receive[CC_PORT];
  RadioSnoop = ActiveMessageC.Snoop[CC_PORT];
#endif

}

