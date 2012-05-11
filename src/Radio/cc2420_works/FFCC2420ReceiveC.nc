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
 * Implementation of the receive path for the ChipCon FFCC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2009-08-14 20:33:43 $
 */

configuration FFCC2420ReceiveC {

  provides interface StdControl;
  provides interface CC2420Receive;
  provides interface Receive;
  provides interface ReceiveIndicator as PacketIndicator;

}

implementation {
  components MainC;
  components FFCC2420ReceiveP;
  components FFCC2420PacketC;
  components new CC2420SpiC() as Spi;
  
  components HplCC2420PinsC as Pins;
  components HplCC2420InterruptsC as InterruptsC;

  components LedsC as Leds;
  FFCC2420ReceiveP.Leds -> Leds;

  StdControl = FFCC2420ReceiveP;
  CC2420Receive = FFCC2420ReceiveP;
  Receive = FFCC2420ReceiveP;
  PacketIndicator = FFCC2420ReceiveP.PacketIndicator;

  MainC.SoftwareInit -> FFCC2420ReceiveP;
  
  FFCC2420ReceiveP.CSN -> Pins.CSN;
  FFCC2420ReceiveP.FIFO -> Pins.FIFO;
  FFCC2420ReceiveP.FIFOP -> Pins.FIFOP;
  FFCC2420ReceiveP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
  FFCC2420ReceiveP.SpiResource -> Spi;
  FFCC2420ReceiveP.RXFIFO -> Spi.RXFIFO;
  FFCC2420ReceiveP.SFLUSHRX -> Spi.SFLUSHRX;
  FFCC2420ReceiveP.SACK -> Spi.SACK;
  FFCC2420ReceiveP.CC2420Packet -> FFCC2420PacketC;
  FFCC2420ReceiveP.CC2420PacketBody -> FFCC2420PacketC;
  FFCC2420ReceiveP.PacketTimeStamp -> FFCC2420PacketC;

  FFCC2420ReceiveP.SECCTRL0 -> Spi.SECCTRL0;
  FFCC2420ReceiveP.SECCTRL1 -> Spi.SECCTRL1;
  FFCC2420ReceiveP.SRXDEC -> Spi.SRXDEC;
  FFCC2420ReceiveP.RXNONCE -> Spi.RXNONCE;
  FFCC2420ReceiveP.KEY0 -> Spi.KEY0;
  FFCC2420ReceiveP.KEY1 -> Spi.KEY1;
  FFCC2420ReceiveP.RXFIFO_RAM -> Spi.RXFIFO_RAM;
  FFCC2420ReceiveP.SNOP -> Spi.SNOP;

}
