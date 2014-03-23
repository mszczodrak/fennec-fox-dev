/*
 * Copyright (c) 2010, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti, Janos Sallai
 */

#include <CC2420XRadio.h>
#include <RadioConfig.h>
#include <Tasklet.h>

module CC2420XDriverConfigP {

provides interface SplitControl;
	provides
	{
		interface CC2420XDriverConfig;
	}

	uses
	{
		interface Ieee154PacketLayer;
		interface RadioAlarm;
		interface RadioPacket as CC2420XPacket;

		interface PacketTimeStamp<TRadio, uint32_t>;
	}
	uses interface cc2420xParams;
}

implementation
{

/*----------------- CC2420XDriverConfig -----------------*/

	async command uint8_t CC2420XDriverConfig.headerLength(message_t* msg)
	{
		return offsetof(message_t, data) - sizeof(cc2420xpacket_header_t);
	}

	async command uint8_t CC2420XDriverConfig.maxPayloadLength()
	{
		return sizeof(cc2420xpacket_header_t) + TOSH_DATA_LENGTH;
	}

	async command uint8_t CC2420XDriverConfig.metadataLength(message_t* msg)
	{
		return 0;
	}

	async command uint8_t CC2420XDriverConfig.headerPreloadLength()
	{
		// we need the fcf, dsn, destpan and dest
		return 7;
	}

	async command bool CC2420XDriverConfig.requiresRssiCca(message_t* msg)
	{
		return call Ieee154PacketLayer.isDataFrame(msg);
	}

}
