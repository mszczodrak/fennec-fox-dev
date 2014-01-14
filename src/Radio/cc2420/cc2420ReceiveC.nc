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
 * Implementation of the receive path for the ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.4 $ $Date: 2009-08-14 20:33:43 $
 */

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
  * cc2420 driver adapted from the TinyOS ActiveMessage stack for CC2420 and cc2420x
  *
  * @author: Marcin K Szczodrak
  * @updated: 01/03/2014
  */


configuration cc2420ReceiveC {

provides interface StdControl;
provides interface CC2420Receive;
provides interface RadioReceive;
provides interface ReceiveIndicator as PacketIndicator;

uses interface RadioConfig;
uses interface RadioPacket;
uses interface PacketField<uint32_t> as PacketTimeSync;

}

implementation {
components MainC;
components cc2420ReceiveP;
components new CC2420SpiC() as Spi;
  
components HplCC2420PinsC as Pins;
components HplCC2420InterruptsC as InterruptsC;

components LedsC as Leds;
cc2420ReceiveP.Leds -> Leds;

StdControl = cc2420ReceiveP;
CC2420Receive = cc2420ReceiveP;
RadioReceive = cc2420ReceiveP;
PacketIndicator = cc2420ReceiveP.PacketIndicator;
RadioPacket = cc2420ReceiveP.RadioPacket;
PacketTimeSync = cc2420ReceiveP.PacketTimeSync;

MainC.SoftwareInit -> cc2420ReceiveP;
  
cc2420ReceiveP.CSN -> Pins.CSN;
cc2420ReceiveP.FIFO -> Pins.FIFO;
cc2420ReceiveP.FIFOP -> Pins.FIFOP;
cc2420ReceiveP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
cc2420ReceiveP.SpiResource -> Spi;
cc2420ReceiveP.RXFIFO -> Spi.RXFIFO;
cc2420ReceiveP.SFLUSHRX -> Spi.SFLUSHRX;
cc2420ReceiveP.SACK -> Spi.SACK;
RadioConfig = cc2420ReceiveP.RadioConfig;

cc2420ReceiveP.SECCTRL0 -> Spi.SECCTRL0;
cc2420ReceiveP.SECCTRL1 -> Spi.SECCTRL1;
cc2420ReceiveP.SRXDEC -> Spi.SRXDEC;
cc2420ReceiveP.RXNONCE -> Spi.RXNONCE;
cc2420ReceiveP.KEY0 -> Spi.KEY0;
cc2420ReceiveP.KEY1 -> Spi.KEY1;
cc2420ReceiveP.RXFIFO_RAM -> Spi.RXFIFO_RAM;
cc2420ReceiveP.SNOP -> Spi.SNOP;

}
