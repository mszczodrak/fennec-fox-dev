/*
 *  Cape radio module for Fennec Fox platform.
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
 * Network: Cape Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration capeRadioC {
  provides interface Mgmt;
  provides interface Receive as RadioReceive;
  provides interface ModuleStatus as RadioStatus;

  uses interface capeRadioParams;

  provides interface Resource as RadioResource;
  provides interface RadioConfig;
  provides interface RadioPower;
  provides interface Read<uint16_t> as ReadRssi;

  provides interface StdControl as RadioControl;

  provides interface RadioTransmit;

  provides interface ReceiveIndicator as PacketIndicator;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;

}

implementation {

  components capeSimRadioC;
  Mgmt = capeSimRadioC;
  capeRadioParams = capeSimRadioC;
  RadioReceive = capeSimRadioC.RadioReceive;
  RadioStatus = capeSimRadioC.RadioStatus;

  PacketIndicator = capeSimRadioC.PacketIndicator;
  EnergyIndicator = capeSimRadioC.EnergyIndicator;
  ByteIndicator = capeSimRadioC.ByteIndicator;

  RadioResource = capeSimRadioC.RadioResource;
  RadioConfig = capeSimRadioC.RadioConfig;
  RadioPower = capeSimRadioC.RadioPower;
  ReadRssi = capeSimRadioC.ReadRssi;

  RadioTransmit = capeSimRadioC.RadioTransmit;
  RadioControl = capeSimRadioC.RadioControl;

}
