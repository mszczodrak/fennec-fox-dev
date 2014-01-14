/*
 *  cape radio module for Fennec Fox platform.
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
 * Network: cape Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration capeRadioC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface capeRadioParams;

provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;

}

implementation {

components capeRadioP;
SplitControl = capeRadioP;
RadioState = capeRadioP;
capeRadioParams = capeRadioP;
RadioReceive = capeRadioP.RadioReceive;

PacketTransmitPower = capeRadioP.PacketTransmitPower;
PacketRSSI = capeRadioP.PacketRSSI;
PacketTimeSync = capeRadioP.PacketTimeSync;
PacketLinkQuality = capeRadioP.PacketLinkQuality;
RadioLinkPacketMetadata = capeRadioP.RadioLinkPacketMetadata;

RadioResource = capeRadioP.RadioResource;

RadioBuffer = capeRadioP.RadioBuffer;
RadioPacket = capeRadioP.RadioPacket;
RadioSend = capeRadioP.RadioSend;

components CapePacketModelC as CapePacketModelC;
components CpmModelC;

capeRadioP.AMControl -> CapePacketModelC;
capeRadioP.Model -> CapePacketModelC.Packet;

CapePacketModelC.GainRadioModel -> CpmModelC;
RadioCCA = CapePacketModelC.RadioCCA;
}
