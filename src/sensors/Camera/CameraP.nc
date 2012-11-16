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

module CameraP {
  provides interface Camera;

#ifdef _H_IMB400_CAMERA_H
  uses interface Camera as IMBCam;
#else
  uses interface Camera as VirtualCam;
#endif

}

implementation {

  command error_t Camera.capture(uint8_t *buffer, uint8_t color, uint8_t vga) {
#ifdef _H_IMB400_CAMERA_H
    return call IMBCam.capture(buffer, color, vga);
#else
    return call VirtualCam.capture(buffer, color, vga);
#endif
  }

#ifdef _H_IMB400_CAMERA_H
  event void IMBCam.captureDone(uint8_t *buffer, uint32_t size) {
    signal Camera.captureDone(buffer, size);
  }
#else
  event void VirtualCam.captureDone(uint8_t *buffer, uint32_t size) {
    signal Camera.captureDone(buffer, size);
  }
#endif
}
