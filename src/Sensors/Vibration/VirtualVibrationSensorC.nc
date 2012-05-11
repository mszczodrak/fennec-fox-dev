
configuration VirtualVibrationSensorC {
  provides interface Read<uint16_t>;
}

implementation {

  components VirtualVibrationSensorP;
  Read = VirtualVibrationSensorP;

}

