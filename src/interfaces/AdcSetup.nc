interface AdcSetup {
  command error_t set_input_channel(uint8_t new_input_channel);
  command uint8_t get_input_channel();
}
