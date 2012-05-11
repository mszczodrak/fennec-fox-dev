/*
 *  Test Remote Debug application for Fennec Fox platform.
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
 * Application: Test Remote Debug
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2012
 */

generic configuration TestRemoteDebugAppC(uint16_t delay) {
  provides interface Mgmt;
  provides interface Module;

  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {

  components new TestRemoteDebugAppP(delay);
  Mgmt = TestRemoteDebugAppP;
  Module = TestRemoteDebugAppP;

  NetworkAMSend = TestRemoteDebugAppP.NetworkAMSend;
  NetworkReceive = TestRemoteDebugAppP.NetworkReceive;
  NetworkSnoop = TestRemoteDebugAppP.NetworkSnoop;
  NetworkAMPacket = TestRemoteDebugAppP.NetworkAMPacket;
  NetworkPacket = TestRemoteDebugAppP.NetworkPacket;
  NetworkPacketAcknowledgements = TestRemoteDebugAppP.NetworkPacketAcknowledgements;
  NetworkStatus = TestRemoteDebugAppP.NetworkStatus;

  components LedsC;
  TestRemoteDebugAppP.Leds -> LedsC;

  components new TimerMilliC() as Timer0;
  TestRemoteDebugAppP.Timer0 -> Timer0;
}
