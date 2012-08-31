/*
 *  Null radio module for Fennec Fox platform.
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
 * Network: Null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

configuration cc2420RadioC {
  provides interface Mgmt;
  provides interface Module;
  provides interface AMSend as RadioAMSend;
  provides interface Receive as RadioReceive;
  provides interface Receive as RadioSnoop;
  provides interface AMPacket as RadioAMPacket;
  provides interface Packet as RadioPacket;
  provides interface PacketAcknowledgements as RadioPacketAcknowledgements;
  provides interface ModuleStatus as RadioStatus;

  uses interface cc2420RadioParams;

  provides interface Resource as RadioResource;
  provides interface RadioConfig;
  provides interface RadioPower;
  provides interface Read<uint16_t> as ReadRssi;

  provides interface StdControl;

  provides interface RadioTransmit;

  provides interface ReceiveIndicator as PacketIndicator;
  provides interface ReceiveIndicator as EnergyIndicator;
  provides interface ReceiveIndicator as ByteIndicator;

}

implementation {

  enum {
    CC_FF_PORT = 114,
  };

  components cc2420RadioP;
  Mgmt = cc2420RadioP;
  Module = cc2420RadioP;
  cc2420RadioParams = cc2420RadioP;
  RadioAMSend = cc2420RadioP.RadioAMSend;
  //RadioReceive = cc2420RadioP.RadioReceive;
  RadioSnoop = cc2420RadioP.RadioSnoop;
  RadioAMPacket = cc2420RadioP.RadioAMPacket;
  RadioPacket = cc2420RadioP.RadioPacket;
  RadioPacketAcknowledgements = cc2420RadioP.RadioPacketAcknowledgements;
  RadioStatus = cc2420RadioP.RadioStatus;

  StdControl = cc2420RadioP.StdControl;

  components cc2420ControlC;
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

  components cc2420TransmitC;
  cc2420RadioP.TransmitControl -> cc2420TransmitC.StdControl;
  ByteIndicator = cc2420TransmitC.ByteIndicator;

  RadioTransmit = cc2420TransmitC.RadioTransmit;

  cc2420RadioParams = cc2420TransmitC.cc2420RadioParams;

  RadioReceive = cc2420TransmitC.Receive;
  cc2420TransmitC.SubReceive -> cc2420ReceiveC.Receive;
  cc2420TransmitC.EnergyIndicator -> cc2420DriverC.EnergyIndicator;

  components cc2420DriverC;
  EnergyIndicator = cc2420DriverC.EnergyIndicator;

}
