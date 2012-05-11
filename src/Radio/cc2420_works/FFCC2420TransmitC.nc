/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Implementation of the transmit path for the ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2009-08-14 20:33:43 $
 */

#include "IEEE802154.h"

generic configuration FFCC2420TransmitC(uint8_t channel, uint8_t power) {

  provides {
    interface StdControl;
    interface CC2420Transmit;
    interface RadioBackoff;
    interface ReceiveIndicator as EnergyIndicator;
    interface ReceiveIndicator as ByteIndicator;
  }
}

implementation {

  components new FFCC2420TransmitP(channel, power);
  StdControl = FFCC2420TransmitP;
  CC2420Transmit = FFCC2420TransmitP;
  RadioBackoff = FFCC2420TransmitP;
  EnergyIndicator = FFCC2420TransmitP.EnergyIndicator;
  ByteIndicator = FFCC2420TransmitP.ByteIndicator;

  components MainC;
  MainC.SoftwareInit -> FFCC2420TransmitP;
  MainC.SoftwareInit -> Alarm;
  
  components AlarmMultiplexC as Alarm;
  FFCC2420TransmitP.BackoffTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  FFCC2420TransmitP.CCA -> Pins.CCA;
  FFCC2420TransmitP.CSN -> Pins.CSN;
  FFCC2420TransmitP.SFD -> Pins.SFD;

  components HplCC2420InterruptsC as Interrupts;
  FFCC2420TransmitP.CaptureSFD -> Interrupts.CaptureSFD;

  components new CC2420SpiC() as Spi;
  FFCC2420TransmitP.SpiResource -> Spi;
  FFCC2420TransmitP.ChipSpiResource -> Spi;
  FFCC2420TransmitP.SNOP        -> Spi.SNOP;
  FFCC2420TransmitP.STXON       -> Spi.STXON;
  FFCC2420TransmitP.STXONCCA    -> Spi.STXONCCA;
  FFCC2420TransmitP.SFLUSHTX    -> Spi.SFLUSHTX;
  FFCC2420TransmitP.TXCTRL      -> Spi.TXCTRL;
  FFCC2420TransmitP.TXFIFO      -> Spi.TXFIFO;
  FFCC2420TransmitP.TXFIFO_RAM  -> Spi.TXFIFO_RAM;
  FFCC2420TransmitP.MDMCTRL1    -> Spi.MDMCTRL1;
  FFCC2420TransmitP.SECCTRL0 -> Spi.SECCTRL0;
  FFCC2420TransmitP.SECCTRL1 -> Spi.SECCTRL1;
  FFCC2420TransmitP.STXENC -> Spi.STXENC;
  FFCC2420TransmitP.TXNONCE -> Spi.TXNONCE;
  FFCC2420TransmitP.KEY0 -> Spi.KEY0;
  FFCC2420TransmitP.KEY1 -> Spi.KEY1;
  
  components FFCC2420ReceiveC;
  FFCC2420TransmitP.CC2420Receive -> FFCC2420ReceiveC;
  
  components FFCC2420PacketC;
  FFCC2420TransmitP.CC2420Packet -> FFCC2420PacketC;
  FFCC2420TransmitP.CC2420PacketBody -> FFCC2420PacketC;
  FFCC2420TransmitP.PacketTimeStamp -> FFCC2420PacketC;
  FFCC2420TransmitP.PacketTimeSyncOffset -> FFCC2420PacketC;

  components LedsC;
  FFCC2420TransmitP.Leds -> LedsC;

}
