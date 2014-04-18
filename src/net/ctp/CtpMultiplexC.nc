#include "ctp.h"

configuration CtpMultiplexC {
provides interface AMSend[uint8_t id];
provides interface Receive[uint8_t id];
provides interface Receive as Snoop[uint8_t id];

uses interface AMSend as SubAMSend;
uses interface AMPacket as SubAMPacket;
uses interface Packet as SubPacket;
uses interface Receive as SubReceive;
uses interface Receive as SubSnoop;

provides interface AMSend as SubQueueAMSend[uint8_t id];

uses interface Send as QueueSend[uint8_t sid];

}

implementation {

components CtpMultiplexP;
AMSend = CtpMultiplexP.AMSend;
Receive = CtpMultiplexP.Receive;
Snoop = CtpMultiplexP.Snoop;

QueueSend = CtpMultiplexP.QueueSend;

SubReceive = CtpMultiplexP.SubReceive;
SubSnoop = CtpMultiplexP.SubSnoop;
SubAMSend = CtpMultiplexP.SubAMSend;
SubAMPacket = CtpMultiplexP.SubAMPacket;
SubPacket = CtpMultiplexP.SubPacket;

SubQueueAMSend = CtpMultiplexP.SubQueueAMSend;

}
