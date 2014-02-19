/*
 * Copyright (c) 2014, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox Cape Read Input
  *
  * @author: Marcin K Szczodrak
  * @last_update: 02/10/2014
  */

#include "sim_io.h"

module CapeInputP {
provides interface Read<uint16_t> as Read16[uint8_t id];
provides interface Read<uint32_t> as Read32[uint8_t id];
}

implementation {

norace uint8_t reader_id;
norace uint16_t read16;
norace uint32_t read32;

task void do_read16() {
	read16 = sim_node_read_input(sim_node(), reader_id);
	signal Read16.readDone[reader_id](SUCCESS, read16);
}

task void do_read32() {
	read32 = sim_node_read_input(sim_node(), reader_id);
	signal Read32.readDone[reader_id](SUCCESS, read32);
}

command error_t Read16.read[uint8_t id]() {
	dbg("CapeInput", "CapeInput Read16.read[%u]()", id);
	reader_id = id;	
	post do_read16();
	return SUCCESS;
}

command error_t Read32.read[uint8_t id]() {
	dbg("CapeInput", "CapeInput Read32.read[%u]()", id);
	reader_id = id;	
	post do_read32();
	return SUCCESS;
}

default void event Read16.readDone[uint8_t id](error_t error, uint16_t val) {}
default void event Read32.readDone[uint8_t id](error_t error, uint32_t val) {}

}
