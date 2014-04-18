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

#include "phidgetAdc.h"

generic configuration phidgetAdcC() {
provides interface SplitControl;

uses interface phidgetAdcParams;
   
uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
 
enum {
    SERIAL_PORT = 1
};
 
components new phidgetAdcP();
SplitControl = phidgetAdcP;
phidgetAdcParams = phidgetAdcP;
  
components new TimerMilliC() as TimerImp;
phidgetAdcP.Timer -> TimerImp;

/* Creating a queue for sending messages over the network */
components new QueueC(msg_queue_t, APP_NETWORK_QUEUE_SIZE) as NetworkQueueC;
phidgetAdcP.NetworkQueue -> NetworkQueueC;

/* Creating a queue for sending messages over the serial interface */
components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
phidgetAdcP.SerialQueue -> SerialQueueC;

/* Creating a pool of message memory for network and serial communication */
components new PoolC(message_t, APP_MESSAGE_POOL) as MessagePoolC;
phidgetAdcP.MessagePool -> MessagePoolC;

components LedsC;
phidgetAdcP.Leds -> LedsC;

components new phidget_adc_driverC() as PhidgetAdcDriver_0;
phidgetAdcP.Sensor_0_Ctrl -> PhidgetAdcDriver_0.SensorCtrl;
phidgetAdcP.Sensor_0_Setup -> PhidgetAdcDriver_0.AdcSetup;
phidgetAdcP.Sensor_0_Read -> PhidgetAdcDriver_0.Read;

components new phidget_adc_driverC() as PhidgetAdcDriver_1;
phidgetAdcP.Sensor_1_Ctrl -> PhidgetAdcDriver_1.SensorCtrl;
phidgetAdcP.Sensor_1_Setup -> PhidgetAdcDriver_1.AdcSetup;
phidgetAdcP.Sensor_1_Read -> PhidgetAdcDriver_1.Read;

components SerialActiveMessageC;
components new SerialAMSenderC(SERIAL_PORT);
components new SerialAMReceiverC(SERIAL_PORT);
phidgetAdcP.SerialAMSend -> SerialAMSenderC.AMSend;
phidgetAdcP.SerialAMPacket -> SerialAMSenderC.AMPacket;
phidgetAdcP.SerialPacket -> SerialAMSenderC.Packet; 
phidgetAdcP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
phidgetAdcP.SerialReceive -> SerialAMReceiverC.Receive;
 
NetworkAMSend = phidgetAdcP.NetworkAMSend;
NetworkReceive = phidgetAdcP.NetworkReceive;
NetworkSnoop = phidgetAdcP.NetworkSnoop;
NetworkAMPacket = phidgetAdcP.NetworkAMPacket;
NetworkPacket = phidgetAdcP.NetworkPacket;
NetworkPacketAcknowledgements = phidgetAdcP.NetworkPacketAcknowledgements;

}

