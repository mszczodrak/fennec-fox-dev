/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * The Active Message layer for the CC2420 radio with timesync support. This
 * configuration is just layer above CC2420ActiveMessageC that supports
 * TimeSyncPacket and TimeSyncAMSend interfaces (TEP 133)
 *
 * @author: Miklos Maroti
 * @author: Brano Kusy (CC2420 port)
 */

#include <Timer.h>
#include <AM.h>
#include "TimeSyncMessage.h"

configuration TimeSyncMessageC {
provides interface Receive;
provides interface Receive as Snoop;
provides interface Packet;
provides interface AMPacket;
    
provides interface TimeSyncAMSend<T32khz, uint32_t> as TimeSyncAMSend32khz;
provides interface TimeSyncPacket<T32khz, uint32_t> as TimeSyncPacket32khz;

provides interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli;
provides interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;

uses interface AMSend as SubAMSend;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;

uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;

}

implementation {
components TimeSyncMessageP, CC2420PacketC;

TimeSyncAMSend32khz = TimeSyncMessageP;
TimeSyncPacket32khz = TimeSyncMessageP;

TimeSyncAMSendMilli = TimeSyncMessageP;
TimeSyncPacketMilli = TimeSyncMessageP;

Packet = TimeSyncMessageP;

SubAMSend = TimeSyncMessageP.SubSend;
SubAMPacket = TimeSyncMessageP.SubAMPacket;
SubPacket = TimeSyncMessageP.SubPacket;

TimeSyncMessageP.PacketTimeStamp32khz -> CC2420PacketC;
TimeSyncMessageP.PacketTimeStampMilli -> CC2420PacketC;
TimeSyncMessageP.PacketTimeSyncOffset -> CC2420PacketC;
components Counter32khz32C, new CounterToLocalTimeC(T32khz) as LocalTime32khzC, LocalTimeMilliC;
LocalTime32khzC.Counter -> Counter32khz32C;
TimeSyncMessageP.LocalTime32khz -> LocalTime32khzC;
TimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;

Receive = TimeSyncMessageP.Receive;
Snoop = TimeSyncMessageP.Snoop;
AMPacket = TimeSyncMessageP;

SubReceive = TimeSyncMessageP.SubReceive;
SubSnoop = TimeSyncMessageP.SubSnoop;
}
