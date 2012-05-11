/*
 *  Blinking application for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2011 Marcin Szczodrak
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
 * Application: UWB CISL
 * Author: Marcin Szczodrak
 * Date: 10/1/2011
 * Last Modified: 1/2/2012
 */


generic configuration UWBCISL01RadioC() {
  provides interface Mgmt;
  provides interface Module;
  provides interface RadioCall;
  provides interface RadioSignal;
}

implementation {
  components new UWBCISL01RadioP();
  components CrcC;
  Mgmt = UWBCISL01RadioP;
  Module = UWBCISL01RadioP;
  RadioCall = UWBCISL01RadioP;
  RadioSignal = UWBCISL01RadioP;

  components HplAtm128GeneralIOC as GeneralIO;
  UWBCISL01RadioP.Crc  -> CrcC;
  UWBCISL01RadioP.PinF1-> GeneralIO.PortF1;

  components HplUWBCISL01P;
  Module = HplUWBCISL01P;
  UWBCISL01RadioP.EnhantsPHY -> HplUWBCISL01P;

  components HplAtm128Timer3C as Timer3; 
  components HplAtm128InterruptC as Interrupt;
  HplUWBCISL01P.CompareA	  -> Timer3.Compare[0];
  HplUWBCISL01P.TimerCtrl  -> Timer3.TimerCtrl;

  HplUWBCISL01P.PinClk1	  -> GeneralIO.PortE3;
  HplUWBCISL01P.PinTxData  -> GeneralIO.PortF5;
  HplUWBCISL01P.PinRfSwitch-> GeneralIO.PortA7;

  HplUWBCISL01P.PinC0 	  -> GeneralIO.PortC0;
  HplUWBCISL01P.PinC1 	  -> GeneralIO.PortC1;
  HplUWBCISL01P.PinC2 	  -> GeneralIO.PortC2;
  HplUWBCISL01P.PinC3 	  -> GeneralIO.PortC3;
  HplUWBCISL01P.PinC4 	  -> GeneralIO.PortC4;
  HplUWBCISL01P.PinC5 	  -> GeneralIO.PortC5;
  HplUWBCISL01P.PinC6 	  -> GeneralIO.PortC6;
  HplUWBCISL01P.PinC7 	  -> GeneralIO.PortC7;
  HplUWBCISL01P.PinF2 	  -> GeneralIO.PortF2;

  HplUWBCISL01P.Int0	  -> Interrupt.Int5;
  HplUWBCISL01P.Int1	  -> Interrupt.Int4;

  HplUWBCISL01P.Crc  		-> CrcC;
}
