#include "message.h"

interface CSMATransmit {

  command error_t resend(bool useCca);

}

