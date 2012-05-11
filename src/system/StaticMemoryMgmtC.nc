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
 * date: 12/8/2009
 */

generic module StaticMemoryMgmtC(typedef mem_t, uint8_t size) @safe() {
  provides interface Memory<mem_t>;
}

implementation {

  uint8_t left = size;
  mem_t* ONE_NOK mem[size];
  mem_t ONE_NOK space[size];

  command bool Memory.empty() {
    return left == 0;
  }
  command uint8_t Memory.size() {
    return left;
  }
    
  command uint8_t Memory.maxSize() {
    return size;
  }

  command mem_t* Memory.get() {
    dbg("Memory", "System Memory Msg pool get: size left is %d\n", left);
    atomic {
      if (left) {
        uint8_t i;
        for (i = 0; i < size; i++) {
          if( mem[i] == NULL) {
            mem[i] = space + i;
            left--;
            dbg("Memory", "System Memory Msg pool get SUCCESS: size left is %d\n", left);
	    if (left == 0) dbgs(F_MEMORY, S_NONE, DBGS_MEMORY_EMPTY, 0, 0);
            memset(mem[i], 0, sizeof(mem_t));
            return mem[i];          
          }
       }      
      }
    }
    dbg("Memory", "System Memory Msg pool get FAIL: size left is %d\n", left);
    return NULL;
  }

  command error_t Memory.put(mem_t* newVal) {
    uint8_t i;
    dbg("Memory", "System Memory Msg pool put: size left is %d\n", left);

    if (newVal == NULL) {
      dbg("Memory", "System Memory Msg pool put: got NULL size %d\n", left);
      return FAIL;
    }

    atomic {
      for (i = 0; i < size; i++) {
        if ( mem[i] == newVal) {
          mem[i] = NULL;
          left++;
          dbg("Memory", "System Memory Msg pool put SUCCESS: size left is %d\n", left);
          return SUCCESS;
        }
      }
      dbg("Memory", "System Memory Msg pool put FAIL: size left is %d\n", left);
      return FAIL;
    }
  }

  command void Memory.reset() {
    atomic {
      uint16_t i;
      for(i = 0; i < size; i++) {
        mem[i] = NULL;
      }
      left = size;
    }
  }
}
