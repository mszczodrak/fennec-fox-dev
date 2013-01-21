/*
 *  Phidget Z1 Application module for Fennec Fox platform.
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
 * Application: Phidget Z1 Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 12/28/2012
 */

#include "phidgetZ1App.h"

configuration phidgetZ1AppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface phidgetZ1AppParams;
   
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {
 
  enum {
    SERIAL_PORT = 1
  };
 
  components phidgetZ1AppP;
  Mgmt = phidgetZ1AppP;
  Module = phidgetZ1AppP;
  phidgetZ1AppParams = phidgetZ1AppP;
  
  components new TimerMilliC() as TimerImp;
  phidgetZ1AppP.Timer -> TimerImp;

  /* Creating a queue for sending messages over the network */
  components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
  phidgetZ1AppP.NetworkQueue -> NetworkQueueC;

  /* Creating a queue for sending messages over the serial interface */
  components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
  phidgetZ1AppP.SerialQueue -> SerialQueueC;

  /* Creating a pool of message memory for network and serial communication */
  components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
  phidgetZ1AppP.MessagePool -> MessagePoolC;

  components LedsC;
  phidgetZ1AppP.Leds -> LedsC;

  components new tmp102_0_driverC() as TemperatureSensorC;
  phidgetZ1AppP.Temperature_Ctrl -> TemperatureSensorC.SensorCtrl;
  phidgetZ1AppP.Temperature_Info -> TemperatureSensorC.SensorInfo;
  phidgetZ1AppP.Temperature_Read -> TemperatureSensorC.Read;

  components new phidget_adc_driverC() as PhidgetAdcDriver_1;
  phidgetZ1AppP.Sensor_1_Ctrl -> PhidgetAdcDriver_1.SensorCtrl;
  phidgetZ1AppP.Sensor_1_Setup -> PhidgetAdcDriver_1.AdcSetup;
  phidgetZ1AppP.Sensor_1_Info -> PhidgetAdcDriver_1.SensorInfo;
  phidgetZ1AppP.Sensor_1_Read -> PhidgetAdcDriver_1.Read;

  components new phidget_adc_driverC() as PhidgetAdcDriver_2;
  phidgetZ1AppP.Sensor_2_Ctrl -> PhidgetAdcDriver_2.SensorCtrl;
  phidgetZ1AppP.Sensor_2_Setup -> PhidgetAdcDriver_2.AdcSetup;
  phidgetZ1AppP.Sensor_2_Info -> PhidgetAdcDriver_2.SensorInfo;
  phidgetZ1AppP.Sensor_2_Read -> PhidgetAdcDriver_2.Read;

  components SerialActiveMessageC;
  components new SerialAMSenderC(SERIAL_PORT);
  components new SerialAMReceiverC(SERIAL_PORT);
  phidgetZ1AppP.SerialAMSend -> SerialAMSenderC.AMSend;
  phidgetZ1AppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
  phidgetZ1AppP.SerialPacket -> SerialAMSenderC.Packet; 
  phidgetZ1AppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
  phidgetZ1AppP.SerialReceive -> SerialAMReceiverC.Receive;
 
  NetworkAMSend = phidgetZ1AppP.NetworkAMSend;
  NetworkReceive = phidgetZ1AppP.NetworkReceive;
  NetworkSnoop = phidgetZ1AppP.NetworkSnoop;
  NetworkAMPacket = phidgetZ1AppP.NetworkAMPacket;
  NetworkPacket = phidgetZ1AppP.NetworkPacket;
  NetworkPacketAcknowledgements = phidgetZ1AppP.NetworkPacketAcknowledgements;
  NetworkStatus = phidgetZ1AppP.NetworkStatus;

}

