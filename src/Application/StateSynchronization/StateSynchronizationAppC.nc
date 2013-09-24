/*
 *  State Synchronization application module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2013 Marcin Szczodrak
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
 * Application: State Synchronization module
 * Author: Marcin Szczodrak
 * Date: 9/21/2013
 */


#include <Fennec.h>

configuration StateSynchronizationAppC {
provides interface Mgmt;

uses interface StateSynchronizationAppParams;
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {

components StateSynchronizationAppP;
Mgmt = StateSynchronizationAppP;
StateSynchronizationAppParams = StateSynchronizationAppP;

NetworkAMSend = StateSynchronizationAppP;
NetworkReceive = StateSynchronizationAppP.NetworkReceive;
NetworkSnoop = StateSynchronizationAppP.NetworkSnoop;
NetworkAMPacket = StateSynchronizationAppP.NetworkAMPacket;
NetworkPacket = StateSynchronizationAppP.NetworkPacket;
NetworkPacketAcknowledgements = StateSynchronizationAppP.NetworkPacketAcknowledgements;

//  components ProtocolStackC;
//  StateSynchronizationAppP.ProtocolStack -> ProtocolStackC;

components CachesC;
StateSynchronizationAppP.Fennec -> CachesC;

components RandomC;
StateSynchronizationAppP.Random -> RandomC;

components LedsC;
StateSynchronizationAppP.Leds -> LedsC;

components new TimerMilliC() as Timer;
StateSynchronizationAppP.Timer -> Timer;

}

