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

configuration cc2420TransmitC {

  provides interface Receive;

  provides {
    interface StdControl;
    interface RadioTransmit;
    interface RadioBackoff;
    interface ReceiveIndicator as ByteIndicator;
  }

  uses interface cc2420RadioParams;
  uses interface Receive as SubReceive;
  uses interface ReceiveIndicator as EnergyIndicator;
}

implementation {

  components cc2420TransmitP;
  StdControl = cc2420TransmitP;
  RadioTransmit = cc2420TransmitP;
  RadioBackoff = cc2420TransmitP;
  EnergyIndicator = cc2420TransmitP.EnergyIndicator;
  ByteIndicator = cc2420TransmitP.ByteIndicator;

  cc2420RadioParams = cc2420TransmitP.cc2420RadioParams;

  components AlarmMultiplexC as Alarm;
  cc2420TransmitP.BackoffTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  cc2420TransmitP.CSN -> Pins.CSN;
  cc2420TransmitP.SFD -> Pins.SFD;

  components HplCC2420InterruptsC as Interrupts;
  cc2420TransmitP.CaptureSFD -> Interrupts.CaptureSFD;

  components new CC2420SpiC() as Spi;
  cc2420TransmitP.SpiResource -> Spi;
  cc2420TransmitP.ChipSpiResource -> Spi;
  cc2420TransmitP.SNOP        -> Spi.SNOP;
  cc2420TransmitP.STXON       -> Spi.STXON;
  cc2420TransmitP.STXONCCA    -> Spi.STXONCCA;
  cc2420TransmitP.SFLUSHTX    -> Spi.SFLUSHTX;
  cc2420TransmitP.TXCTRL      -> Spi.TXCTRL;
  cc2420TransmitP.TXFIFO      -> Spi.TXFIFO;
  cc2420TransmitP.TXFIFO_RAM  -> Spi.TXFIFO_RAM;
  cc2420TransmitP.MDMCTRL1    -> Spi.MDMCTRL1;
  cc2420TransmitP.SECCTRL0 -> Spi.SECCTRL0;
  cc2420TransmitP.SECCTRL1 -> Spi.SECCTRL1;
  cc2420TransmitP.STXENC -> Spi.STXENC;
  cc2420TransmitP.TXNONCE -> Spi.TXNONCE;
  cc2420TransmitP.KEY0 -> Spi.KEY0;
  cc2420TransmitP.KEY1 -> Spi.KEY1;
  
  components cc2420ReceiveC;
  cc2420TransmitP.CC2420Receive -> cc2420ReceiveC;
  
  components LedsC;
  cc2420TransmitP.Leds -> LedsC;

  Receive = cc2420TransmitP.Receive;
  SubReceive = cc2420TransmitP.SubReceive;

}
