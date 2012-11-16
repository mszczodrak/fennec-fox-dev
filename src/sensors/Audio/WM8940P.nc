#include <Fennec.h>
#include "wm8940_driver.c"

module WM8940P {
  provides interface Audio;
}

implementation {

  bool started = 0;

  void initialize() {
    WmInitialize();
    started = 1;
  }

  command uint16_t Audio.readSample() {
    if (!started) initialize();
    return WmReadSample();
    
  }

  command void Audio.writeSample( uint16_t sample ) {
    if (!started) initialize();
    WmWriteSample( sample );
  }

  command void Audio.setVolume( uint8_t volume ) {
    if (!started) initialize();
    WmSetVolume( volume );
  }

  command void Audio.playStream( uint32_t *data, uint32_t length ) {
    uint32_t i;
    if (!started) initialize();
    for( i = 0; i < length; i++) {
      WmWriteSample(data[i]);
    }    
  }

  command void Audio.readStream( uint32_t *data, uint32_t length ) {
    uint32_t i;
    if (!started) initialize();
    for( i = 0; i < length; i++) {
      data[i] = WmReadSample();
    }    
  }

}
