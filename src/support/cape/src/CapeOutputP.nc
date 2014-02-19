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
  * Fennec Fox Cape Write Output
  *
  * @author: Marcin K Szczodrak
  * @last_update: 02/10/2014
  */

#include "sim_io.h"

module CapeOutputP {
provides interface Write<uint16_t> as Write16[uint8_t id];
provides interface Write<uint32_t> as Write32[uint8_t id];
}

implementation {

norace uint8_t writer_id;
norace uint16_t write16;
norace uint32_t write32;

task void do_write16() {
	sim_node_write_output(sim_node(), write16, writer_id);
	signal Write16.writeDone[writer_id](SUCCESS);
}

task void do_write32() {
	sim_node_write_output(sim_node(), write32, writer_id);
	signal Write32.writeDone[writer_id](SUCCESS);
}

command error_t Write16.write[uint8_t id](uint16_t val) {
	dbg("CapeOutput", "CapeOutput Write16.read[%u](%u)", id, val);
	writer_id = id;	
	write16 = val;
	post do_write16();
	return SUCCESS;
}

command error_t Write32.write[uint8_t id](uint32_t val) {
	dbg("CapeOutput", "CapeOutput Write32.read[%u](%u)", id, val);
	writer_id = id;	
	write32 = val;
	post do_write32();
	return SUCCESS;
}

default void event Write16.writeDone[uint8_t id](error_t error) {}
default void event Write32.writeDone[uint8_t id](error_t error) {}

}
