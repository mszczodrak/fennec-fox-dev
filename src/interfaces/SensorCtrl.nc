interface SensorCtrl {
  command error_t start();
  command error_t stop();

  event void startDone(error_t err);
  event void stopDone(error_t err);

  command error_t set_sensitivity(uint16_t new_sensitivity);
  command error_t set_rate(uint32_t new_rate);
  command error_t set_signaling(bool new_signaling);
  command error_t set_input_channel(uint8_t new_input_channel);

  command uint16_t get_sensitivity();
  command uint32_t get_rate();
  command bool get_signaling();
  command uint8_t get_input_channel();
}
