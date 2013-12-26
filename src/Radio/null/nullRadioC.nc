/*
 *  null radio module for Fennec Fox platform.
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
 * Network: null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration nullRadioC {
provides interface SplitControl;

uses interface nullRadioParams;

provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LinkPacketMetadata;

}

implementation {

components nullRadioP;
SplitControl = nullRadioP;
nullRadioParams = nullRadioP;

RadioSend = nullRadioP;
RadioReceive = nullRadioP;
RadioCCA = nullRadioP;
RadioPacket = nullRadioP;

PacketTransmitPower = nullRadioP.PacketTransmitPower;
PacketRSSI = nullRadioP.PacketRSSI;
PacketTimeSyncOffset = nullRadioP.PacketTimeSyncOffset;
PacketLinkQuality = nullRadioP.PacketLinkQuality;
LinkPacketMetadata = nullRadioP;

}
