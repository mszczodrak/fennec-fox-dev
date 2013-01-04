/*
 *  Generic Sensor Application module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
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
 * Application: Generic Sensor Application Module
 * Author: Marcin Szczodrak
 * Date: 1/2/2013
 * Last Modified: 1/2/2013
 */

#include "genericSensorApp.h"

configuration genericSensorAppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface genericSensorAppParams;
   
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {
 
  components genericSensorAppP;
  Mgmt = genericSensorAppP;
  Module = genericSensorAppP;
  genericSensorAppParams = genericSensorAppP;
  
  components new TimerMilliC() as TimerImp;
  genericSensorAppP.Timer -> TimerImp;

  components LedsC;
  genericSensorAppP.Leds -> LedsC;

  //components new phidget_1142_0_driverC() as GenericSensorC;
  //components new adxl345_0_driverC() as GenericSensorC;
  components new sht11_0_driverC() as GenericSensorC;

  genericSensorAppP.SensorCtrl -> GenericSensorC.SensorCtrl;
  genericSensorAppP.SensorInfo -> GenericSensorC.SensorInfo;
  //genericSensorAppP.AdcSetup -> GenericSensorC.AdcSetup;
  genericSensorAppP.Read -> GenericSensorC.Read;

  NetworkAMSend = genericSensorAppP.NetworkAMSend;
  NetworkReceive = genericSensorAppP.NetworkReceive;
  NetworkSnoop = genericSensorAppP.NetworkSnoop;
  NetworkAMPacket = genericSensorAppP.NetworkAMPacket;
  NetworkPacket = genericSensorAppP.NetworkPacket;
  NetworkPacketAcknowledgements = genericSensorAppP.NetworkPacketAcknowledgements;
  NetworkStatus = genericSensorAppP.NetworkStatus;
}

