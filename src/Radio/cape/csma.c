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
 * C++ implementation of the default TOSSIM CSMA model.
 *
 * @author Philip Levis
 * @date   Dec 10 2005
 */

#include <radio.h>

Csma::Csma() {}
Csma::~Csma() {}

int Csma::initHigh() {return sim_radio_init_high();}
int Csma::initLow() {return sim_radio_init_low();}
int Csma::high() {return sim_radio_high();}
int Csma::low() {return sim_radio_low();}
int Csma::symbolsPerSec() {return sim_radio_symbols_per_sec();}
int Csma::bitsPerSymbol() {return sim_radio_bits_per_symbol();}
int Csma::preambleLength() {return sim_radio_preamble_length();}
int Csma::exponentBase() {return sim_radio_exponent_base();}
int Csma::minFreeSamples() {return sim_radio_min_free_samples();}
int Csma::rxtxDelay() {return sim_radio_rxtx_delay();}
int Csma::ackTime() {return sim_radio_ack_time();}

void Csma::setInitHigh(int val) {sim_radio_set_init_high(val);}
void Csma::setInitLow(int val) {sim_radio_set_init_low(val);}
void Csma::setHigh(int val) {sim_radio_set_high(val);}
void Csma::setLow(int val) {sim_radio_set_low(val);}
void Csma::setSymbolsPerSec(int val) {sim_radio_set_symbols_per_sec(val);}
void Csma::setBitsBerSymbol(int val) {sim_radio_set_bits_per_symbol(val);}
void Csma::setPreambleLength(int val) {sim_radio_set_preamble_length(val);}
void Csma::setExponentBase(int val) {sim_radio_set_exponent_base(val);}
void Csma::setMinFreeSamples(int val) {sim_radio_set_min_free_samples(val);}
void Csma::setRxtxDelay(int val) {sim_radio_set_rxtx_delay(val);}
void Csma::setAckTime(int val); {sim_radio_set_ack_time(val);}

#endif
