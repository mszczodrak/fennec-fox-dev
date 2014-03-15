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

generic configuration TestSerialC(process_t process) {
provides interface SplitControl;

uses interface TestSerialParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components new TestSerialP(process);
SplitControl = TestSerialP;

TestSerialParams = TestSerialP;

NetworkAMSend = TestSerialP.NetworkAMSend;
NetworkReceive = TestSerialP.NetworkReceive;
NetworkSnoop = TestSerialP.NetworkSnoop;
NetworkAMPacket = TestSerialP.NetworkAMPacket;
NetworkPacket = TestSerialP.NetworkPacket;
NetworkPacketAcknowledgements = TestSerialP.NetworkPacketAcknowledgements;

components LedsC;
TestSerialP.Leds -> LedsC;

components new TimerMilliC() as Timer;
TestSerialP.Timer -> Timer;


components SerialActiveMessageC;
components new SerialAMSenderC(100);
components new SerialAMReceiverC(100);
TestSerialP.SerialAMSend -> SerialAMSenderC.AMSend;
TestSerialP.SerialAMPacket -> SerialAMSenderC.AMPacket;
TestSerialP.SerialPacket -> SerialAMSenderC.Packet;
TestSerialP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
TestSerialP.SerialReceive -> SerialAMReceiverC.Receive;

}
