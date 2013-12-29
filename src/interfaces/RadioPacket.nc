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







        /**
         * This command returns the length of the header. The header
         * starts at the first byte of the message_t structure
         * (some layers may add dummy bytes to allign the payload to
         * the msg->data section).
         */
        async command uint8_t headerLength(message_t* msg);

        /**
         * Returns the length of the payload. The payload starts right
         * after the header.
         */
        async command uint8_t payloadLength(message_t* msg);

        /**
         * Sets the length of the payload.
         */
        async command void setPayloadLength(message_t* msg, uint8_t length);

        /**
         * Returns the length of the metadata section. The metadata section
         * is at the very end of the message_t structure and grows downwards.
         */
        async command uint8_t metadataLength(message_t* msg);

        /**
         * Clears all metadata and sets all default values in the headers.
         */
        async command void clear(message_t* msg);
}
