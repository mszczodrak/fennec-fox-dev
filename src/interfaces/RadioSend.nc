#include <TinyError.h>
#include <message.h>

interface RadioSend {

/** 
  * Send a packet with a data payload of <tt>len</tt>. To determine
  * the maximum available size, use the Packet interface of the
  * component providing Send. If send returns SUCCESS, then the
  * component will signal the sendDone event in the future; if send
  * returns an error, it will not signal sendDone.  Note that a
  * component may accept a send request which it later finds it
  * cannot satisfy; in this case, it will signal sendDone with an
  * appropriate error code.
  *
  * @param   'message_t* ONE msg'     the packet to send
  * @param   len     the length of the packet payload
  * @return          SUCCESS if the request was accepted and will issue
  *                  a sendDone event, EBUSY if the component cannot accept
  *                  the request now but will be able to later, FAIL
  *                  if the stack is in a state that cannot accept requests
  *                  (e.g., it's off).
  */ 
async command error_t send(message_t* msg, uint8_t len);

/** 
  * Signaled in response to an accepted send request. <tt>msg</tt>
  * is the sent buffer, and <tt>error</tt> indicates whether the
  * send was succesful, and if not, the cause of the failure.
  * 
  * @param 'message_t* ONE msg'   the message which was requested to send
  * @param error SUCCESS if it was transmitted successfully, FAIL if
  *              it was not, ECANCEL if it was cancelled via <tt>cancel</tt>
  */ 
async event void sendDone(message_t* msg, error_t error);


/**
  * This event is fired when the component is most likely able to accept
  * a send request. If the send command has returned with a failure, then
  * this event will be called at least once in the near future.
  */
async event void ready();


}
