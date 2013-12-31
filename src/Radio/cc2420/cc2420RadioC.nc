/*
 *  cc2420 radio module for Fennec Fox platform.
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
 * Network: cc2420 Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 12/26/2013
 */

configuration cc2420RadioC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface cc2420RadioParams;
provides interface Resource as RadioResource;
provides interface RadioConfig;
provides interface RadioPower;
provides interface Read<uint16_t> as ReadRssi;
provides interface RadioSend;
provides interface RadioPacket;
provides interface RadioBuffer;
provides interface ReceiveIndicator as PacketIndicator;
provides interface ReceiveIndicator as EnergyIndicator;
provides interface ReceiveIndicator as ByteIndicator;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;


}

implementation {

components cc2420RadioP;
components cc2420ControlC;
components cc2420DriverC;
EnergyIndicator = cc2420DriverC.EnergyIndicator;
cc2420RadioParams = cc2420DriverC.cc2420RadioParams;
ByteIndicator = cc2420DriverC.ByteIndicator;
RadioCCA = cc2420DriverC.RadioCCA;

cc2420RadioP.RadioPower -> cc2420ControlC.RadioPower;
cc2420RadioP.RadioResource -> cc2420ControlC.RadioResource;

SplitControl = cc2420RadioP;
cc2420RadioParams = cc2420RadioP;

RadioResource = cc2420ControlC.RadioResource;
RadioConfig = cc2420ControlC.RadioConfig;
RadioPower = cc2420ControlC.RadioPower;
ReadRssi = cc2420ControlC.ReadRssi;

cc2420RadioParams = cc2420ControlC;

cc2420RadioP.RadioConfig -> cc2420ControlC.RadioConfig;

components cc2420ReceiveC;
cc2420ReceiveC.RadioConfig -> cc2420ControlC.RadioConfig;
PacketIndicator = cc2420ReceiveC.PacketIndicator;
cc2420RadioP.ReceiveControl -> cc2420ReceiveC.StdControl;

RadioReceive = cc2420ReceiveC.RadioReceive;
RadioBuffer = cc2420DriverC.RadioBuffer;
RadioSend = cc2420DriverC.RadioSend;
RadioPacket = cc2420DriverC.RadioPacket;
cc2420RadioP.TransmitControl -> cc2420DriverC.StdControl;

cc2420ReceiveC.RadioPacket -> cc2420DriverC.RadioPacket;

components LedsC;
cc2420RadioP.Leds -> LedsC;


RadioState = cc2420RadioP.RadioState;
RadioLinkPacketMetadata = cc2420DriverC.RadioLinkPacketMetadata;
  
PacketTransmitPower = cc2420DriverC.PacketTransmitPower;
PacketRSSI = cc2420DriverC.PacketRSSI;
PacketTimeSyncOffset = cc2420DriverC.PacketTimeSyncOffset;
PacketLinkQuality = cc2420DriverC.PacketLinkQuality;

cc2420ReceiveC.PacketTimeSyncOffset -> cc2420DriverC.PacketTimeSyncOffset;

}
