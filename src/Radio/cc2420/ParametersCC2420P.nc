module ParametersCC2420P @safe() {

  provides interface ParametersCC2420;
}

implementation {

  am_addr_t 	current_sink_addr;
  uint8_t 	current_channel;
  uint8_t	current_power;
  uint16_t	current_remote_wakeup;
  uint16_t	current_delay_after_receive;
  uint16_t	current_backoff;
  uint16_t	current_min_backoff;
  uint8_t	current_cca;
  uint8_t	current_ack;
  uint8_t	current_crc;

  command void ParametersCC2420.set_sink_addr(am_addr_t new_sink_addr) {
    current_sink_addr = new_sink_addr;
  }

  command void ParametersCC2420.set_channel(uint8_t new_channel) {
    current_channel = new_channel;
  }

  command void ParametersCC2420.set_power(uint8_t new_power) {
    current_power = new_power;
  }

  command void ParametersCC2420.set_remote_wakeup(uint16_t new_remote_wakeup) {
    current_remote_wakeup = new_remote_wakeup;
  }

  command void ParametersCC2420.set_delay_after_receive(uint16_t new_delay_after_receive) {
    current_delay_after_receive = new_delay_after_receive;
  }

  command void ParametersCC2420.set_backoff(uint16_t new_backoff) {
    current_backoff = new_backoff;
  }

  command void ParametersCC2420.set_min_backoff(uint16_t new_min_backoff) {
    current_min_backoff = new_min_backoff;
  }

  command void ParametersCC2420.set_cca(uint8_t new_cca) {
    current_cca = new_cca;
  }

  command void ParametersCC2420.set_ack(uint8_t new_ack) {
    current_ack = new_ack;
  }

  command void ParametersCC2420.set_crc(uint8_t new_crc) {
    current_crc = new_crc;
  }

  command am_addr_t ParametersCC2420.get_sink_addr() {
    return current_sink_addr;
  }

  command uint8_t ParametersCC2420.get_channel() {
    return current_channel;
  }

  command uint8_t ParametersCC2420.get_power() {
    return current_power;
  }

  command uint16_t ParametersCC2420.get_remote_wakeup() {
    return current_remote_wakeup;
  }

  command uint16_t ParametersCC2420.get_delay_after_receive() {
    return current_delay_after_receive;
  }

  command uint16_t ParametersCC2420.get_backoff() {
    return current_backoff;
  }

  command uint16_t ParametersCC2420.get_min_backoff() {
    return current_min_backoff;
  }

  command uint8_t ParametersCC2420.get_cca() {
    return current_cca;
  }

  command uint8_t ParametersCC2420.get_ack() {
    return current_ack;
  }

  command uint8_t ParametersCC2420.get_crc() {
    return current_crc;
  }

}
