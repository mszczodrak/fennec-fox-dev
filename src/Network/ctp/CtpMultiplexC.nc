#include "ctp.h"

configuration CtpMultiplexC {
provides interface AMSend[uint8_t id];
provides interface Receive[uint8_t id];
provides interface Receive as Snoop[uint8_t id];

uses interface AMSend as MacAMSend;
uses interface AMPacket as MacAMPacket;
uses interface Packet as MacPacket;
uses interface Receive as MacReceive;
uses interface Receive as MacSnoop;

provides interface AMSend as SubQueueAMSend[uint8_t id];

uses interface Send as QueueSend[uint8_t sid];

}

implementation {

components CtpMultiplexP;
AMSend = CtpMultiplexP.AMSend;
Receive = CtpMultiplexP.Receive;
Snoop = CtpMultiplexP.Snoop;

QueueSend = CtpMultiplexP.QueueSend;

MacReceive = CtpMultiplexP.MacReceive;
MacSnoop = CtpMultiplexP.MacSnoop;
MacAMSend = CtpMultiplexP.MacAMSend;
MacAMPacket = CtpMultiplexP.MacAMPacket;
MacPacket = CtpMultiplexP.MacPacket;

SubQueueAMSend = CtpMultiplexP.SubQueueAMSend;

}
