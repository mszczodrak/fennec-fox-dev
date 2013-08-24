#include "IEEE802154.h"
//#include "message.h"
//#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"

module FennecPacketP @safe() {

  provides {

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
  }

  uses interface Packet;
  uses interface LocalTime<T32khz> as LocalTime32khz;
  uses interface LocalTime<TMilli> as LocalTimeMilli;
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


metadata_t* getMetadata( message_t* msg ) @C() {
	return (metadata_t*)msg->metadata;
}

  int getAddressLength(int type) {
    switch (type) {
    case IEEE154_ADDR_SHORT: return 2;
    case IEEE154_ADDR_EXT: return 8;
    case IEEE154_ADDR_NONE: return 0;
    default: return -100;
    }
  }
 
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



  /***************** PacketTimeStamp32khz Commands ****************/
  async command bool PacketTimeStamp32khz.isValid(message_t* msg)
  {
    return ((getMetadata( msg ))->timestamp != CC2420_INVALID_TIMESTAMP);
  }

  async command uint32_t PacketTimeStamp32khz.timestamp(message_t* msg)
  {
    return (getMetadata( msg ))->timestamp;
  }

  async command void PacketTimeStamp32khz.clear(message_t* msg)
  {
    (getMetadata( msg ))->timesync = FALSE;
    (getMetadata( msg ))->timestamp = CC2420_INVALID_TIMESTAMP;
  }

  async command void PacketTimeStamp32khz.set(message_t* msg, uint32_t value)
  {
    (getMetadata( msg ))->timestamp = value;
  }

  /***************** PacketTimeStampMilli Commands ****************/
  // over the air value is always T32khz, which is used to capture SFD interrupt
  // (Timer1 on micaZ, B1 on telos)
  async command bool PacketTimeStampMilli.isValid(message_t* msg)
  {
    return call PacketTimeStamp32khz.isValid(msg);
  }

  //timestmap is always represented in 32khz
  //28.1 is coefficient difference between T32khz and TMilli on MicaZ
  async command uint32_t PacketTimeStampMilli.timestamp(message_t* msg)
  {
    int32_t offset = (call LocalTime32khz.get()-call PacketTimeStamp32khz.timestamp(msg));
    offset/=28.1;
    return call LocalTimeMilli.get() - offset;
  }

  async command void PacketTimeStampMilli.clear(message_t* msg)
  {
    call PacketTimeStamp32khz.clear(msg);
  }

  async command void PacketTimeStampMilli.set(message_t* msg, uint32_t value)
  {
    int32_t offset = (value - call LocalTimeMilli.get()) << 5;
    call PacketTimeStamp32khz.set(msg, offset + call LocalTime32khz.get());
  }
  /*----------------- PacketTimeSyncOffset -----------------*/
  async command bool PacketTimeSyncOffset.isSet(message_t* msg)
  {
    return ((getMetadata( msg ))->timesync);
  }

  //returns offset of timestamp from the beginning of cc2420 header which is
  //          sizeof(fennec_header_t)+datalen-sizeof(timesync_radio_t)
  //uses packet length of the message which is
  //          MAC_HEADER_SIZE+MAC_FOOTER_SIZE+datalen
  async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
  {
    return ((fennec_header_t*)msg->data)->length
            + (sizeof(fennec_header_t) - MAC_HEADER_SIZE)
            - MAC_FOOTER_SIZE
            - sizeof(timesync_radio_t);
  }
  
  async command void PacketTimeSyncOffset.set(message_t* msg)
  {
    (getMetadata( msg ))->timesync = TRUE;
  }

  async command void PacketTimeSyncOffset.cancel(message_t* msg)
  {
    (getMetadata( msg ))->timesync = FALSE;
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
