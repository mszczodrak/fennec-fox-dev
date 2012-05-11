interface Audio {
  command uint16_t readSample();
  command void writeSample( uint16_t sample );
  command void setVolume( uint8_t volume );
  command void playStream( uint32_t *data, uint32_t length );
  command void readStream( uint32_t *data, uint32_t length );
}
