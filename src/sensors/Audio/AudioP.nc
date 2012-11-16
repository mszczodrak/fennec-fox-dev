/*
 * Copyright (c) 2009-2010 Columbia University.
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
 * date: 7/27/2010
 */

module AudioP {
  provides interface Audio;

#ifdef _H_IMB400_AUDIO_H
  uses interface Audio as IMBAudio;
#else
  uses interface Audio as VirtualAudio;
#endif
}

implementation {

  command uint16_t Audio.readSample() {
#ifdef _H_IMB400_AUDIO_H
    return call IMBAudio.readSample();  
#else 
    return call VirtualAudio.readSample();  
#endif
  }

  command void Audio.writeSample( uint16_t sample ) {
#ifdef _H_IMB400_AUDIO_H
    call IMBAudio.writeSample( sample );
#else
    call VirtualAudio.writeSample( sample );
#endif
  }

  command void Audio.setVolume( uint8_t volume ) {
#ifdef _H_IMB400_AUDIO_H
    return call IMBAudio.setVolume( volume );
#else
    return call VirtualAudio.setVolume( volume );
#endif
  }

  command void Audio.playStream( uint32_t *data, uint32_t length ) {
#ifdef _H_IMB400_AUDIO_H
    return call IMBAudio.playStream( data, length );
#else
    return call VirtualAudio.playStream( data, length );
#endif
  }


  command void Audio.readStream( uint32_t *data, uint32_t length ) {
#ifdef _H_IMB400_AUDIO_H
    return call IMBAudio.readStream( data, length );
#else
    return call VirtualAudio.readStream( data, length );
#endif
  }

}

