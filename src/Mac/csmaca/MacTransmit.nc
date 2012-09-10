#include "message.h"

interface MacTransmit {

  command error_t send( message_t* ONE p_msg, bool useCca );

  command error_t resend(bool useCca);

  command error_t cancel();

  event void sendDone( message_t* ONE_NOK p_msg, error_t error );

}

