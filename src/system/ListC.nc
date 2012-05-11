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

generic module ListC(typedef list_t, uint8_t LIST_SIZE) {
  provides interface List<list_t>;
}

implementation {

  list_t ONE_NOK list[LIST_SIZE];
  uint8_t head = 0;
  uint8_t tail = 0;
  uint8_t size = 0;
  
  command bool List.empty() {
    return size == 0;
  }

  command uint8_t List.size() {
    return size;
  }

  command uint8_t List.maxSize() {
    return LIST_SIZE;
  }

  command list_t List.head() {
    return list[head];
  }

  command list_t List.pop() {
    list_t t = call List.head();
    if (!call List.empty()) {
      head++;
      if (head == LIST_SIZE) head = 0;
      size--;
    }
    return t;
  }

  command error_t List.append(list_t newVal) {
    if (call List.size() < call List.maxSize()) {
      list[tail] = newVal;
      tail++;
      if (tail == LIST_SIZE) tail = 0;
      size++;
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  command error_t List.push(list_t newVal) {
    if (call List.size() < call List.maxSize()) {
      if (head == 0) {
        head = LIST_SIZE - 1;
      } else {
        head--;
      }
      list[head] = newVal;
      size++;
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }
  
  command list_t List.element(uint8_t idx) {
    idx += head;
    if (idx >= LIST_SIZE) {
      idx -= LIST_SIZE;
    }
    return list[idx];
  }  

}
