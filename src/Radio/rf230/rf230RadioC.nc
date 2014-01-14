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
components RF230DriverLayerC;

components new RadioAlarmC();
components new SoftwareAckLayerC();

//components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as ResourceC;
//RadioResource = ResourceC.Resource[unique(RADIO_SEND_RESOURCE)];

SplitControl = rf230RadioP;
rf230RadioParams = rf230RadioP;
RadioReceive = rf230RadioP.RadioReceive;
RadioBuffer = rf230RadioP.RadioBuffer;
RadioSend = rf230RadioP.RadioSend;
RadioState = rf230RadioP.RadioState;

RadioPacket = RF230DriverLayerC.RadioPacket;
rf230RadioP.RadioPacket -> RF230DriverLayerC.RadioPacket;
rf230RadioP.SubRadioSend -> AutoResourceAcquireLayerC;
rf230RadioP.SubRadioReceive -> SoftwareAckLayerC.RadioReceive;
rf230RadioP.SubRadioState -> RF230DriverLayerC.RadioState;

// -------- RadioAlarm

RadioAlarmC.Alarm -> RF230DriverLayerC;

rf230RadioParams = RF230DriverLayerC;

components new AutoResourceAcquireLayerC();
AutoResourceAcquireLayerC.Resource -> SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];
AutoResourceAcquireLayerC -> SoftwareAckLayerC.RadioSend; 

components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as SendResourceC;
RadioResource = SendResourceC.Resource[unique(RADIO_SEND_RESOURCE)];

SoftwareAckLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];
SoftwareAckLayerC.SubSend -> RF230DriverLayerC.RadioSend;
SoftwareAckLayerC.SubReceive -> RF230DriverLayerC.RadioReceive;
SoftwareAckLayerC.RadioPacket -> RF230DriverLayerC.RadioPacket;

PacketTransmitPower = RF230DriverLayerC.PacketTransmitPower;
PacketLinkQuality = RF230DriverLayerC.PacketLinkQuality;
PacketRSSI = RF230DriverLayerC.PacketRSSI;
RadioLinkPacketMetadata = RF230DriverLayerC;
PacketTimeSync = RF230DriverLayerC.PacketTimeSync;
RadioCCA = RF230DriverLayerC.RadioCCA;

RF230DriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

}
