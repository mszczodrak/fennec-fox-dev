
configuration VirtualSoundSensorC {
  provides interface Read<uint16_t>;
}

implementation {

  components VirtualSoundSensorP;
  Read = VirtualSoundSensorP;

}

