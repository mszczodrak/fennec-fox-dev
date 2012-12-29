/*
 *  Phidget Light and Motion Application module for Fennec Fox platform.
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
 * Application: Phidget Light and Motion Application Module
 * Author: Marcin Szczodrak
 * Date: 12/28/2012
 * Last Modified: 12/28/2012
 */

#include "phidgetLightAndMotionApp.h"

configuration phidgetLightAndMotionAppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface phidgetLightAndMotionAppParams;
   
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
 
  components phidgetLightAndMotionAppP;
  Mgmt = phidgetLightAndMotionAppP;
  Module = phidgetLightAndMotionAppP;
  phidgetLightAndMotionAppParams = phidgetLightAndMotionAppP;
  
  components new TimerMilliC() as TimerImp;
  phidgetLightAndMotionAppP.Timer -> TimerImp;

  /* Creating a queue for sending messages over the network */
  components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
  phidgetLightAndMotionAppP.NetworkQueue -> NetworkQueueC;

  /* Creating a queue for sending messages over the serial interface */
  components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
  phidgetLightAndMotionAppP.SerialQueue -> SerialQueueC;

  /* Creating a pool of message memory for network and serial communication */
  components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
  phidgetLightAndMotionAppP.MessagePool -> MessagePoolC;

  components LedsC;
  phidgetLightAndMotionAppP.Leds -> LedsC;

  components new phidget_adc_driverC() as PhidgetAdcDriver_0;
  phidgetLightAndMotionAppP.Sensor_1_Ctrl -> PhidgetAdcDriver_0.SensorCtrl;
  phidgetLightAndMotionAppP.Sensor_1_Setup -> PhidgetAdcDriver_0.AdcSetup;
  phidgetLightAndMotionAppP.Sensor_1_Raw -> PhidgetAdcDriver_0.Raw;

  components new phidget_adc_driverC() as PhidgetAdcDriver_1;
  phidgetLightAndMotionAppP.Sensor_0_Ctrl -> PhidgetAdcDriver_1.SensorCtrl;
  phidgetLightAndMotionAppP.Sensor_0_Setup -> PhidgetAdcDriver_1.AdcSetup;
  phidgetLightAndMotionAppP.Sensor_0_Raw -> PhidgetAdcDriver_1.Raw;

  components SerialActiveMessageC;
  components new SerialAMSenderC(SERIAL_PORT);
  components new SerialAMReceiverC(SERIAL_PORT);
  phidgetLightAndMotionAppP.SerialAMSend -> SerialAMSenderC.AMSend;
  phidgetLightAndMotionAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
  phidgetLightAndMotionAppP.SerialPacket -> SerialAMSenderC.Packet; 
  phidgetLightAndMotionAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
  phidgetLightAndMotionAppP.SerialReceive -> SerialAMReceiverC.Receive;
 
  NetworkAMSend = phidgetLightAndMotionAppP.NetworkAMSend;
  NetworkReceive = phidgetLightAndMotionAppP.NetworkReceive;
  NetworkSnoop = phidgetLightAndMotionAppP.NetworkSnoop;
  NetworkAMPacket = phidgetLightAndMotionAppP.NetworkAMPacket;
  NetworkPacket = phidgetLightAndMotionAppP.NetworkPacket;
  NetworkPacketAcknowledgements = phidgetLightAndMotionAppP.NetworkPacketAcknowledgements;
  NetworkStatus = phidgetLightAndMotionAppP.NetworkStatus;

}

