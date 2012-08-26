interface ParametersCC2420 {
  command void set_sink_addr(am_addr_t new_sink_addr);
  command void set_channel(uint8_t new_channel);
  command void set_power(uint8_t new_power);
  command void set_remote_wakeup(uint16_t new_remote_wakeup);
  command void set_delay_after_receive(uint16_t new_delay_after_receive);
  command void set_backoff(uint16_t new_backoff);
  command void set_min_backoff(uint16_t new_min_backoff);
  command void set_cca(uint8_t status);
  command void set_ack(uint8_t status);
  command void set_crc(uint8_t status);

  command am_addr_t get_sink_addr();
  command uint8_t get_channel();
  command uint8_t get_power();
  command uint16_t get_remote_wakeup();
  command uint16_t get_delay_after_receive();
  command uint16_t get_backoff();
  command uint16_t get_min_backoff();
  command uint8_t get_cca();
  command uint8_t get_ack();
  command uint8_t get_crc();
}
