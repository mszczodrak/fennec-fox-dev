interface cc2420XDriverParams {

command void set_power(uint8_t power);
command uint8_t get_power();
command void set_channel(uint8_t channel);
command uint8_t get_channel();
command void set_ack(uint8_t status);
command uint8_t get_ack();
command void set_crc(uint8_t status);
command uint8_t get_crc();

}
