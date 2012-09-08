#include "message.h"

interface RadioTransmit {

  command void start();
  command void stop();
  command void cancel();
  command error_t load(message_t *msg);
  command error_t send(message_t *msg, bool useCca);
  event void sendDone(error_t err);
  event void loadDone(message_t *msg, error_t err);


}


