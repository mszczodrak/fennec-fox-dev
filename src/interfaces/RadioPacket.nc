#include <TinyError.h>
#include <message.h>

interface RadioPacket {

   /**
   * Return the maximum payload length that this communication layer
   * can provide. This command behaves identically to
   * <tt>Packet.maxPayloadLength</tt> and is included in this
   * interface as a convenience.
   *
   * @return  the maximum payload length
   */

  
  async command uint8_t maxPayloadLength();


   /**
    * Return a pointer to a protocol's payload region in a packet which
    * at least a certain length.  If the payload region is smaller than
    * the len parameter, then getPayload returns NULL. This command
    * behaves identicallt to <tt>Packet.getPayload</tt> and is
    * included in this interface as a convenience.
    *
    * @param   'message_t* ONE msg'    the packet
    * @return  'void* COUNT_NOK(len)'  a pointer to the packet's payload
    */
  async command void* getPayload(message_t* msg, uint8_t len);

}
