/*
 *  Ctp network module for Fennec Fox platform.
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
 * Network: Ctp Network Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>

configuration ctpNetC {
  provides interface Mgmt;
  provides interface Module;

  uses interface ctpNetParams;

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

  enum {
    AM_TESTNETWORKMSG = 0x05,
    SAMPLE_RATE_KEY = 0x1,
    CL_TEST = 0xee,
    TEST_NETWORK_QUEUE_SIZE = 8,
  };

  components ctpNetP;
  Mgmt = ctpNetP;
  Module = ctpNetP;
  ctpNetParams = ctpNetP;
  NetworkStatus = ctpNetP;
  NetworkAMSend = ctpNetP;
  NetworkAMPacket = ctpNetP;
  NetworkPacket = ctpNetP;
  NetworkPacketAcknowledgements = ctpNetP;

  components CtpP;
  components CtpActiveMessageC;
  components CollectionC as Collector;
  components new CollectionSenderC(CL_TEST);

  NetworkReceive = Collector.Receive[CL_TEST];
  NetworkSnoop = Collector.Snoop[CL_TEST];

  MacAMSend = CtpActiveMessageC;
  MacReceive = CtpActiveMessageC.MacReceive;
  MacSnoop = CtpActiveMessageC.MacSnoop;
  MacAMPacket = CtpActiveMessageC.MacAMPacket;
  MacPacket = CtpActiveMessageC.MacPacket;
  MacPacketAcknowledgements = CtpActiveMessageC.MacPacketAcknowledgements;
  MacStatus = CtpActiveMessageC.MacStatus;

  ctpNetP.RoutingControl -> CtpP;
  ctpNetP.RootControl -> CtpP;
  ctpNetP.CtpSend -> CollectionSenderC.Send;
  ctpNetP.CtpPacket -> CtpP.Packet;
  ctpNetP.CtpPacketAcknowledgements -> CtpActiveMessageC.PacketAcknowledgements;

  ctpNetP.CtpAMPacket -> CtpP.AMPacket;
}
