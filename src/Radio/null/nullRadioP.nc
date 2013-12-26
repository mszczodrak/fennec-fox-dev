/*
 *  null radio module for Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * Network: null Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include "nullRadio.h"

module nullRadioP @safe() {

provides interface SplitControl;

uses interface nullRadioParams;

provides interface RadioSend;
provides interface RadioReceive;
provides interface RadioCCA;
provides interface RadioPacket;

provides interface PacketField<uint8_t> as PacketTransmitPower;
provides interface PacketField<uint8_t> as PacketRSSI;
provides interface PacketField<uint8_t> as PacketTimeSyncOffset;
provides interface PacketField<uint8_t> as PacketLinkQuality;
provides interface LinkPacketMetadata;


}

implementation {

uint8_t channel;
norace uint8_t state = S_STOPPED;
norace message_t *m;

task void start_done() {
	state = S_STARTED;
	signal SplitControl.startDone(SUCCESS);
}

task void finish_starting_radio() {
	post start_done();
}

task void stop_done() {
	state = S_STOPPED;
	signal SplitControl.stopDone(SUCCESS);
}

command error_t SplitControl.start() {
	dbg("Radio", "nullRadio SplitControl.start()");

	if (state == S_STOPPED) {
		state = S_STARTING;
		post start_done();
		return SUCCESS;

	} else if(state == S_STARTED) {
		post start_done();
		return EALREADY;

	} else if(state == S_STARTING) {
		return SUCCESS;
	}
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("Radio", "nullRadio SplitControl.stop()");
	if (state == S_STARTED) {
		state = S_STOPPING;
		post stop_done();
		return SUCCESS;
	} else if(state == S_STOPPED) {
		post stop_done();
		return EALREADY;
	} else if(state == S_STOPPING) {
		return SUCCESS;
	}
	return SUCCESS;
}


        tasklet_async command error_t RadioCCA.request()
        {
		signal RadioCCA.done(SUCCESS);
                return SUCCESS;
        }

/*----------------- PacketTransmitPower -----------------*/

        async command bool PacketTransmitPower.isSet(message_t* msg)
        {
                return TRUE;
        }

        async command uint8_t PacketTransmitPower.get(message_t* msg)
        {
                return 0;
        }

        async command void PacketTransmitPower.clear(message_t* msg)
        {
                
        }

        async command void PacketTransmitPower.set(message_t* msg, uint8_t value)
        {
        }


/*----------------- PacketRSSI -----------------*/

        async command bool PacketRSSI.isSet(message_t* msg)
        {
                return TRUE;
        }

        async command uint8_t PacketRSSI.get(message_t* msg)
        {
                return 0;
        }

        async command void PacketRSSI.clear(message_t* msg)
        {
        }

        async command void PacketRSSI.set(message_t* msg, uint8_t value)
        {
        }

/*----------------- PacketTimeSyncOffset -----------------*/

        async command bool PacketTimeSyncOffset.isSet(message_t* msg)
        {
                return TRUE;
        }

        async command uint8_t PacketTimeSyncOffset.get(message_t* msg)
        {
                return 0;
        }

        async command void PacketTimeSyncOffset.clear(message_t* msg)
        {
        }

        async command void PacketTimeSyncOffset.set(message_t* msg, uint8_t value)
        {
        }


/*----------------- PacketLinkQuality -----------------*/

        async command bool PacketLinkQuality.isSet(message_t* msg)
        {
                return TRUE;
        }

        async command uint8_t PacketLinkQuality.get(message_t* msg)
        {
                return 0;
        }

        async command void PacketLinkQuality.clear(message_t* msg)
        {
        }

        async command void PacketLinkQuality.set(message_t* msg, uint8_t value)
        {
        }

/*----------------- LinkPacketMetadata -----------------*/

        async command bool LinkPacketMetadata.highChannelQuality(message_t* msg)
        {
                return TRUE;
        }



/*----------------- RadioPacket -----------------*/

        async command uint8_t RadioPacket.headerLength(message_t* msg)
        {
                return 0;
        }

        async command uint8_t RadioPacket.payloadLength(message_t* msg)
        {
                return 0;
        }

        async command void RadioPacket.setPayloadLength(message_t* msg, uint8_t length)
        {
        }

        async command uint8_t RadioPacket.maxPayloadLength()
        {
                return 128;
        }

        async command uint8_t RadioPacket.metadataLength(message_t* msg)
        {
                return 0;
        }

        async command void RadioPacket.clear(message_t* msg)
        {
        }

        tasklet_async command error_t RadioSend.send(message_t* msg)
        {
		return SUCCESS;
	}



}

