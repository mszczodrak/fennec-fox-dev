#include "message.h"

interface TDMATransmit {

  command error_t resend(bool useCca);

}

