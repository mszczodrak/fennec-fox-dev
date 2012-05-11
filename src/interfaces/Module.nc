interface Module {
  event uint8_t get_conf();
  event void drop_message(msg_t *msg);
  event msg_t* next_message();
}
