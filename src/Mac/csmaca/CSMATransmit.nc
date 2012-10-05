#include "message.h"

interface CSMATransmit {

  command error_t resend(message_t *msg, bool useCca);

}

