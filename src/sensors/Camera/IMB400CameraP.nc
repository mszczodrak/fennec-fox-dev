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

#include <Fennec.h>
#include <ov7670.h>
#include "Camera.h"

module IMB400CameraP {
  provides interface Camera;

  uses interface HplPXA27XQuickCaptInt as CIF;
  uses interface HplOV7670 as OV;
}

implementation {

  norace frame_t* currframe;

  command error_t Camera.capture(uint8_t* buffer, uint8_t color, uint8_t vga) {

    currframe = (frame_t*) buffer;

    currframe->size   = QVGA_HEIGHT * QVGA_WIDTH * 2; // 2 bytes per pixel
    currframe->header = (frame_header_t*) (buffer + sizeof(frame_t));
    currframe->buf    = (uint8_t*) (buffer + sizeof(frame_t) + sizeof(frame_header_t));

    call OV.config_window(SIZE_QVGA);
    call OV.init(color, 1, SIZE_QVGA);

    currframe->header->height     = QVGA_HEIGHT;
    currframe->header->width      = QVGA_WIDTH;
    currframe->header->color      = 0;
    currframe->header->size       = QVGA_WIDTH * QVGA_HEIGHT * 2;
    currframe->header->time_stamp = 0;
    currframe->header->type = 0;

    call CIF.init(color);
    call CIF.setImageSize(QVGA_WIDTH, QVGA_HEIGHT, (call OV.get_config())->color);
    call CIF.initDMA(currframe->size, currframe->buf);
    call CIF.enable();

    return SUCCESS;
  }

  task void startOfFrame() {
    ov_stat_t *stat = call OV.get_config();
    frame_header_t *header = currframe->header;
  
    header->height     = QVGA_HEIGHT;
    header->width      = QVGA_WIDTH;
    
    header->color      = stat->color;
    header->size       = header->width * 2 * header->height;
    header->time_stamp = RCNR;
  
    call CIF.initDMA(header->size, currframe->buf);
    CIFR |= CIFR_RESETF;
    call CIF.startDMA();
  }

  async event void CIF.startOfFrame() {
    post startOfFrame();
  }

  task void captureDone() {
    uint32_t i;
    call CIF.disableQuick();

    for (i = 0; i < currframe->header->size / 2; i++) {
      currframe->buf[i] = currframe->buf[2 * i + 1];
    }
    currframe->header->size  = currframe->header->size / 2;

    signal Camera.captureDone(currframe->buf, currframe->header->size);
  }

  async event void CIF.endOfFrame() {
    post captureDone();
  }

  async event void CIF.endOfLine(){}

  async event void CIF.recvDataAvailable(uint8_t channel){}

  async event void CIF.fifoOverrun(uint8_t channel){}

}
