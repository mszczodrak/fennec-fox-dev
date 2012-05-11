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
 * Implementation for configuring a ChipCon CC2420 radio.
 *
 * @author Jonathan Hui <jhui@archrock.com>
 * @version $Revision: 1.3 $ $Date: 2008/05/14 21:33:07 $
 */

#include "FFCC2420.h"
#include "IEEE802154.h"

generic configuration FFCC2420ControlC(uint8_t channel, uint8_t power) {

  provides interface Resource;
  provides interface CC2420Config;
  provides interface CC2420Power;
  provides interface Read<uint16_t> as ReadRssi;
  
}

implementation {
  
  components new FFCC2420ControlP(channel, power);
  Resource = FFCC2420ControlP;
  CC2420Config = FFCC2420ControlP;
  CC2420Power = FFCC2420ControlP;
  ReadRssi = FFCC2420ControlP;

  components MainC;
  MainC.SoftwareInit -> FFCC2420ControlP;
  
  components AlarmMultiplexC as Alarm;
  FFCC2420ControlP.StartupTimer -> Alarm;

  components HplCC2420PinsC as Pins;
  FFCC2420ControlP.CSN -> Pins.CSN;
  FFCC2420ControlP.RSTN -> Pins.RSTN;
  FFCC2420ControlP.VREN -> Pins.VREN;

  components HplCC2420InterruptsC as Interrupts;
  FFCC2420ControlP.InterruptCCA -> Interrupts.InterruptCCA;

  components new CC2420SpiC() as Spi;
  FFCC2420ControlP.SpiResource -> Spi;
  FFCC2420ControlP.SRXON -> Spi.SRXON;
  FFCC2420ControlP.SRFOFF -> Spi.SRFOFF;
  FFCC2420ControlP.SXOSCON -> Spi.SXOSCON;
  FFCC2420ControlP.SXOSCOFF -> Spi.SXOSCOFF;
  FFCC2420ControlP.FSCTRL -> Spi.FSCTRL;
  FFCC2420ControlP.IOCFG0 -> Spi.IOCFG0;
  FFCC2420ControlP.IOCFG1 -> Spi.IOCFG1;
  FFCC2420ControlP.MDMCTRL0 -> Spi.MDMCTRL0;
  FFCC2420ControlP.MDMCTRL1 -> Spi.MDMCTRL1;
  FFCC2420ControlP.PANID -> Spi.PANID;
  FFCC2420ControlP.IEEEADR -> Spi.IEEEADR;
  FFCC2420ControlP.RXCTRL1 -> Spi.RXCTRL1;
  FFCC2420ControlP.RSSI  -> Spi.RSSI;
  FFCC2420ControlP.TXCTRL  -> Spi.TXCTRL;

  components new CC2420SpiC() as SyncSpiC;
  FFCC2420ControlP.SyncResource -> SyncSpiC;

  components new CC2420SpiC() as RssiResource;
  FFCC2420ControlP.RssiResource -> RssiResource;
  
  components ActiveMessageAddressC;
  FFCC2420ControlP.ActiveMessageAddress -> ActiveMessageAddressC;

  components LocalIeeeEui64C;
  FFCC2420ControlP.LocalIeeeEui64 -> LocalIeeeEui64C;

}

