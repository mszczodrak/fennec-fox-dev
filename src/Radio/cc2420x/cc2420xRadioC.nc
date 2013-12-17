/*
 *  cc2420x radio module for Fennec Fox platform.
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
 * Network: cc2420x Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include "CC2420.h"

configuration cc2420xRadioC {
provides interface SplitControl;

uses interface cc2420xRadioParams;

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

components cc2420xRadioP;
SplitControl = cc2420xRadioP;
cc2420xRadioParams = cc2420xRadioP;

components CC2420XDriverLayerC;
cc2420xRadioP.RadioState -> CC2420XDriverLayerC;

RadioSend = CC2420XDriverLayerC;
RadioReceive = CC2420XDriverLayerC;
RadioCCA = CC2420XDriverLayerC;
RadioPacket = CC2420XDriverLayerC;

PacketTransmitPower = CC2420XDriverLayerC.PacketTransmitPower;
PacketRSSI = CC2420XDriverLayerC.PacketRSSI;
PacketTimeSyncOffset = CC2420XDriverLayerC.PacketTimeSyncOffset;
PacketLinkQuality = CC2420XDriverLayerC.PacketLinkQuality;
LinkPacketMetadata = CC2420XDriverLayerC;


//RadioDriverLayerC.Config -> RadioP;
//RadioDriverLayerC.PacketTimeStamp -> TimeStampingLayerC;
//PacketTransmitPower = RadioDriverLayerC.PacketTransmitPower;
//PacketLinkQuality = RadioDriverLayerC.PacketLinkQuality;
//PacketRSSI = RadioDriverLayerC.PacketRSSI;
//LinkPacketMetadata = RadioDriverLayerC;
//LocalTimeRadio = RadioDriverLayerC;

//RadioDriverLayerC.TransmitPowerFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
//RadioDriverLayerC.RSSIFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
//RadioDriverLayerC.TimeSyncFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
//RadioDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];



}
