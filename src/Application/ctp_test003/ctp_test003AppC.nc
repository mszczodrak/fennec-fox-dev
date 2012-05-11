/*
 *  Dummy application module for Fennec Fox platform.
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
 * Network: Dummy Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

generic configuration ctp_test003AppC(uint16_t delay, uint16_t src, uint16_t dest) {
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

  components new ctp_test003AppP(delay, src, dest);
  Mgmt = ctp_test003AppP;
  Module = ctp_test003AppP;
  NetworkAMSend = ctp_test003AppP;
  NetworkReceive = ctp_test003AppP.NetworkReceive;
  NetworkSnoop = ctp_test003AppP.NetworkSnoop;
  NetworkAMPacket = ctp_test003AppP.NetworkAMPacket;
  NetworkPacket = ctp_test003AppP.NetworkPacket;
  NetworkPacketAcknowledgements = ctp_test003AppP.NetworkPacketAcknowledgements;
  NetworkStatus = ctp_test003AppP.NetworkStatus;

  components LedsC;
  components new TimerMilliC();

  ctp_test003AppP.Leds -> LedsC;
  ctp_test003AppP.Timer -> TimerMilliC;

}
