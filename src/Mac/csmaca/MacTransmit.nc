#include "message.h"

interface MacTransmit {

  async command error_t send( message_t* ONE p_msg, bool useCca );

  async command error_t resend(bool useCca);

  async command error_t cancel();

  async event void sendDone( message_t* ONE_NOK p_msg, error_t error );

}

