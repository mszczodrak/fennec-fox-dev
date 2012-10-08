#include "TimeSyncMsg.h"
#include "tdmaMac.h"

generic module TimeSyncP(typedef precision_tag)
{
    provides
    {
        interface StdControl;
        interface GlobalTime<precision_tag>;

        //interfaces for extra functionality: need not to be wired
        interface TimeSyncInfo;
        interface TimeSyncMode;
        interface TimeSyncNotify;
    }
    uses
    {
        interface TimeSyncAMSend<precision_tag,uint32_t> as Send;
        interface Receive;
        interface Timer<TMilli>;
        interface Random;
        interface Leds;
        interface TimeSyncPacket<precision_tag,uint32_t>;
        interface LocalTime<precision_tag> as LocalTime;
    }
    uses interface tdmaMacParams;
}
implementation
{

    TableItem   table[MAX_ENTRIES];
    uint8_t tableEntries;
    bool busy_sending = FALSE;

    enum {
        STATE_IDLE = 0x00,
        STATE_PROCESSING = 0x01,
        STATE_SENDING = 0x02,
        STATE_INIT = 0x04,
    };

    uint8_t state = STATE_IDLE;

/*
    We do linear regression from localTime to timeOffset (globalTime - localTime).
    This way we can keep the slope close to zero (ideally) and represent it
    as a float with high precision.

        timeOffset - offsetAverage = skew * (localTime - localAverage)
        timeOffset = offsetAverage + skew * (localTime - localAverage)
        globalTime = localTime + offsetAverage + skew * (localTime - localAverage)
*/

    float       skew;
    uint32_t    localAverage;
    int32_t     offsetAverage;
    uint8_t     numEntries = 0; // the number of full entries in the table

    message_t processedMsgBuffer;
    message_t* processedMsg;

    message_t outgoingMsgBuffer;
    TimeSyncMsg* outgoingMsg;

    uint8_t receive_counter = 0;

    async command uint32_t GlobalTime.getLocalTime()
    {
        return call LocalTime.get();
    }

    async command error_t GlobalTime.getGlobalTime(uint32_t *time)
    {
        *time = call GlobalTime.getLocalTime();
        return call GlobalTime.local2Global(time);
    }

    error_t is_synced()
    {
      if ((numEntries>=ENTRY_VALID_LIMIT) || (outgoingMsg->rootID==TOS_NODE_ID))
        return SUCCESS;
      else
        return FAIL;
    }


    async command error_t GlobalTime.local2Global(uint32_t *time)
    {
        *time += offsetAverage + (int32_t)(skew * (int32_t)(*time - localAverage));
        return is_synced();
    }

    async command error_t GlobalTime.global2Local(uint32_t *time)
    {
        uint32_t approxLocalTime = *time - offsetAverage;
        *time = approxLocalTime - (int32_t)(skew * (int32_t)(approxLocalTime - localAverage));
        return is_synced();
    }

    void calculateConversion()
    {
        float newSkew = skew;
        uint32_t newLocalAverage;
        int32_t newOffsetAverage;
        int32_t localAverageRest;
        int32_t offsetAverageRest;

        int64_t localSum;
        int64_t offsetSum;

        int8_t i;

        for(i = 0; i < MAX_ENTRIES && table[i].state != ENTRY_FULL; ++i)
            ;

        if( i >= MAX_ENTRIES )  // table is empty
            return;

/*
        We use a rough approximation first to avoid time overflow errors. The idea
        is that all times in the table should be relatively close to each other.
*/
        newLocalAverage = table[i].localTime;
        newOffsetAverage = table[i].timeOffset;

        localSum = 0;
        localAverageRest = 0;
        offsetSum = 0;
        offsetAverageRest = 0;

        while( ++i < MAX_ENTRIES )
            if( table[i].state == ENTRY_FULL ) {
                /*
                   This only works because C ISO 1999 defines the signe for modulo the same as for the Dividend!
                */ 
                localSum += (int32_t)(table[i].localTime - newLocalAverage) / tableEntries;
                localAverageRest += (table[i].localTime - newLocalAverage) % tableEntries;
                offsetSum += (int32_t)(table[i].timeOffset - newOffsetAverage) / tableEntries;
                offsetAverageRest += (table[i].timeOffset - newOffsetAverage) % tableEntries;
            }

        newLocalAverage += localSum + localAverageRest / tableEntries;
        newOffsetAverage += offsetSum + offsetAverageRest / tableEntries;

	/* up to here is good */

        localSum = offsetSum = 0;
        for(i = 0; i < MAX_ENTRIES; ++i)
            if( table[i].state == ENTRY_FULL ) {
                int32_t a = table[i].localTime - newLocalAverage;         // a is (xi - x)
                int32_t b = table[i].timeOffset - newOffsetAverage;	  // b is (yi - y)

                localSum += (int64_t)a * a;				// E (xi -x)^2
                offsetSum += (int64_t)a * b;				// E (xi - x)(yi - y)
            }

        if( localSum != 0 ) {
	    newSkew = (float)offsetSum / (float)localSum;
	}

        atomic
        {
            skew = newSkew;
            offsetAverage = newOffsetAverage;
            localAverage = newLocalAverage;
            numEntries = tableEntries;
        }
    }

    void clearTable()
    {
        int8_t i;
        for(i = 0; i < MAX_ENTRIES; ++i)
            table[i].state = ENTRY_EMPTY;

        atomic numEntries = 0;
    }

    uint8_t numErrors=0;
    void addNewEntry(TimeSyncMsg *msg)
    {
        int8_t i, freeItem = -1, oldestItem = 0;
        uint32_t age, oldestTime = 0;
        int32_t timeError;

        // clear table if the received entry's been inconsistent for some time
        timeError = msg->localTime;
        call GlobalTime.local2Global((uint32_t*)(&timeError));
        timeError -= msg->globalTime;
        if( (is_synced() == SUCCESS) &&
            (timeError > ENTRY_THROWOUT_LIMIT || timeError < -ENTRY_THROWOUT_LIMIT))
        {
            if (++numErrors>3)
                clearTable();
            return; // don't incorporate a bad reading
        }

        tableEntries = 0; // don't reset table size unless you're recounting
        numErrors = 0;

        for(i = 0; i < MAX_ENTRIES; ++i) {
            age = msg->localTime - table[i].localTime;

            //logical time error compensation
            if( age >= 0x7FFFFFFFL )
                table[i].state = ENTRY_EMPTY;

            if( table[i].state == ENTRY_EMPTY )
                freeItem = i;
            else
                ++tableEntries;

            if( age >= oldestTime ) {
                oldestTime = age;
                oldestItem = i;
            }
        }

        if( freeItem < 0 )
            freeItem = oldestItem;
        else
            ++tableEntries;

        table[freeItem].state = ENTRY_FULL;

        table[freeItem].localTime = msg->localTime;
        table[freeItem].timeOffset = msg->globalTime - msg->localTime;
    }

    void task processMsg()
    {
        TimeSyncMsg* msg = (TimeSyncMsg*)(call Send.getPayload(processedMsg, sizeof(TimeSyncMsg)));

        if( msg->rootID < outgoingMsg->rootID ) {
            outgoingMsg->rootID = msg->rootID;
            outgoingMsg->seqNum = msg->seqNum;
        }
        else if( outgoingMsg->rootID == msg->rootID && (int8_t)(msg->seqNum - outgoingMsg->seqNum) > 0 ) {
            outgoingMsg->seqNum = msg->seqNum;
        }
        else
            goto exit;

        addNewEntry(msg);
        calculateConversion();
        signal TimeSyncNotify.msg_received();

    exit:
        state &= ~STATE_PROCESSING;
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
    {

        if( (state & STATE_PROCESSING) == 0
            && call TimeSyncPacket.isValid(msg)) {
            message_t* old = processedMsg;

            processedMsg = msg;
            ((TimeSyncMsg*)(payload))->localTime = call TimeSyncPacket.eventTime(msg);

            state |= STATE_PROCESSING;
            post processMsg();

            return old;
        }
        receive_counter++;

        return msg;
    }

    task void sendMsg()
    {
        uint32_t localTime, globalTime;

        globalTime = localTime = call GlobalTime.getLocalTime();
        call GlobalTime.local2Global(&globalTime);

        // we need to periodically update the reference point for the root
        // to avoid wrapping the 32-bit (localTime - localAverage) value
        if( outgoingMsg->rootID == TOS_NODE_ID ) {
            if( (int32_t)(localTime - localAverage) >= 0x20000000 )
            {
                atomic
                {
                    localAverage = localTime;
                    offsetAverage = globalTime - localTime;
                }
            }
        }

        outgoingMsg->globalTime = globalTime;
        // we don't send time sync msg, if we don't have enough data
        if( numEntries < ENTRY_SEND_LIMIT && outgoingMsg->rootID != TOS_NODE_ID ){
            state &= ~STATE_SENDING;
            busy_sending = FALSE;
        }
        else if( call Send.send(AM_BROADCAST_ADDR, &outgoingMsgBuffer, TIMESYNCMSG_LEN, localTime ) != SUCCESS ){
            state &= ~STATE_SENDING;
            busy_sending = FALSE;
            signal TimeSyncNotify.msg_sent();
        }
    }

    event void Send.sendDone(message_t* ptr, error_t error)
    {
        busy_sending = FALSE;
        if (ptr != &outgoingMsgBuffer)
          return;

        if(error == SUCCESS)
        {
            if( outgoingMsg->rootID == TOS_NODE_ID )
                ++(outgoingMsg->seqNum);
        }

        state &= ~STATE_SENDING;
        signal TimeSyncNotify.msg_sent();
    }

    void timeSyncMsgSend()
    {
        if( outgoingMsg->rootID != 0xFFFF && (state & STATE_SENDING) == 0 ) {
           busy_sending = TRUE;
           state |= STATE_SENDING;
           post sendMsg();
        }
    }

    event void Timer.fired()
    {
      timeSyncMsgSend();
    }

    command error_t TimeSyncMode.setMode(uint8_t mode_) {
        return SUCCESS;
    }

    command uint8_t TimeSyncMode.getMode(){
        return TS_USER_MODE;
    }

    command error_t TimeSyncMode.send(){
        if ((call Timer.isRunning() == TRUE) || (busy_sending == TRUE)) {
          //printf("busy\n");
          //printfflush();
          return SUCCESS;
        }

        if (is_synced() != SUCCESS) {
          //printf("not synced\n");
          //printfflush();
          return SUCCESS;
        }

        if (call tdmaMacParams.get_root_addr() == TOS_NODE_ID) {
          uint32_t d = 1 + call Random.rand32() % (call tdmaMacParams.get_active_time() 
							/ (ENTRY_VALID_LIMIT * 2));
          //printf("send %lu\n", d);
          //printfflush();
          call Timer.startOneShot(d);
        } else {
          uint32_t d = 10 + call Random.rand32() % (call tdmaMacParams.get_active_time()
                					/ (ENTRY_VALID_LIMIT));
          //printf("send %lu\n", d);
          //printfflush();
          call Timer.startOneShot(d);
        }
        return SUCCESS;
    }


    command error_t StdControl.start()
    {

        if (state == STATE_IDLE) {
          receive_counter = 0;
          clearTable();
          atomic {
            skew = 0.0;
            localAverage = 0;
   	    offsetAverage = 0;
            outgoingMsg = (TimeSyncMsg*)call Send.getPayload(&outgoingMsgBuffer, sizeof(TimeSyncMsg));
          }
  	  if (outgoingMsg == NULL) {
	    return FAIL;
	  }

	  if (call tdmaMacParams.get_root_addr() == TOS_NODE_ID) {
  	    outgoingMsg->rootID = TOS_NODE_ID;
          } else {
  	    outgoingMsg->rootID = 0xFFFF;
          }

          processedMsg = &processedMsgBuffer;
        }
        busy_sending = FALSE;
        state = STATE_INIT;
        return SUCCESS;
    }

    command error_t StdControl.stop()
    {
        busy_sending = FALSE;
        state = STATE_INIT;
        call Timer.stop();
        return SUCCESS;
    }

    async command float     TimeSyncInfo.getSkew() { return skew; }
    async command uint32_t  TimeSyncInfo.getOffset() { return offsetAverage; }
    async command uint32_t  TimeSyncInfo.getSyncPoint() { return localAverage; }
    async command uint16_t  TimeSyncInfo.getRootID() { return outgoingMsg->rootID; }
    async command uint8_t   TimeSyncInfo.getSeqNum() { return outgoingMsg->seqNum; }
    async command uint8_t   TimeSyncInfo.getNumEntries() { return numEntries; }
    async command uint8_t   TimeSyncInfo.getHeartBeats() { return 0; }

    event void tdmaMacParams.receive_status(uint16_t status_flag) {
    }
}
