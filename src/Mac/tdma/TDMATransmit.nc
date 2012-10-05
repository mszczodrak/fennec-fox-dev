#include "message.h"

interface TDMATransmit {

  command error_t resend(message_t *msg, bool useCca);

}

