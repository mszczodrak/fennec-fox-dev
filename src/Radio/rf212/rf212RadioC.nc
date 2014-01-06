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
  * Fennec Fox rf212 radio driver adaptation
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/06/2014
  */


configuration rf212RadioC {
provides interface SplitControl;
provides interface RadioReceive;

uses interface rf212RadioParams;

provides interface Resource as RadioResource;

provides interface RadioPacket;
provides interface RadioBuffer;
provides interface RadioSend;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;

provides interface RadioState;
provides interface LinkPacketMetadata as RadioLinkPacketMetadata;
provides interface RadioCCA;
}

implementation {

#define UQ_METADATA_FLAGS       "UQ_RF212_METADATA_FLAGS"
#define UQ_RADIO_ALARM          "UQ_RF212_RADIO_ALARM"



components rf212RadioP;
SplitControl = rf212RadioP;
rf212RadioParams = rf212RadioP;
RadioReceive = rf212RadioP.RadioReceive;

RadioBuffer = rf212RadioP.RadioBuffer;
RadioSend = rf212RadioP.RadioSend;
RadioState = rf212RadioP.RadioState;

components new SimpleFcfsArbiterC(RADIO_SEND_RESOURCE) as ResourceC;
RadioResource = ResourceC.Resource[unique(RADIO_SEND_RESOURCE)];

components RF212DriverLayerC;

PacketTransmitPower = RF212DriverLayerC.PacketTransmitPower;
PacketRSSI = RF212DriverLayerC.PacketRSSI;
PacketTimeSyncOffset = RF212DriverLayerC.PacketTimeSyncOffset;
PacketLinkQuality = RF212DriverLayerC.PacketLinkQuality;
RadioPacket = RF212DriverLayerC.RadioPacket;
RadioCCA = RF212DriverLayerC.RadioCCA;

components new RadioAlarmC();
RadioAlarmC.Alarm -> RF212DriverLayerC;
RF212DriverLayerC.RadioAlarm -> RadioAlarmC.RadioAlarm[unique(UQ_RADIO_ALARM)];

RadioLinkPacketMetadata = RF212DriverLayerC.LinkPacketMetadata;

components new MetadataFlagsLayerC();
MetadataFlagsLayerC.SubPacket -> RF212DriverLayerC;

RF212DriverLayerC.TransmitPowerFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
RF212DriverLayerC.RSSIFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];
RF212DriverLayerC.TimeSyncFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];

components new TimeStampingLayerC();
TimeStampingLayerC.LocalTimeRadio -> RF212DriverLayerC;
TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;
TimeStampingLayerC.TimeStampFlag -> MetadataFlagsLayerC.PacketFlag[unique(UQ_METADATA_FLAGS)];

RF212DriverLayerC.PacketTimeStamp -> TimeStampingLayerC;


rf212RadioP.SubRadioState -> RF212DriverLayerC.RadioState;
rf212RadioP.SubRadioSend -> RF212DriverLayerC.RadioSend;
rf212RadioP.SubRadioReceive -> RF212DriverLayerC.RadioReceive;
rf212RadioP.RadioPacket -> RF212DriverLayerC.RadioPacket;

}
