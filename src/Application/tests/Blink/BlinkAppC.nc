/*
 *  Blinking application for Fennec Fox platform.
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
 * Application: LED blinking
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 6/2/2011
 */

#include "BlinkApp.h"

configuration BlinkAppC {
provides interface SplitControl;

uses interface BlinkAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components BlinkAppP;
SplitControl = BlinkAppP;

BlinkAppParams = BlinkAppP;

NetworkAMSend = BlinkAppP.NetworkAMSend;
NetworkReceive = BlinkAppP.NetworkReceive;
NetworkSnoop = BlinkAppP.NetworkSnoop;
NetworkAMPacket = BlinkAppP.NetworkAMPacket;
NetworkPacket = BlinkAppP.NetworkPacket;
NetworkPacketAcknowledgements = BlinkAppP.NetworkPacketAcknowledgements;

components LedsC;
BlinkAppP.Leds -> LedsC;

components new TimerMilliC() as Timer;
BlinkAppP.Timer -> Timer;
}
