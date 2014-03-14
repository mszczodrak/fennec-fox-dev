/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Janos Sallai, Miklos Maroti
 */

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
  * @updated: 01/12/2014
  */

#include <RadioConfig.h>
#include <CC2420XDriverLayer.h>

configuration CC2420XDriverLayerC {
provides interface RadioState;
provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;
provides interface cc2420XDriverParams;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint32_t> as PacketTimeSync;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LinkPacketMetadata;

provides interface LocalTime<TRadio> as LocalTimeRadio;
provides interface Alarm<TRadio, tradio_size>;

uses interface RadioAlarm;
}

implementation {

components CC2420XDriverLayerP as DriverLayerP,
	BusyWaitMicroC,
	MainC,
	HplCC2420XC as HplC;

MainC.SoftwareInit -> DriverLayerP.SoftwareInit;
MainC.SoftwareInit -> HplC.Init;

RadioState = DriverLayerP;
RadioSend = DriverLayerP;
RadioReceive = DriverLayerP;
RadioCCA = DriverLayerP;
RadioPacket = DriverLayerP;

LocalTimeRadio = HplC;

cc2420XDriverParams = DriverLayerP;

DriverLayerP.VREN -> HplC.VREN;
DriverLayerP.CSN -> HplC.CSN;
DriverLayerP.CCA -> HplC.CCA;
DriverLayerP.RSTN -> HplC.RSTN;
DriverLayerP.FIFO -> HplC.FIFO;
DriverLayerP.FIFOP -> HplC.FIFOP;
DriverLayerP.SFD -> HplC.SFD;

PacketTransmitPower = DriverLayerP.PacketTransmitPower;

PacketRSSI = DriverLayerP.PacketRSSI;

PacketTimeSync = DriverLayerP.PacketTimeSync;

PacketLinkQuality = DriverLayerP.PacketLinkQuality;
LinkPacketMetadata = DriverLayerP;

Alarm = HplC.Alarm;
RadioAlarm = DriverLayerP.RadioAlarm;

DriverLayerP.SpiResource -> HplC.SpiResource;
DriverLayerP.FastSpiByte -> HplC;

DriverLayerP.SfdCapture -> HplC;
DriverLayerP.FifopInterrupt -> HplC;

DriverLayerP.BusyWait -> BusyWaitMicroC;

DriverLayerP.LocalTime-> HplC.LocalTimeRadio;

components LedsC;
DriverLayerP.Leds -> LedsC;
}
