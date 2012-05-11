interface Serial
{
  command void send(void *buf, uint16_t len);
  event void receive(void *buf, uint16_t len);
}
