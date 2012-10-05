#include "message.h"

interface cuTransmit {

  command error_t resend(message_t *msg, bool useCca);

}

