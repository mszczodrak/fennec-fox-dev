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
  * Fennec Fox TelosB Sensors Application
  *
  * @author: Marcin K Szczodrak
  * @updated: 02/04/2014
  */

generic configuration TelosbSensorsC(process_t process) {
provides interface SplitControl;

uses interface TelosbSensorsParams;

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
components new TelosbSensorsP(process);
SplitControl = TelosbSensorsP;

TelosbSensorsParams = TelosbSensorsP;

SubAMSend = TelosbSensorsP.SubAMSend;
SubReceive = TelosbSensorsP.SubReceive;
SubSnoop = TelosbSensorsP.SubSnoop;
SubAMPacket = TelosbSensorsP.SubAMPacket;
SubPacket = TelosbSensorsP.SubPacket;
SubPacketAcknowledgements = TelosbSensorsP.SubPacketAcknowledgements;

components SerialActiveMessageC;
components new SerialAMSenderC(100);
components new SerialAMReceiverC(100);
TelosbSensorsP.SerialAMSend -> SerialAMSenderC.AMSend;
TelosbSensorsP.SerialAMPacket -> SerialAMSenderC.AMPacket;
TelosbSensorsP.SerialPacket -> SerialAMSenderC.Packet;
TelosbSensorsP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
TelosbSensorsP.SerialReceive -> SerialAMReceiverC.Receive;

SubPacketLinkQuality = TelosbSensorsP.SubPacketLinkQuality;
SubPacketTransmitPower = TelosbSensorsP.SubPacketTransmitPower;
SubPacketRSSI = TelosbSensorsP.SubPacketRSSI;

components new TimerMilliC();
TelosbSensorsP.Timer -> TimerMilliC;

components LedsC;
TelosbSensorsP.Leds -> LedsC;

#ifndef TOSSIM 

components new SensirionSht11C();
TelosbSensorsP.ReadHumidity -> SensirionSht11C.Humidity;
TelosbSensorsP.ReadTemperature -> SensirionSht11C.Temperature;

components new HamamatsuS10871TsrC();
TelosbSensorsP.ReadLight -> HamamatsuS10871TsrC;

#else

/* Sensor Number 0 */
components new CapeInputC() as CapeHumidityC;
TelosbSensorsP.ReadHumidity -> CapeHumidityC.Read16;

/* Sensor Number 1 */
components new CapeInputC() as CapeTemperatureC;
TelosbSensorsP.ReadTemperature -> CapeTemperatureC.Read16;

/* Sensor Number 2 */
components new CapeInputC() as CapeLightC;
TelosbSensorsP.ReadLight -> CapeLightC.Read16;

#endif

}
