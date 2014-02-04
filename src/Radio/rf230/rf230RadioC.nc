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
  * Fennec Fox rf230 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/11/2014
  */


configuration rf230RadioC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface rf230RadioParams;

provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;
}

implementation {

components rf230RadioP;

components new RadioAlarmC();

#ifdef RF230_HARDWARE_ACK
components RF230DriverHwAckC as RadioDriverLayerC;
#else
components RF230DriverLayerC as RadioDriverLayerC;
components new SoftwareAckLayerC();
#endif

//components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as ResourceC;
//RadioResource = ResourceC.Resource[unique(RADIO_SEND_RESOURCE)];

SplitControl = rf230RadioP;
rf230RadioParams = rf230RadioP;
RadioReceive = rf230RadioP.RadioReceive;
RadioBuffer = rf230RadioP.RadioBuffer;
RadioSend = rf230RadioP.RadioSend;
RadioState = rf230RadioP.RadioState;

RadioPacket = RadioDriverLayerC.RadioPacket;
rf230RadioP.RadioPacket -> RadioDriverLayerC.RadioPacket;
rf230RadioP.SubRadioSend -> AutoResourceAcquireLayerC;
rf230RadioP.SubRadioState -> RadioDriverLayerC.RadioState;

// -------- RadioAlarm

RadioAlarmC.Alarm -> RadioDriverLayerC;

rf230RadioParams = RadioDriverLayerC;

components new AutoResourceAcquireLayerC();
AutoResourceAcquireLayerC.Resource -> SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];


#ifndef RF230_HARDWARE_ACK
AutoResourceAcquireLayerC -> RadioDriverLayerC.RadioSend; 
rf230RadioP.SubRadioReceive -> RadioDriverLayerC.RadioReceive;
#else 
AutoResourceAcquireLayerC -> SoftwareAckLayerC.RadioSend; 
SoftwareAckLayerC.SubSend -> RadioDriverLayerC.RadioSend;
SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
SoftwareAckLayerC.SubReceive -> RadioDriverLayerC.RadioReceive;
SoftwareAckLayerC.RadioPacket -> RadioDriverLayerC.RadioPacket;
rf230RadioP.SubRadioReceive -> SoftwareAckLayerC.RadioReceive;
#endif


components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as SendResourceC;
RadioResource = SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];


PacketTransmitPower = RadioDriverLayerC.PacketTransmitPower;
PacketLinkQuality = RadioDriverLayerC.PacketLinkQuality;
PacketRSSI = RadioDriverLayerC.PacketRSSI;
RadioLinkPacketMetadata = RadioDriverLayerC;
PacketTimeSync = RadioDriverLayerC.PacketTimeSync;
RadioCCA = RadioDriverLayerC.RadioCCA;

RadioDriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

}
