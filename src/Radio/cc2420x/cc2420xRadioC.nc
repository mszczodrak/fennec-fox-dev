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

configuration cc2420xRadioC {
provides interface SplitControl;
provides interface Receive as RadioReceive;

uses interface cc2420xRadioParams;

provides interface Resource as RadioResource;
provides interface RadioConfig;
provides interface RadioPower;
provides interface Read<uint16_t> as ReadRssi;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface ReceiveIndicator as PacketIndicator;
provides interface ReceiveIndicator as EnergyIndicator;
provides interface ReceiveIndicator as ByteIndicator;

}

implementation {

components cc2420xRadioP;
SplitControl = cc2420xRadioP;
cc2420xRadioParams = cc2420xRadioP;
RadioReceive = cc2420xRadioP.RadioReceive;

PacketIndicator = cc2420xRadioP.PacketIndicator;
EnergyIndicator = cc2420xRadioP.EnergyIndicator;
ByteIndicator = cc2420xRadioP.ByteIndicator;

RadioResource = cc2420xRadioP.RadioResource;
RadioConfig = cc2420xRadioP.RadioConfig;
RadioPower = cc2420xRadioP.RadioPower;
ReadRssi = cc2420xRadioP.ReadRssi;

RadioBuffer = cc2420xRadioP.RadioBuffer;
RadioPacket = cc2420xRadioP.RadioPacket;
RadioSend = cc2420xRadioP.RadioSend;

components CC2420XDriverLayerC;
cc2420xRadioP.RadioState -> CC2420XDriverLayerC;

}
