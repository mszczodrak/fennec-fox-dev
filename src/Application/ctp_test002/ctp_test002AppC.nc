/*
 *  Dummy application module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
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
 * Network: Dummy Application Module
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */

#include "Ctp.h"

generic configuration ctp_test002AppC(uint16_t src, uint16_t dest) {
   provides interface Mgmt;
   provides interface Module;
   uses interface NetworkCall;
   uses interface NetworkSignal;
}

implementation {

  components new ctp_test002AppP(src, dest);
  Mgmt = ctp_test002AppP;
  Module = ctp_test002AppP;
  NetworkCall = ctp_test002AppP;
  NetworkSignal = ctp_test002AppP;

  components LedsC, ActiveMessageC;
  components DisseminationC;
  components new DisseminatorC(uint32_t, SAMPLE_RATE_KEY) as Object32C;
  components CollectionC as Collector;
  components new CollectionSenderC(CL_TEST);
  components new TimerMilliC();
  components RandomC;

  ctp_test002AppP.RadioControl -> ActiveMessageC;
  ctp_test002AppP.RoutingControl -> Collector;
  ctp_test002AppP.DisseminationControl -> DisseminationC;
  ctp_test002AppP.Leds -> LedsC;
  ctp_test002AppP.Timer -> TimerMilliC;
  ctp_test002AppP.DisseminationPeriod -> Object32C;
  ctp_test002AppP.Send -> CollectionSenderC;
  ctp_test002AppP.RootControl -> Collector;
  ctp_test002AppP.Receive -> Collector.Receive[CL_TEST];
  ctp_test002AppP.CollectionPacket -> Collector;
  ctp_test002AppP.CtpInfo -> Collector;
  ctp_test002AppP.CtpCongestion -> Collector;
  ctp_test002AppP.Random -> RandomC;
  ctp_test002AppP.RadioPacket -> ActiveMessageC;
  ctp_test002AppP.LowPowerListening -> ActiveMessageC;
  ctp_test002AppP.AMPacket -> ActiveMessageC;
}
