#ifndef __NULLRADIO_RADIO_H__
#define __NULLRADIO_RADIO_H__

#include <RadioConfig.h>
#include <TinyosNetworkLayer.h>
#include <Ieee154PacketLayer.h>
#include <ActiveMessageLayer.h>
#include <MetadataFlagsLayer.h>
#include <nullRadioDriverLayer.h>
#include <TimeStampingLayer.h>
#include <LowPowerListeningLayer.h>
#include <PacketLinkLayer.h>

typedef nx_struct nullRadiopacket_header_t
{
	nullRadio_header_t nullRadio;
	ieee154_simple_header_t ieee154;
#ifndef TFRAMES_ENABLED
	network_header_t network;
#endif
#ifndef IEEE154FRAMES_ENABLED
	activemessage_header_t am;
#endif
} nullRadiopacket_header_t;

typedef nx_struct nullRadiopacket_footer_t
{
	// the time stamp is not recorded here, time stamped messaged cannot have max length
} nullRadiopacket_footer_t;


typedef struct nullRadiopacket_metadata_t
{
#ifdef LOW_POWER_LISTENING
	lpl_metadata_t lpl;
#endif
#ifdef PACKET_LINK
	link_metadata_t link;
#endif
	timestamp_metadata_t timestamp;
	flags_metadata_t flags;
	message_metadata_t nullRadio;
} nullRadiopacket_metadata_t;

#endif//__NULLRADIO_H__
