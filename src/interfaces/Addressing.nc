interface Addressing {
  async command uint8_t length(msg_t *msg);
  async command nx_uint8_t* addr(nx_uint16_t addr, msg_t *msg);
  async command bool eq(nx_uint8_t *ad1, nx_uint8_t *ad2, msg_t *msg);
  async command bool copy(nx_uint8_t *pos, nx_uint16_t ad, msg_t *msg);
  async command bool move(nx_uint8_t *ad1, nx_uint8_t *ad2, msg_t *msg);
  async command bool set(nx_uint8_t *pos, nx_uint16_t ad, msg_t *msg);
}
