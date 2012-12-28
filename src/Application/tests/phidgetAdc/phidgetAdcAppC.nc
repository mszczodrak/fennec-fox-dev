/*
 *  Phidget ADC Application module for Fennec Fox platform.
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
 * Application: Phidget ADC Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 12/28/2012
 */

#include "phidgetAdcApp.h"

configuration phidgetAdcAppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface phidgetAdcAppParams;
   
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
 
  components phidgetAdcAppP ;
  Mgmt = phidgetAdcAppP;
  Module = phidgetAdcAppP;
  phidgetAdcAppParams = phidgetAdcAppP;
  
  components new TimerMilliC() as TimerImp;
  phidgetAdcAppP.Timer -> TimerImp;

  /* Creating a queue for sending messages over the network */
  components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
  phidgetAdcAppP.NetworkQueue -> NetworkQueueC;

  /* Creating a queue for sending messages over the serial interface */
  components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
  phidgetAdcAppP.SerialQueue -> SerialQueueC;

  /* Creating a pool of message memory for network and serial communication */
  components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
  phidgetAdcAppP.MessagePool -> MessagePoolC;

  components LedsC;
  phidgetAdcAppP.Leds -> LedsC;

  components new phidget_adc_driverC() as PhidgetAdcDriver_0;
  phidgetAdcAppP.Sensor_1_Ctrl -> PhidgetAdcDriver_0.SensorCtrl;
  phidgetAdcAppP.Sensor_1_Setup -> PhidgetAdcDriver_0.AdcSetup;
  phidgetAdcAppP.Sensor_1_Raw -> PhidgetAdcDriver_0.Raw;

  components new phidget_adc_driverC() as PhidgetAdcDriver_1;
  phidgetAdcAppP.Sensor_0_Ctrl -> PhidgetAdcDriver_1.SensorCtrl;
  phidgetAdcAppP.Sensor_0_Setup -> PhidgetAdcDriver_1.AdcSetup;
  phidgetAdcAppP.Sensor_0_Raw -> PhidgetAdcDriver_1.Raw;

  components SerialActiveMessageC;
  components new SerialAMSenderC(SERIAL_PORT);
  components new SerialAMReceiverC(SERIAL_PORT);
  phidgetAdcAppP.SerialAMSend -> SerialAMSenderC.AMSend;
  phidgetAdcAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
  phidgetAdcAppP.SerialPacket -> SerialAMSenderC.Packet; 
  phidgetAdcAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
  phidgetAdcAppP.SerialReceive -> SerialAMReceiverC.Receive;
 
  NetworkAMSend = phidgetAdcAppP.NetworkAMSend;
  NetworkReceive = phidgetAdcAppP.NetworkReceive;
  NetworkSnoop = phidgetAdcAppP.NetworkSnoop;
  NetworkAMPacket = phidgetAdcAppP.NetworkAMPacket;
  NetworkPacket = phidgetAdcAppP.NetworkPacket;
  NetworkPacketAcknowledgements = phidgetAdcAppP.NetworkPacketAcknowledgements;
  NetworkStatus = phidgetAdcAppP.NetworkStatus;

}

