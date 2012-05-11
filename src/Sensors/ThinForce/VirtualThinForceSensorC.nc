
configuration VirtualThinForceSensorC {
  provides interface Read<uint16_t>;
}

implementation {

  components VirtualThinForceSensorP;
  Read = VirtualThinForceSensorP;

}

