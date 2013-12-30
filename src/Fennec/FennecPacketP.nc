//#include "message.h"
//#include "CC2420.h"

module FennecPacketP @safe() {

}

implementation {

enum
{
  // From CC2420.h file
  CC2420_INVALID_TIMESTAMP  = 0x80000000L,
};



enum {
	MAC_HEADER_SIZE = sizeof( fennec_header_t ) - 1,
	MAC_FOOTER_SIZE = sizeof( uint16_t )

};


  /**
	returns offset of timestamp from the beginning of cc2420 header which is
           sizeof(fennec_header_t)+datalen-sizeof(timesync_radio_t)
  uses packet length of the message which is
            MAC_HEADER_SIZE+MAC_FOOTER_SIZE+datalen
  */


  uint8_t PacketTimeSyncOffsetget(message_t* msg) @C() 
  {
    fennec_header_t *header = (fennec_header_t*) msg->data;
    return header->length
            + (sizeof(fennec_header_t) - MAC_HEADER_SIZE)
            - MAC_FOOTER_SIZE
            - sizeof(timesync_radio_t);
  }


  void PacketTimeStampclear(message_t* msg) @C()
  {
    metadata_t *meta = (metadata_t*)getMetadata( msg );
    meta->timesync = FALSE;
    meta->timestamp = CC2420_INVALID_TIMESTAMP;
  }

  void PacketTimeStampset(message_t* msg, uint32_t value) @C()
  {
    metadata_t *meta = (metadata_t*)getMetadata( msg );
    meta->timestamp = value;
  }

  bool PacketTimeSyncOffsetisSet(message_t* msg) @C()
  {
    metadata_t *meta = (metadata_t*)getMetadata( msg );
    return (meta->timesync);
  }


}
