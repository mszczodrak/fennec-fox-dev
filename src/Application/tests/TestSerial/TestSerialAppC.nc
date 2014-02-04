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
  * Serial Test Application Module
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */

generic configuration TestSerialAppC() {
provides interface SplitControl;

uses interface TestSerialAppParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components new TestSerialAppP();
SplitControl = TestSerialAppP;

TestSerialAppParams = TestSerialAppP;

NetworkAMSend = TestSerialAppP.NetworkAMSend;
NetworkReceive = TestSerialAppP.NetworkReceive;
NetworkSnoop = TestSerialAppP.NetworkSnoop;
NetworkAMPacket = TestSerialAppP.NetworkAMPacket;
NetworkPacket = TestSerialAppP.NetworkPacket;
NetworkPacketAcknowledgements = TestSerialAppP.NetworkPacketAcknowledgements;

components LedsC;
TestSerialAppP.Leds -> LedsC;

components new TimerMilliC() as Timer;
TestSerialAppP.Timer -> Timer;


components SerialActiveMessageC;
components new SerialAMSenderC(100);
components new SerialAMReceiverC(100);
TestSerialAppP.SerialAMSend -> SerialAMSenderC.AMSend;
TestSerialAppP.SerialAMPacket -> SerialAMSenderC.AMPacket;
TestSerialAppP.SerialPacket -> SerialAMSenderC.Packet;
TestSerialAppP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
TestSerialAppP.SerialReceive -> SerialAMReceiverC.Receive;

}
