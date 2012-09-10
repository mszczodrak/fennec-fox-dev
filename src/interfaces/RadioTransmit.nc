#include "message.h"

interface RadioTransmit {

  async command void cancel();
  async command error_t load(message_t *msg);
  async command error_t send(message_t *msg, bool useCca);
  async event void sendDone(error_t err);
  async event void loadDone(message_t *msg, error_t err);
}


