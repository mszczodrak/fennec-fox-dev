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

generic configuration pushDataAppC(uint32_t init_delay_ms, uint16_t delay_ms, uint16_t src, uint16_t dest, uint16_t max_sequence) {
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

  components new pushDataAppP(init_delay_ms, delay_ms, src, dest, max_sequence);
  Mgmt = pushDataAppP;
  Module = pushDataAppP;
  NetworkAMSend = pushDataAppP.NetworkAMSend;
  NetworkReceive = pushDataAppP.NetworkReceive;
  NetworkSnoop = pushDataAppP.NetworkSnoop;
  NetworkAMPacket = pushDataAppP.NetworkAMPacket;
  NetworkPacket = pushDataAppP.NetworkPacket;
  NetworkPacketAcknowledgements = pushDataAppP.NetworkPacketAcknowledgements;
  NetworkStatus = pushDataAppP.NetworkStatus;


  components LedsC;
  components new TimerMilliC();
  components new TimerMilliC() as ExperimentTimerC;

  pushDataAppP.Leds -> LedsC;
  pushDataAppP.Timer -> TimerMilliC;
  pushDataAppP.ExperimentTimer -> ExperimentTimerC;
}
