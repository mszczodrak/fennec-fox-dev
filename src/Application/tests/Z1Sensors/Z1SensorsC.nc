/*
 * Copyright (c) 2011, Columbia University.
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
  * Fennec Fox Z1 Sensors application driver
  *
  * @author: Marcin K Szczodrak
  * @updated: 03/02/2014
  */

#include "Z1SensorsAdc.h"

generic configuration Z1SensorsC() {
provides interface SplitControl;

uses interface Z1SensorsParams;

uses interface AMSend as NetworkAMSend;
uses interface Receive as NetworkReceive;
uses interface Receive as NetworkSnoop;
uses interface AMPacket as NetworkAMPacket;
uses interface Packet as NetworkPacket;
uses interface PacketAcknowledgements as NetworkPacketAcknowledgements;
}

implementation {
components new Z1SensorsP();
SplitControl = Z1SensorsP;

Z1SensorsParams = Z1SensorsP;

NetworkAMSend = Z1SensorsP.NetworkAMSend;
NetworkReceive = Z1SensorsP.NetworkReceive;
NetworkSnoop = Z1SensorsP.NetworkSnoop;
NetworkAMPacket = Z1SensorsP.NetworkAMPacket;
NetworkPacket = Z1SensorsP.NetworkPacket;
NetworkPacketAcknowledgements = Z1SensorsP.NetworkPacketAcknowledgements;

components SerialActiveMessageC;
components new SerialAMSenderC(100);
components new SerialAMReceiverC(100);
Z1SensorsP.SerialAMSend -> SerialAMSenderC.AMSend;
Z1SensorsP.SerialAMPacket -> SerialAMSenderC.AMPacket;
Z1SensorsP.SerialPacket -> SerialAMSenderC.Packet;
Z1SensorsP.SerialSplitControl -> SerialActiveMessageC.SplitControl;
Z1SensorsP.SerialReceive -> SerialAMReceiverC.Receive;

components new TimerMilliC();
Z1SensorsP.Timer -> TimerMilliC;

components LedsC;
Z1SensorsP.Leds -> LedsC;

#ifndef TOSSIM

components new SimpleTMP102C();
Z1SensorsP.ReadTemperature -> SimpleTMP102C;

components new BatteryC();
Z1SensorsP.ReadBattery -> BatteryC.Read;

components new ADXL345C();
Z1SensorsP.ReadXaxis -> ADXL345C.X;
Z1SensorsP.ReadYaxis -> ADXL345C.Y;
Z1SensorsP.ReadZaxis -> ADXL345C.Z;
Z1SensorsP.AccelSplitControl -> ADXL345C.SplitControl;

components new Msp430Adc12ClientC() as ReadAdc0;
Z1SensorsP.ReadAdc0 -> ReadAdc0;
Z1SensorsP.ResourceAdc0 -> ReadAdc0;

components new Msp430Adc12ClientC() as ReadAdc1;
Z1SensorsP.ReadAdc1 -> ReadAdc1;
Z1SensorsP.ResourceAdc1 -> ReadAdc1;

components new Msp430Adc12ClientC() as ReadAdc3;
Z1SensorsP.ReadAdc3 -> ReadAdc3;
Z1SensorsP.ResourceAdc3 -> ReadAdc3;

components new Msp430Adc12ClientC() as ReadAdc7;
Z1SensorsP.ReadAdc7 -> ReadAdc7;
Z1SensorsP.ResourceAdc7 -> ReadAdc7;

#else

components new CapeInputC() as CapeTemperatureC;
Z1SensorsP.ReadTemperature -> CapeTemperatureC.Read16;

components new CapeInputC() as CapeBetteryC;
Z1SensorsP.ReadBattery -> CapeBatteryC.Read16;

components new CapeInputC() as CapeAccelXC;
Z1SensorsP.ReadXaxis -> CapeAccelXC.Read16;

components new CapeInputC() as CapeAccelYC;
Z1SensorsP.ReadYaxis -> CapeAccelYC.Read16;

components new CapeInputC() as CapeAccelZC;
Z1SensorsP.ReadZaxis -> CapeAccelZC.Read16;

components new CapeInputC() as CapeAdc0C;
Z1SensorsP.ReadAdc0 -> CapeAdc0C.Read16;

components new CapeInputC() as CapeAdc1C;
Z1SensorsP.ReadAdc1 -> CapeAdc1C.Read16;

components new CapeInputC() as CapeAdc3C;
Z1SensorsP.ReadAdc3 -> CapeAdc3C.Read16;

components new CapeInputC() as CapeAdc7C;
Z1SensorsP.ReadAdc7 -> CapeAdc7C.Read16;

#endif

}
