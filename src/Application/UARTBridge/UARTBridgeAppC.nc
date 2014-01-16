/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the <organization> nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox generic UART Bridge application module
  *
  * @author: Marcin K Szczodrak
  */

#include "UARTBridgeApp.h"

generic configuration UARTBridgeAppC() {
provides interface SplitControl;

uses interface UARTBridgeAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components new UARTBridgeAppP();
SplitControl = UARTBridgeAppP;

UARTBridgeAppParams = UARTBridgeAppP;

NetworkAMSend = UARTBridgeAppP.NetworkAMSend;
NetworkReceive = UARTBridgeAppP.NetworkReceive;
NetworkSnoop = UARTBridgeAppP.NetworkSnoop;
NetworkAMPacket = UARTBridgeAppP.NetworkAMPacket;
NetworkPacket = UARTBridgeAppP.NetworkPacket;
NetworkPacketAcknowledgements = UARTBridgeAppP.NetworkPacketAcknowledgements;

components LedsC;
UARTBridgeAppP.Leds -> LedsC;

components SerialActiveMessageC;
components new SerialAMSenderC(100);
components new SerialAMReceiverC(100);
UARTBridgeAppP.SerialAMSend -> SerialAMSenderC.AMSend;
UARTBridgeAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
UARTBridgeAppP.SerialPacket -> SerialAMSenderC.Packet;
UARTBridgeAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
UARTBridgeAppP.SerialReceive -> SerialAMReceiverC.Receive;

/* Creating a queue for sending messages over the serial interface */
components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
UARTBridgeAppP.SerialQueue -> SerialQueueC;

}
