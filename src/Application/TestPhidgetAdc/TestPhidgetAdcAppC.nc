/*
 *  ADC Test application module for Fennec Fox platform.
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
 * Application: Phidget Sensor Application for Z1
 * Author: Marcin Szczodrak
 * Date: 12/7/2012
 */

#include "TestPhidgetAdcApp.h"

configuration TestPhidgetAdcAppC {
  provides interface Mgmt;
  provides interface Module;

  uses interface TestPhidgetAdcAppParams;
   
  uses interface AMSend as NetworkAMSend;
  uses interface Receive as NetworkReceive;
  uses interface Receive as NetworkSnoop;
  uses interface AMPacket as NetworkAMPacket;
  uses interface Packet as NetworkPacket;
  uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
  uses interface ModuleStatus as NetworkStatus;
}

implementation {
  
  components TestPhidgetAdcAppP ;
  Mgmt = TestPhidgetAdcAppP;
  Module = TestPhidgetAdcAppP;
  
  components new TimerMilliC() as TimerImp;
  components TestPhidgetAdcAppC;
  TestPhidgetAdcAppP.Timer -> TimerImp;

  /* Creating a queue for sending messages over the network */
  components new QueueC(message_t*, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
  TestPhidgetAdcAppP.NetworkQueue -> NetworkQueueC;

  /* Creating a queue for sending messages over the serial interface */
  components new QueueC(message_t*, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
  TestPhidgetAdcAppP.SerialQueue -> SerialQueueC;

  /* Creating a pool of message memory for network communication */
  components new PoolC(message_t, APP_NETWORK_QUEUE_SIZE) as NetworkPoolC;
  TestPhidgetAdcAppP.NetworkPool -> NetworkPoolC;

  /* Creating a pool of message memory for serial communication */
  components new PoolC(message_t, APP_SERIAL_QUEUE_SIZE) as SerialPoolC;
  TestPhidgetAdcAppP.SerialPool -> SerialPoolC;

  components LedsC;
  TestPhidgetAdcAppP.LedsBlink -> LedsC;

  components new phidget_adc_driverC() as PhidgetAdcDriver ;
  TestPhidgetAdcAppP.SensorCtrl -> PhidgetAdcDriver.SensorCtrl;
  TestPhidgetAdcAppP.Raw -> PhidgetAdcDriver.Raw;
  TestPhidgetAdcAppP.Occurence -> PhidgetAdcDriver.Occurence;

  //serial wiring
  components SerialActiveMessageC;
  components new SerialAMSenderC(GENERIC_APP_ID);
  components new SerialAMReceiverC(GENERIC_APP_ID);
  TestPhidgetAdcAppP.SerialAMSend -> SerialAMSenderC.AMSend;
  TestPhidgetAdcAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
  TestPhidgetAdcAppP.SerialPacket -> SerialAMSenderC.Packet; 
  TestPhidgetAdcAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
  TestPhidgetAdcAppP.SerialReceive -> SerialAMReceiverC.Receive;
 
  //network wiring - implemented by  Fennec Fox stack
  NetworkAMSend = TestPhidgetAdcAppP.NetworkAMSend;
  NetworkReceive = TestPhidgetAdcAppP.NetworkReceive;
  NetworkSnoop = TestPhidgetAdcAppP.NetworkSnoop;
  NetworkAMPacket = TestPhidgetAdcAppP.NetworkAMPacket;
  NetworkPacket = TestPhidgetAdcAppP.NetworkPacket;
  NetworkPacketAcknowledgements = TestPhidgetAdcAppP.NetworkPacketAcknowledgements;
  NetworkStatus = TestPhidgetAdcAppP.NetworkStatus;

  TestPhidgetAdcAppParams = TestPhidgetAdcAppP;
}

