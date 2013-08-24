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
 * C++ implementation of the gain-based TOSSIM radio model.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

#include <radio.h>
#include <sim_gain.h>
#include <sim_radio.h>

Radio::Radio() {}
Radio::~Radio() {}

void Radio::add(int src, int dest, double gain) {
  sim_gain_add(src, dest, gain);
}

double Radio::gain(int src, int dest) {
  return sim_gain_value(src, dest);
}

bool Radio::connected(int src, int dest) {
  return sim_gain_connected(src, dest);
}

void Radio::remove(int src, int dest) {
  sim_gain_remove(src, dest);
}

void Radio::setNoise(int node, double mean, double range) {
  sim_gain_set_noise_floor(node, mean, range);
}


void Radio::setSensitivity(double sensitivity) {
  sim_gain_set_sensitivity(sensitivity);
}








int Radio::symbolsPerSec() {return sim_radio_symbols_per_sec();}
int Radio::bitsPerSymbol() {return sim_radio_bits_per_symbol();}
int Radio::preambleLength() {return sim_radio_preamble_length();}
int Radio::rxtxDelay() {return sim_radio_rxtx_delay();}
int Radio::ackTime() {return sim_radio_ack_time();}


void Radio::setSymbolsPerSec(int val) {sim_radio_set_symbols_per_sec(val);}
void Radio::setBitsBerSymbol(int val) {sim_radio_set_bits_per_symbol(val);}
void Radio::setPreambleLength(int val) {sim_radio_set_preamble_length(val);}
void Radio::setRxtxDelay(int val) {sim_radio_set_rxtx_delay(val);}
void Radio::setAckTime(int val) {
  sim_radio_set_ack_time(val);
}



