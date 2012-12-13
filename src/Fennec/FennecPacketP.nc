#include "IEEE802154.h"
#include "message.h"
#include "CC2420.h"
#include "CC2420TimeSyncMessage.h"

module FennecPacketP @safe() {

  provides {
//    interface FennecPacket;
//    interface PacketAcknowledgements as Acks;
    interface CC2420PacketBody;
//    interface LinkPacketMetadata;

    interface PacketTimeStamp<T32khz, uint32_t> as PacketTimeStamp32khz;
    interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
    interface PacketTimeSyncOffset;
  }

  uses interface Packet;
  uses interface LocalTime<T32khz> as LocalTime32khz;
  uses interface LocalTime<TMilli> as LocalTimeMilli;
}

implementation {


  /***************** PacketAcknowledgement Commands ****************/
//  async command error_t Acks.requestAck( message_t* p_msg ) {
//    (call CC2420PacketBody.getHeader( p_msg ))->fcf |= 1 << IEEE154_FCF_ACK_REQ;
//    return SUCCESS;
//  }

//  async command error_t Acks.noAck( message_t* p_msg ) {
//    (call CC2420PacketBody.getHeader( p_msg ))->fcf &= ~(1 << IEEE154_FCF_ACK_REQ);
//    return SUCCESS;
//  }

//  async command bool Acks.wasAcked( message_t* p_msg ) {
//    return (call CC2420PacketBody.getMetadata( p_msg ))->ack;
//  }

  /***************** CC2420Packet Commands ****************/
  
  int getAddressLength(int type) {
    switch (type) {
    case IEEE154_ADDR_SHORT: return 2;
    case IEEE154_ADDR_EXT: return 8;
    case IEEE154_ADDR_NONE: return 0;
    default: return -100;
    }
  }
  
  uint8_t * ONE getNetwork(message_t * ONE msg) {
    cc2420_header_t *hdr = (call CC2420PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(cc2420_header_t, dest);

    return ((uint8_t *)hdr) + offset;
  }

//  async command void CC2420Packet.setPower( message_t* p_msg, uint8_t power ) {
//    if ( power > 31 )
//      power = 31;
//    (call CC2420PacketBody.getMetadata( p_msg ))->tx_power = power;
//  }

//  async command uint8_t CC2420Packet.getPower( message_t* p_msg ) {
//    return (call CC2420PacketBody.getMetadata( p_msg ))->tx_power;
//  }
   
//  async command int8_t CC2420Packet.getRssi( message_t* p_msg ) {
//    return (call CC2420PacketBody.getMetadata( p_msg ))->rssi;
//  }

//  async command uint8_t CC2420Packet.getLqi( message_t* p_msg ) {
//    return (call CC2420PacketBody.getMetadata( p_msg ))->lqi;
//  }

//  async command uint8_t CC2420Packet.getNetwork( message_t* ONE p_msg ) {
//#if defined(TFRAMES_ENABLED)
//    return TINYOS_6LOWPAN_NETWORK_ID;
//#else
//    atomic 
//      return *(getNetwork(p_msg));
//#endif
//  }

//  async command void CC2420Packet.setNetwork( message_t* ONE p_msg , uint8_t networkId ) {
//#if ! defined(TFRAMES_ENABLED)
//    atomic 
//      *(getNetwork(p_msg)) = networkId;
//#endif
//  }    


  /***************** CC2420PacketBody Commands ****************/
  async command cc2420_header_t * ONE CC2420PacketBody.getHeader( message_t* ONE msg ) {
    return TCAST(cc2420_header_t* ONE, (uint8_t *)msg + offsetof(message_t, data) - sizeof( cc2420_header_t ));
  }

  async command uint8_t * CC2420PacketBody.getPayload( message_t* msg) {
    cc2420_header_t *hdr = (call CC2420PacketBody.getHeader( msg ));
    int offset;
    
    offset = getAddressLength((hdr->fcf >> IEEE154_FCF_DEST_ADDR_MODE) & 0x3) +
      getAddressLength((hdr->fcf >> IEEE154_FCF_SRC_ADDR_MODE) & 0x3) + 
      offsetof(cc2420_header_t, dest);

    return ((uint8_t *)hdr) + offset;
  }

  async command cc2420_metadata_t *CC2420PacketBody.getMetadata( message_t* msg ) {
    return (cc2420_metadata_t*)msg->metadata;
  }

//  async command bool LinkPacketMetadata.highChannelQuality(message_t* msg) {
//    return call CC2420Packet.getLqi(msg) > 105;
//  }

  /***************** PacketTimeStamp32khz Commands ****************/
  async command bool PacketTimeStamp32khz.isValid(message_t* msg)
  {
    return ((call CC2420PacketBody.getMetadata( msg ))->timestamp != CC2420_INVALID_TIMESTAMP);
  }

  async command uint32_t PacketTimeStamp32khz.timestamp(message_t* msg)
  {
    return (call CC2420PacketBody.getMetadata( msg ))->timestamp;
  }

  async command void PacketTimeStamp32khz.clear(message_t* msg)
  {
    (call CC2420PacketBody.getMetadata( msg ))->timesync = FALSE;
    (call CC2420PacketBody.getMetadata( msg ))->timestamp = CC2420_INVALID_TIMESTAMP;
  }

  async command void PacketTimeStamp32khz.set(message_t* msg, uint32_t value)
  {
    (call CC2420PacketBody.getMetadata( msg ))->timestamp = value;
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
    return ((call CC2420PacketBody.getMetadata( msg ))->timesync);
  }

  //returns offset of timestamp from the beginning of cc2420 header which is
  //          sizeof(cc2420_header_t)+datalen-sizeof(timesync_radio_t)
  //uses packet length of the message which is
  //          MAC_HEADER_SIZE+MAC_FOOTER_SIZE+datalen
  async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
  {
    return (call CC2420PacketBody.getHeader(msg))->length
            + (sizeof(cc2420_header_t) - MAC_HEADER_SIZE)
            - MAC_FOOTER_SIZE
            - sizeof(timesync_radio_t);
  }
  
  async command void PacketTimeSyncOffset.set(message_t* msg)
  {
    (call CC2420PacketBody.getMetadata( msg ))->timesync = TRUE;
  }

  async command void PacketTimeSyncOffset.cancel(message_t* msg)
  {
    (call CC2420PacketBody.getMetadata( msg ))->timesync = FALSE;
  }


  void PacketTimeStampclear(message_t* msg) @C()
  {
    cc2420_metadata_t *meta = (cc2420_metadata_t*)getMetadata( msg );
    meta->timesync = FALSE;
    meta->timestamp = CC2420_INVALID_TIMESTAMP;
  }

  void PacketTimeStampset(message_t* msg, uint32_t value) @C()
  {
    cc2420_metadata_t *meta = (cc2420_metadata_t*)getMetadata( msg );
    meta->timestamp = value;
  }

  bool PacketTimeSyncOffsetisSet(message_t* msg) @C()
  {
    cc2420_metadata_t *meta = (cc2420_metadata_t*)getMetadata( msg );
    return (meta->timesync);
  }


}
