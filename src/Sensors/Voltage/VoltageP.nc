/*
 * Copyright (c) 2009 Columbia University.
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
 * - Neither the name of the Columbia University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL COLUMBIA
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * author: Marcin Szczodrak
 * date: 7/26/2010
 */

#include <Fennec.h>

module VoltageP {
  provides interface Read<uint16_t>;

#ifdef _H_msp430hardware_h
  uses interface Read<uint16_t> as MSPBattery;
#else
  #ifdef PXA27X_HARDWARE_H
    uses interface PMIC;
  #else
    uses interface Read<uint16_t> as VirtualBattery;
  #endif
#endif
}

implementation {

#ifdef PXA27X_HARDWARE_H
  task void readPMIC() {
    error_t error;
    uint8_t v;
    double value;
    atomic {
      error = call PMIC.getBatteryVoltage(&v);
    }
    // Conversion from ADC reading to voltage
    value = (((2.65 * v ) / 256.0) + 2.65 )*1000;
    signal Read.readDone(error, value);
  }
#endif

  command error_t Read.read() {
#ifdef _H_msp430hardware_h
    return call MSPBattery.read();
#else
  #ifdef PXA27X_HARDWARE_H
    post readPMIC();
    return SUCCESS;
  #else
    return call VirtualBattery.read();
  #endif
#endif

    return FAIL;
  }

#ifdef _H_msp430hardware_h
  event void MSPBattery.readDone( error_t result, uint16_t val ) {
    if (result == SUCCESS) {
      double v = ( val / 4096.0) * 3000;
      signal Read.readDone(result, v);
    } else {
      signal Read.readDone(result, val);
    }
  }
#else
  #ifdef PXA27X_HARDWARE_H

  #else

    event void VirtualBattery.readDone( error_t result, uint16_t val) {
      signal Read.readDone(result, val);
    }

  #endif
#endif

}
