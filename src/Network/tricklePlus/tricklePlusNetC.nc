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
  * Fennec Fox Trickle Network Protocol adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/18/2010
  */


#include <Fennec.h>

configuration tricklePlusNetC {
provides interface Mgmt;
provides interface AMSend as NetworkAMSend;
provides interface Receive as NetworkReceive;
provides interface Receive as NetworkSnoop;
provides interface AMPacket as NetworkAMPacket;
provides interface Packet as NetworkPacket;
provides interface PacketAcknowledgements as NetworkPacketAcknowledgements;

uses interface tricklePlusNetParams;

uses interface AMSend as MacAMSend;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface PacketAcknowledgements as MacPacketAcknowledgements;
}

implementation {

components tricklePlusNetP;
Mgmt = tricklePlusNetP;
tricklePlusNetParams = tricklePlusNetP;
NetworkAMSend = tricklePlusNetP.NetworkAMSend;
NetworkReceive = tricklePlusNetP.NetworkReceive;
NetworkSnoop = tricklePlusNetP.NetworkSnoop;
NetworkAMPacket = tricklePlusNetP.NetworkAMPacket;
NetworkPacket = tricklePlusNetP.NetworkPacket;
NetworkPacketAcknowledgements = tricklePlusNetP.NetworkPacketAcknowledgements;

MacAMSend = tricklePlusNetP;
MacReceive = tricklePlusNetP.MacReceive;
MacSnoop = tricklePlusNetP.MacSnoop;
MacAMPacket = tricklePlusNetP.MacAMPacket;
MacPacket = tricklePlusNetP.MacPacket;
MacPacketAcknowledgements = tricklePlusNetP.MacPacketAcknowledgements;

components new TrickleTimerMilliC(1, 1024, 1, 1);
tricklePlusNetP.TrickleTimer[TRICKLE_ID] -> TrickleTimerMilliC.TrickleTimer[TRICKLE_ID];

tricklePlusNetParams = TrickleTimerMilliC;

}
