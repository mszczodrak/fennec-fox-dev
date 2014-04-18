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
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
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

#include "UARTBridge.h"

generic configuration UARTBridgeC(process_t process) {
provides interface SplitControl;

uses interface UARTBridgeParams;

uses interface AMSend as SubAMSend;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface PacketAcknowledgements as SubPacketAcknowledgements;

uses interface PacketField<uint8_t> as SubPacketLinkQuality;
uses interface PacketField<uint8_t> as SubPacketTransmitPower;
uses interface PacketField<uint8_t> as SubPacketRSSI;
}

implementation {
components new UARTBridgeP(process);
SplitControl = UARTBridgeP;

UARTBridgeParams = UARTBridgeP;

SubAMSend = UARTBridgeP.SubAMSend;
SubReceive = UARTBridgeP.SubReceive;
SubSnoop = UARTBridgeP.SubSnoop;
SubAMPacket = UARTBridgeP.SubAMPacket;
SubPacket = UARTBridgeP.SubPacket;
SubPacketAcknowledgements = UARTBridgeP.SubPacketAcknowledgements;

SubPacketLinkQuality = UARTBridgeP.SubPacketLinkQuality;
SubPacketTransmitPower = UARTBridgeP.SubPacketTransmitPower;
SubPacketRSSI = UARTBridgeP.SubPacketRSSI;

components LedsC;
UARTBridgeP.Leds -> LedsC;

components SerialActiveMessageC;
components new SerialAMSenderC(100);
components new SerialAMReceiverC(100);
UARTBridgeP.SerialAMSend -> SerialAMSenderC.AMSend;
UARTBridgeP.SerialAMPacket -> SerialAMSenderC.AMPacket;
UARTBridgeP.SerialPacket -> SerialAMSenderC.Packet;
UARTBridgeP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
UARTBridgeP.SerialReceive -> SerialAMReceiverC.Receive;

/* Creating a queue for sending messages over the serial interface */
components new QueueC(msg_queue_t, APP_SERIAL_QUEUE_SIZE) as SerialQueueC;
UARTBridgeP.SerialQueue -> SerialQueueC;

}
