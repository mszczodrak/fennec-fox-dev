interface eTransmit {
  command error_t send(msg_t *msg);
  command error_t resend(msg_t *msg);
  command error_t load(msg_t *msg);
  event void loadDone(msg_t *msg, error_t);
  event void sendDone(msg_t *msg, error_t);
}
  


