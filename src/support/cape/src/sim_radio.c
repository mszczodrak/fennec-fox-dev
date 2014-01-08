/*
 * Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 *
 * C implementation of configuration parameters for a CSMA link.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

// $Id: sim_radio.c,v 1.5 2010-06-29 22:07:51 scipio Exp $

#include <sim_radio.h>

int radioInitHigh = SIM_CSMA_INIT_HIGH;
int radioInitLow = SIM_CSMA_INIT_LOW;
int radioHigh = SIM_CSMA_HIGH;
int radioLow = SIM_CSMA_LOW;
int radioSymbolsPerSec = SIM_CSMA_SYMBOLS_PER_SEC;
int radioBitsPerSymbol = SIM_CSMA_BITS_PER_SYMBOL;
int radioPreambleLength = SIM_CSMA_PREAMBLE_LENGTH;
int radioExponentBase = SIM_CSMA_EXPONENT_BASE;
int radioMinFreeSamples = SIM_CSMA_MIN_FREE_SAMPLES;
int radioRxTxDelay = SIM_CSMA_RXTX_DELAY;
int radioAckTime = SIM_CSMA_ACK_TIME;

int sim_radio_init_high() __attribute__ ((C, spontaneous)) {
  return radioInitHigh;
}
int sim_radio_init_low() __attribute__ ((C, spontaneous)) {
  return radioInitLow;
}
int sim_radio_high() __attribute__ ((C, spontaneous)) {
  return radioHigh;
}
int sim_radio_low() __attribute__ ((C, spontaneous)) {
  return radioLow;
}
int sim_radio_symbols_per_sec() __attribute__ ((C, spontaneous)) {
  return radioSymbolsPerSec;
}
int sim_radio_bits_per_symbol() __attribute__ ((C, spontaneous)) {
  return radioBitsPerSymbol;
}
int sim_radio_preamble_length() __attribute__ ((C, spontaneous)) {
  return radioPreambleLength;
}
int sim_radio_exponent_base() __attribute__ ((C, spontaneous)) {
  return radioExponentBase;;
}
int sim_radio_min_free_samples() __attribute__ ((C, spontaneous)) {
  return radioMinFreeSamples;
}
int sim_radio_rxtx_delay() __attribute__ ((C, spontaneous)) {
  return radioRxTxDelay;
}
int sim_radio_ack_time() __attribute__ ((C, spontaneous)) {
  return radioAckTime;
}



void sim_radio_set_init_high(int val) __attribute__ ((C, spontaneous)) {
  radioInitHigh = val;
}
void sim_radio_set_init_low(int val) __attribute__ ((C, spontaneous)) {
  radioInitLow = val;
}
void sim_radio_set_high(int val) __attribute__ ((C, spontaneous)) {
  radioHigh = val;
}
void sim_radio_set_low(int val) __attribute__ ((C, spontaneous)) {
  radioLow = val;
}
void sim_radio_set_symbols_per_sec(int val) __attribute__ ((C, spontaneous)) {
  radioSymbolsPerSec = val;
}
void sim_radio_set_bits_per_symbol(int val) __attribute__ ((C, spontaneous)) {
  radioBitsPerSymbol = val;
}
void sim_radio_set_preamble_length(int val) __attribute__ ((C, spontaneous)) {
  radioPreambleLength = val;
}
void sim_radio_set_exponent_base(int val) __attribute__ ((C, spontaneous)) {
  radioExponentBase = val;
}
void sim_radio_set_min_free_samples(int val) __attribute__ ((C, spontaneous)) {
  radioMinFreeSamples = val;
}
void sim_radio_set_rxtx_delay(int val) __attribute__ ((C, spontaneous)) {
  radioRxTxDelay = val;
}
void sim_radio_set_ack_time(int val) __attribute__ ((C, spontaneous)) {
  radioAckTime = val;
}

