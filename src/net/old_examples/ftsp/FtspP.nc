#include "Ftsp.h"

module FtspP {
    uses
    {
        interface GlobalTime<TMilli>;
        interface TimeSyncInfo;
        interface Receive;
        interface AMSend;
        interface Packet;
        interface Leds;
        interface PacketTimeStamp<TMilli,uint32_t>;
        interface Boot;
        interface SplitControl as RadioControl;
    }
}

implementation
{
    message_t msg;
    bool locked = FALSE;

    event void Boot.booted() {
        call RadioControl.start();
    }

    event message_t* Receive.receive(message_t* msgPtr, void* payload, uint8_t len)
    {
        call Leds.led0Toggle();
        if (!locked && call PacketTimeStamp.isValid(msgPtr)) {
//            radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(msgPtr, sizeof(radio_count_msg_t));
            ftsp_msg_t* report = (ftsp_msg_t*)call Packet.getPayload(&msg, sizeof(ftsp_msg_t));

            uint32_t rxTimestamp = call PacketTimeStamp.timestamp(msgPtr);

            report->src_addr = TOS_NODE_ID;
//            report->counter = rcm->counter;
            report->counter = 0;
            report->local_rx_timestamp = rxTimestamp;
            report->is_synced = call GlobalTime.local2Global(&rxTimestamp);
            report->global_rx_timestamp = rxTimestamp;
            report->skew_times_1000000 = (uint32_t)call TimeSyncInfo.getSkew()*1000000UL;
            report->ftsp_root_addr = call TimeSyncInfo.getRootID();
            report->ftsp_seq = call TimeSyncInfo.getSeqNum();
            report->ftsp_table_entries = call TimeSyncInfo.getNumEntries();

            if (call AMSend.send(AM_BROADCAST_ADDR, &msg, sizeof(ftsp_msg_t)) == SUCCESS) {
              locked = TRUE;
            }
        }

        return msgPtr;
    }

    event void AMSend.sendDone(message_t* ptr, error_t success) {
        locked = FALSE;
        return;
    }

    event void RadioControl.startDone(error_t err) {}
    event void RadioControl.stopDone(error_t error){}
}

