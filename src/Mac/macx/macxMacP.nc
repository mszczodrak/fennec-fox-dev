/*
 *  macx MAC module for Fennec Fox platform.
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
 * Module: macx MAC Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include <Fennec.h>
#include <Ieee154.h> 
#include "macxMac.h"

module macxMacP @safe() {
uses interface macxMacParams;

uses interface SplitControl as RadioControl;
uses interface RadioSend;
uses interface RadioReceive;
uses interface RadioCCA;
uses interface RadioPacket;

uses interface PacketField<uint8_t> as PacketTransmitPower;
uses interface PacketField<uint8_t> as PacketRSSI;
uses interface PacketField<uint8_t> as PacketTimeSyncOffset;
uses interface PacketField<uint8_t> as PacketLinkQuality;
uses interface LinkPacketMetadata;

}

implementation {

event void RadioControl.startDone(error_t error) {

}

event void RadioControl.stopDone(error_t error) {

}

tasklet_async event void RadioCCA.done(error_t error) {
}

tasklet_async event bool RadioReceive.header(message_t *msg) {
	return TRUE;
}

tasklet_async event message_t* RadioReceive.receive(message_t *msg) {
	return msg;
}

tasklet_async event void RadioSend.sendDone(error_t error) {

}

tasklet_async event void RadioSend.ready() {

}







}
