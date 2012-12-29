/*
 *  Phidget 1142 and Phidget 1111 Application module for Fennec Fox platform.
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
 * Application: Phidget 1142 and Phidget 1111 Application Module
 * Author: Marcin Szczodrak
 * Date: 12/28/2012
 * Last Modified: 12/28/2012
 */

#include "phidget1142And1111App.h"

configuration phidget1142And1111AppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface phidget1142And1111AppParams;
   
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
 
  components phidget1142And1111AppP;
  Mgmt = phidget1142And1111AppP;
  Module = phidget1142And1111AppP;
  phidget1142And1111AppParams = phidget1142And1111AppP;
  
  components new TimerMilliC() as TimerImp;
  phidget1142And1111AppP.Timer -> TimerImp;

  /* Creating a queue for sending messages over the network */
  components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
  phidget1142And1111AppP.NetworkQueue -> NetworkQueueC;

  /* Creating a queue for sending messages over the serial interface */
  components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
  phidget1142And1111AppP.SerialQueue -> SerialQueueC;

  /* Creating a pool of message memory for network and serial communication */
  components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
  phidget1142And1111AppP.MessagePool -> MessagePoolC;

  components LedsC;
  phidget1142And1111AppP.Leds -> LedsC;

  components phidget_1142_0_driverC;
  phidget1142And1111AppP.Sensor_1_Ctrl -> phidget_1142_0_driverC.SensorCtrl;
  phidget1142And1111AppP.Sensor_1_Setup -> phidget_1142_0_driverC.AdcSetup;
  phidget1142And1111AppP.Sensor_1_Raw -> phidget_1142_0_driverC.Raw;

  components new phidget_adc_driverC() as PhidgetAdcDriver_1;
  phidget1142And1111AppP.Sensor_0_Ctrl -> PhidgetAdcDriver_1.SensorCtrl;
  phidget1142And1111AppP.Sensor_0_Setup -> PhidgetAdcDriver_1.AdcSetup;
  phidget1142And1111AppP.Sensor_0_Raw -> PhidgetAdcDriver_1.Raw;

  components SerialActiveMessageC;
  components new SerialAMSenderC(SERIAL_PORT);
  components new SerialAMReceiverC(SERIAL_PORT);
  phidget1142And1111AppP.SerialAMSend -> SerialAMSenderC.AMSend;
  phidget1142And1111AppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
  phidget1142And1111AppP.SerialPacket -> SerialAMSenderC.Packet; 
  phidget1142And1111AppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
  phidget1142And1111AppP.SerialReceive -> SerialAMReceiverC.Receive;
 
  NetworkAMSend = phidget1142And1111AppP.NetworkAMSend;
  NetworkReceive = phidget1142And1111AppP.NetworkReceive;
  NetworkSnoop = phidget1142And1111AppP.NetworkSnoop;
  NetworkAMPacket = phidget1142And1111AppP.NetworkAMPacket;
  NetworkPacket = phidget1142And1111AppP.NetworkPacket;
  NetworkPacketAcknowledgements = phidget1142And1111AppP.NetworkPacketAcknowledgements;
  NetworkStatus = phidget1142And1111AppP.NetworkStatus;

}

