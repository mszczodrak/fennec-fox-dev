#include "message.h"

interface RadioBuffer {
  async command error_t load(message_t *msg);
  async event void loadDone(message_t *msg, error_t err);
}


