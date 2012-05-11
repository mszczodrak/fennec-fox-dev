/*
 *  simpleCC2420 radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Application: Radio Module for CC2420
 * Author: Marcin Szczodrak
 * Date: 9/29/2009
 * Last Modified: 2/9/2012
 */

generic configuration simpleCC2420RadioC(uint8_t radio_channel, /* Channels are 11-26 */
			uint8_t tx_power, /* Power is: Max 31, 27, 23, 19, 15, 11, 7, 3 Min */
			bool enable_auto_crc) {

  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;
}

implementation {

#ifndef CAPEFOX
  components new simpleCC2420RadioP(radio_channel, tx_power, enable_auto_crc);
  Mgmt = simpleCC2420RadioP;
  Module = simpleCC2420RadioP;
  RadioCall = simpleCC2420RadioP;
  RadioSignal = simpleCC2420RadioP;

  components AlarmMultiplexC as Alarm;
  simpleCC2420RadioP.StartupTimer -> Alarm;

  components HplCC2420InterruptsC as InterruptsC;
  simpleCC2420RadioP.InterruptFIFOP -> InterruptsC.InterruptFIFOP;
  simpleCC2420RadioP.CaptureSFD -> InterruptsC.CaptureSFD;
  simpleCC2420RadioP.InterruptCCA -> InterruptsC.InterruptCCA;

  components HplCC2420PinsC as Pins;
  simpleCC2420RadioP.CSN 			-> Pins.CSN;
  simpleCC2420RadioP.CCA 			-> Pins.CCA;
  simpleCC2420RadioP.SFD 			-> Pins.SFD;
  simpleCC2420RadioP.RSTN 			-> Pins.RSTN;
  simpleCC2420RadioP.VREN			-> Pins.VREN;
  simpleCC2420RadioP.FIFO 			-> Pins.FIFO;
  simpleCC2420RadioP.FIFOP 		-> Pins.FIFOP;

  components new CC2420SpiC() as Spi;
  simpleCC2420RadioP.SpiResource 		-> Spi;
  simpleCC2420RadioP.RXFIFO 		-> Spi.RXFIFO;
  simpleCC2420RadioP.SFLUSHRX 		-> Spi.SFLUSHRX;
  simpleCC2420RadioP.SFLUSHTX 		-> Spi.SFLUSHTX;

  simpleCC2420RadioP.SACK 			-> Spi.SACK;

  simpleCC2420RadioP.SECCTRL0 		-> Spi.SECCTRL0;
  simpleCC2420RadioP.SECCTRL1 		-> Spi.SECCTRL1;
  simpleCC2420RadioP.SRXDEC 		-> Spi.SRXDEC;
  simpleCC2420RadioP.RXNONCE 		-> Spi.RXNONCE;
  simpleCC2420RadioP.KEY0 			-> Spi.KEY0;
  simpleCC2420RadioP.KEY1 			-> Spi.KEY1;
  simpleCC2420RadioP.RXFIFO_RAM 		-> Spi.RXFIFO_RAM;
  simpleCC2420RadioP.SNOP 			-> Spi.SNOP;

  simpleCC2420RadioP.STXON       		-> Spi.STXON;
  simpleCC2420RadioP.TXCTRL      		-> Spi.TXCTRL;
  simpleCC2420RadioP.TXFIFO      		-> Spi.TXFIFO;

  simpleCC2420RadioP.SRXON       		-> Spi.SRXON;
  simpleCC2420RadioP.SRFOFF       		-> Spi.SRFOFF;
  simpleCC2420RadioP.SXOSCON      		-> Spi.SXOSCON;
  simpleCC2420RadioP.SXOSCOFF     		-> Spi.SXOSCOFF;
  simpleCC2420RadioP.FSCTRL 		-> Spi.FSCTRL;
  simpleCC2420RadioP.IOCFG0 		-> Spi.IOCFG0;
  simpleCC2420RadioP.IOCFG1 		-> Spi.IOCFG1;
  simpleCC2420RadioP.MDMCTRL0 		-> Spi.MDMCTRL0;
  simpleCC2420RadioP.MDMCTRL1 		-> Spi.MDMCTRL1;
  simpleCC2420RadioP.RXCTRL1 		-> Spi.RXCTRL1;
  simpleCC2420RadioP.RSSI  		-> Spi.RSSI;

#else
  components new capeRadioC();
  Mgmt = capeRadioC;
  Module = capeRadioC;
  RadioCall = capeRadioC;
  RadioSignal = capeRadioC;

  components IEEE802154ModelC;
  capeRadioC.RadioModel -> IEEE802154ModelC;
  capeRadioC.MgmtModel -> IEEE802154ModelC;
#endif

}

