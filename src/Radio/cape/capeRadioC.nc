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
  provides interface Mgmt;
  provides interface Receive as RadioReceive;
  provides interface ModuleStatus as RadioStatus;

  uses interface capeRadioParams;

  provides interface Resource as RadioResource;
  provides interface RadioConfig;
  provides interface RadioPower;
  provides interface Read<uint16_t> as ReadRssi;

  provides interface SplitControl as RadioControl;

  provides interface RadioPacket;
  provides interface RadioBuffer;
  provides interface RadioSend;

  provides interface ReceiveIndicator as PacketIndicator;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;

}

implementation {

  components capeRadioP;
  Mgmt = capeRadioP;
  capeRadioParams = capeRadioP;
  RadioReceive = capeRadioP.RadioReceive;
  RadioStatus = capeRadioP.RadioStatus;

  PacketIndicator = capeRadioP.PacketIndicator;
  EnergyIndicator = capeRadioP.EnergyIndicator;
  ByteIndicator = capeRadioP.ByteIndicator;

  RadioResource = capeRadioP.RadioResource;
  RadioConfig = capeRadioP.RadioConfig;
  RadioPower = capeRadioP.RadioPower;
  ReadRssi = capeRadioP.ReadRssi;

  RadioBuffer = capeRadioP.RadioBuffer;
  RadioPacket = capeRadioP.RadioPacket;
  RadioSend = capeRadioP.RadioSend;
  RadioControl = capeRadioP.RadioControl;


  //components CapeActiveMessageC as AM;
  components CapePacketModelC as Network;
  components CpmModelC as Model;

  capeRadioP.AMControl -> Network;
  //capeRadioP.Packet -> AM;
  //capeRadioP.AMPacket -> AM;


  //capeRadioP.ReceiveReceive -> AM.Receive;
  //capeRadioP.AMSend -> AM.AMSend;

  capeRadioP.Model -> Network.Packet;

  //AM.Model -> Network.Packet;
  Network.GainRadioModel -> Model;
}
