/*
 * Copyright (c) 2014, Columbia University.
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
  * Fennec Fox cc2420x radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/05/2014
  */


configuration cc2420xMultiC {
provides interface RadioReceive[process_t process_id];
provides interface RadioSend[process_t process_id];
provides interface RadioBuffer[process_t process_id];

provides interface RadioState[process_t process_id];
provides interface RadioCCA[process_t process_id];

provides interface Resource as RadioResource;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface cc2420XDriverParams;
}

implementation {

components cc2420xMultiP;
components CC2420XDriverLayerC;
components new RadioAlarmC();
components new SoftwareAckLayerC();

RadioPacket = CC2420XDriverLayerC.RadioPacket;

RadioSend = cc2420xMultiP.RadioSend;
RadioReceive = cc2420xMultiP.RadioReceive;
RadioBuffer = cc2420xMultiP.RadioBuffer;
cc2420xMultiP.SubRadioReceive -> SoftwareAckLayerC.RadioReceive;
cc2420xMultiP.SubRadioSend -> AutoResourceAcquireLayerC;

RadioCCA = cc2420xMultiP.RadioCCA;
cc2420xMultiP.SubRadioCCA -> CC2420XDriverLayerC.RadioCCA;

cc2420XDriverParams = CC2420XDriverLayerC.cc2420XDriverParams;

RadioState = cc2420xMultiP.RadioState;
cc2420xMultiP.SubRadioState -> CC2420XDriverLayerC.RadioState;

// -------- RadioAlarm

RadioAlarmC.Alarm -> CC2420XDriverLayerC;

components new AutoResourceAcquireLayerC();
AutoResourceAcquireLayerC.Resource -> SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];
AutoResourceAcquireLayerC -> SoftwareAckLayerC.RadioSend; 

components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as SendResourceC;
RadioResource = SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];

SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
SoftwareAckLayerC.SubSend -> CC2420XDriverLayerC.RadioSend;
SoftwareAckLayerC.SubReceive -> CC2420XDriverLayerC.RadioReceive;
SoftwareAckLayerC.RadioPacket -> CC2420XDriverLayerC.RadioPacket;

PacketTransmitPower = CC2420XDriverLayerC.PacketTransmitPower;
PacketLinkQuality = CC2420XDriverLayerC.PacketLinkQuality;
PacketRSSI = CC2420XDriverLayerC.PacketRSSI;
RadioLinkPacketMetadata = CC2420XDriverLayerC;
PacketTimeSync = CC2420XDriverLayerC.PacketTimeSync;

CC2420XDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

}
