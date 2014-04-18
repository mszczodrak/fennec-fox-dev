#include <Fennec.h>
#include "sdrpNet.h"

// Spaially Distributed Routing Protocol

module sdrpNetP {
  provides interface SplitControl;
  provides interface NetworkSend;
  provides interface NetworkReceive;

  uses interface MacCall;
  uses interface MacSignal;

  uses interface FennecStatus;

  uses interface Timer<TMilli> as Timer0;
  uses interface Random;
  uses interface Leds;
}

implementation {

/* Function signatures */
  /* processes arriving discover message */
  void process_discover_msg(msg_t *msg, uint8_t *payload, uint8_t len);

  /* processes arriving bridge_reply message */
  void process_bridge_reply_msg(msg_t *msg, uint8_t *payload, uint8_t len);

  /* processes arriving bridge_reply_failed message */
  void process_bridge_reply_failed_msg(msg_t *msg, uint8_t *payload, uint8_t len);

  /* process arriving pre check message */
  void process_pre_check_msg(msg_t *msg, uint8_t *payload, uint8_t len);

  /* processes arriving data msg */
  void process_data_msg(msg_t *msg, uint8_t *payload, uint8_t len);

  /* forwards message */
  void forward(msg_t *msg, uint8_t *payload, uint8_t len);

  /* returns link cost of a arriving message msg */
  uint16_t get_link_cost(msg_t *msg, uint8_t *payload, uint8_t len);

  /* retrieves cost to addr */
  uint16_t get_cost_to_data();

  /* returns next hop to data source */
  uint16_t get_next_to_data();

  /* returns data source */
  uint16_t get_data_src();

  /* returns next hop to bridge destination */
  uint16_t get_next_to_bridge();

  /* returns bridge destination */
  uint16_t get_bridge_dest();

  /* sends discover message */
  task void send_discover();

  /* sends bridge reply message */
  task void send_bridge_reply();

  /* sends bridge reply fail message */
  task void send_bridge_reply_failed();

  /* sends pre check message */
  task void send_pre_check();

  /* sets new cost to addr to be new_cost */
  void save_data_discovery(uint16_t for_id, uint16_t addr, uint16_t new_cost, uint16_t next_hop);

  /* insert information about pre check message */
  void pre_check_insert(uint16_t addr);

  /* saves bridge reply data in sdrp_list */
  error_t save_to_sdrp_list( sdrp_discover_t *header );

  /* removes path from list */
  void remove_path(sdrp_discover_t *header);


  /* temporary data used by discovery */
  uint8_t id;			/* discovery id */
  uint16_t data_src; 	 	/* Data source, the one that sends Discover msg */
  uint16_t cost_to_data;	/* Cost of path to Data source */
  uint16_t next_to_data; 	/* Next node on the path to data */

  uint8_t sdrp_state = S_STOPPED;
  uint8_t sdrp_seq;
  uint8_t link_cost_metric;

  /* use onle when pre_check enabled */
  struct pre_check_entry pre_check_list[PRE_CHECK_SIZE];
  uint8_t pre_check_counter;

  /* store information about found p2p paths */
  struct p2p_t sdrp_paths_list[SDRP_MAX_PATHS];
  uint8_t sdrp_paths_counter;

  command error_t SplitControl.start() {
    uint8_t i;

#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 0, 0, 0, 0, 0);
#endif

    id = 0;
    data_src = UNKNOWN;
    cost_to_data = UNKNOWN;
    next_to_data = UNKNOWN;

    dbg("Network", "SDRP is starting\n");

    /* pre check section */
    for(i = 0; i < PRE_CHECK_SIZE; i++) {
      pre_check_list[i].addr = UNKNOWN;
      pre_check_list[i].value = 0;
    }
    pre_check_counter = 0;

    /* p2p list */
    for(i = 0; i < SDRP_MAX_PATHS; i++) {
      sdrp_paths_list[i].id = 0;
      sdrp_paths_list[i].data_src = UNKNOWN;
      sdrp_paths_list[i].bridge = UNKNOWN;
      sdrp_paths_list[i].next_to_data = UNKNOWN;
      sdrp_paths_list[i].next_to_bridge = UNKNOWN;
      sdrp_paths_list[i].cost = UNKNOWN;
      sdrp_paths_list[i].usage = 0;
    }
    sdrp_paths_counter = 0;

    sdrp_state = S_STARTED;

    link_cost_metric = SIMPLE_LQI;
    //link_cost_metric = PRE_CHECK;

    switch(link_cost_metric){
      case PRE_CHECK:
        sdrp_state = S_STARTING;
        post send_pre_check();
        break;

      default:
        dbg("Network", "SDRP: start done\n");
        signal SplitControl.startDone(SUCCESS);
    }
    
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 99, 0, 0, 0, 0);
#endif

    call Timer0.stop();
    sdrp_state = S_STOPPED;
    signal SplitControl.stopDone(SUCCESS);
    return SUCCESS;
  }

  event void FennecStatus.update(uint8_t flag, bool status) {
    if ((sdrp_state == S_STOPPED) || (status == OFF)) return;

    switch(flag) {
      case F_BRIDGING:
        dbg("Network", "SDRP: I'm a bridge\n");
	break;

      case F_DATA_SRC:
        dbg("Network", "SDRP: I'm data source\n");
        data_src = TOS_NODE_ID;
	id++;
        cost_to_data = 0;
        call Timer0.startOneShot(INITIAL_DISCOVERY_DELAY);
        break;
    }
  }

  command void* NetworkSend.getPayload(msg_t* message) {
    sdrp_header_t* header = (sdrp_header_t*) call MacCall.getPayload(message);
    return header->payload;
  }

  command error_t NetworkSend.send(msg_t *msg) {
    sdrp_header_t *header = (sdrp_header_t*) call MacCall.getPayload(msg);
   
    dbg("Network", "SDRP : got a message from Application to send\n");

    header->flags = SDRP_DATA;
    header->destination = msg->next_hop;
    
    msg->next_hop = get_next_to_bridge();

    if (msg->next_hop == UNKNOWN) {
      dbg("Network", "SDRP : unknown next hop, FAILs\n");
      signal NetworkSend.sendDone(msg, FAIL);
      return FAIL;
    }

    msg->len += sizeof(sdrp_header_t);

    if (call MacCall.send(msg) != SUCCESS) {
      dbg("Network", "SDRP: failed to send application a message\n");
      signal NetworkSend.sendDone(msg, FAIL);
      return FAIL;
    }

#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 1, msg->next_hop, 0, 0, 0);
#endif
    return SUCCESS;
  }

  command uint8_t NetworkSend.getMaxSize() {
    return (call MacCall.getMaxSize() - sizeof(sdrp_header_t));
  }

  event void MacSignal.sendDone(msg_t *msg, error_t err) {
    sdrp_discover_t *header = (sdrp_discover_t*) call MacCall.getPayload(msg);

    dbg("Network", "SDRP got send done\n");

    switch(header->flags) {
      case SDRP_DISCOVER:
        dbg("Network", "SDRP: Send done: DISCOVER\n");
        drop_message(msg);
        break;

      case SDRP_BRIDGE_REPLY:
        dbg("Network", "SDRP: Send done: BRIDGE_REPLY\n");
        drop_message(msg);
        break;

      case SDRP_PRE_CHECK:
        dbg("Network", "SDRP: Send done: PRE_CHECK\n");
        drop_message(msg);
        call Timer0.startOneShot(call Random.rand16() % (PRE_CHECK_DELAY / 2) + (PRE_CHECK_DELAY/2));

        break;

      case SDRP_BRIDGE_REPLY_FAILED:
        remove_path(header);
        drop_message(msg);
        break;

      case SDRP_DATA:
        dbg("Network", "SDRP: Send done: SDRP_DATA\n");
        signal NetworkSend.sendDone(msg, err);
        break;

      default:
        dbg("Network", "SDRP: Error send done unknown message\n");
        drop_message(msg);
    }
  }

  event void MacSignal.receive(msg_t *msg, uint8_t *payload, uint8_t len) {
    sdrp_header_t *header = (sdrp_header_t*) payload;


    switch(header->flags) {
      case SDRP_DISCOVER:
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 2, 1, 0, 0, 0);
#endif
        process_discover_msg(msg, payload, len);
        break;

      case SDRP_BRIDGE_REPLY:
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 2, 2, 0, 0, 0);
#endif
        process_bridge_reply_msg(msg, payload, len);
        break;

      case SDRP_BRIDGE_REPLY_FAILED:
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 2, 3, 0, 0, 0);
#endif
        process_bridge_reply_failed_msg(msg, payload, len);
        break;

      case SDRP_PRE_CHECK:
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 2, 4, 0, 0, 0);
#endif
        process_pre_check_msg(msg, payload, len);
        break;

      case SDRP_DATA:
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 2, 5, 0, 0, 0);
#endif
        process_data_msg(msg, payload, len);
        break;

      default:
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 2, 6, 0, 0, 0);
#endif

        dbg("Network", "SDRP: Error drop_message unknown message\n");
        drop_message(msg);
    }
  }

  event void Timer0.fired() {
    switch(sdrp_state) {

      case S_STARTED:
        if (data_src == TOS_NODE_ID) {
          post send_discover();
          sdrp_state = S_DISCOVER_DELAY;
        }
        break;

      case S_BRIDGE_DELAY:
        // send reply
	if (sdrp_paths_counter < SDRP_MAX_PATHS) {
          sdrp_state = S_STARTED;
          sdrp_paths_list[sdrp_paths_counter].id = id;
          sdrp_paths_list[sdrp_paths_counter].data_src = data_src;
          sdrp_paths_list[sdrp_paths_counter].bridge = TOS_NODE_ID;
          sdrp_paths_list[sdrp_paths_counter].next_to_data = next_to_data;
          sdrp_paths_list[sdrp_paths_counter].next_to_bridge = TOS_NODE_ID;
          sdrp_paths_list[sdrp_paths_counter].cost = cost_to_data;
          sdrp_paths_list[sdrp_paths_counter].usage = 0;
          sdrp_paths_counter++;
          post send_bridge_reply();
          dbg("Network", "SDRP: Bridge delay is done\n");
        }
        break;
   
      case S_DISCOVER_DELAY:
        sdrp_state = S_STARTED;
        //dbg("Network", "SDRP: Data Src resends discovery\n");
        post send_discover();
        break;

      case S_STARTING:
        pre_check_counter++;
        if (pre_check_counter < PRE_CHECK_REPEAT) {
          post send_pre_check();
        } else {
          call Timer0.stop();
          sdrp_state = S_STARTED;
          dbg("Network", "SDRP: start done: finished sending prechecks\n");
          signal SplitControl.startDone(SUCCESS);
        }
        break;

      default:
        dbg("Network", "SDRP: Timer fired, why I'm default?\n");

    }
  }



  /* Functions */



  task void send_discover() 
  {
    msg_t *m = nextMessage();
    sdrp_discover_t *header;

#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 3, 0, 0, 0, 0);
#endif


    if (m == NULL) {
      dbg("Network", "SDRP: Can't send discover, no more msg memory\n");
      return;
    }
   
    header = (sdrp_discover_t*) call MacCall.getPayload(m);
    header->flags = SDRP_DISCOVER;
    header->id = id;
    header->discover = data_src;
    header->bridge = UNKNOWN;
    header->cost = cost_to_data;
    header->last = TOS_NODE_ID;

    m->next_hop = BROADCAST;
    m->len = sizeof(sdrp_discover_t);

    if ((call MacCall.send(m)) != SUCCESS) {
      dbg("Network", "SDRP: Failed to send discover\n");
      sdrp_state = S_DISCOVER_DELAY;
      call Timer0.startOneShot(DISCOVER_DELAY / 2);
      drop_message(m);
    } else {
      dbg("Network", "SDRP: send discover\n");
    }
  }

  task void send_bridge_reply()
  {
    msg_t *m = nextMessage();
    sdrp_discover_t *header;

    if (m == NULL) {
      dbg("Network", "SDRP: Can't send bridge reply, no more msg memory\n");
      return;
    }

    header = (sdrp_discover_t*) call MacCall.getPayload(m);
    header->flags = SDRP_BRIDGE_REPLY;
    header->id = sdrp_paths_list[sdrp_paths_counter-1].id;
    header->discover = get_data_src();
    header->bridge = get_bridge_dest(); 
    dbg("Network", "SDRP: Bridge rep send with cost %d\n", get_cost_to_data());
    header->cost = get_cost_to_data();
    header->last = TOS_NODE_ID; 

    m->next_hop = get_next_to_data(); 
    m->len = sizeof(sdrp_discover_t);

    dbg("Network", "SDRP: Bridge reply send from %d to %d\n", TOS_NODE_ID, m->next_hop);

    if ((call MacCall.send(m)) != SUCCESS) {
      dbg("Network", "SDRP: Failed to send bridge reply\n");
      /* we don't retry since if it failed, that this is not a good link */
      drop_message(m);
      post send_bridge_reply_failed();
    } else {
      dbg("Network", "SDRP: send bridge reply\n");
    }
  }

  task void send_bridge_reply_failed()
  {
    msg_t *m = nextMessage();
    sdrp_discover_t *header;

    if (m == NULL) {
      dbg("Network", "Can't send bridge reply failed, no more msg memory\n");
      return;
    }

    header = (sdrp_discover_t*) call MacCall.getPayload(m);
    header->flags = SDRP_BRIDGE_REPLY_FAILED;
    header->id = sdrp_paths_list[sdrp_paths_counter-1].id;
    header->discover = get_data_src();
    header->bridge = get_bridge_dest();
    header->cost = get_cost_to_data();
    header->last = TOS_NODE_ID;

    m->next_hop = get_next_to_bridge();
    m->len = sizeof(sdrp_discover_t);

    dbg("Network", "Bridge failed reply send from %d to %d\n", TOS_NODE_ID, m->next_hop);

    if (getFennecStatus(F_BRIDGING)) {
      remove_path(header);
      drop_message(m);
      return;
    }

    if ((call MacCall.send(m)) != SUCCESS) {
      dbg("Network", "Failed to send bridge failed reply\n");
      drop_message(m);
      post send_bridge_reply();
    } 
  }


  task void send_pre_check()
  {
    msg_t *m = nextMessage();
    sdrp_discover_t *header;

    if (m == NULL) {
      dbg("Network", "SDRP: Can't send pre check, no more msg memory\n");
      return;
    } 

    header = (sdrp_discover_t*) call MacCall.getPayload(m);
    header->flags = SDRP_PRE_CHECK;
    header->last = TOS_NODE_ID;
    m->len = sizeof(sdrp_discover_t);
    m->next_hop = BROADCAST;

    if ((call MacCall.send(m)) != SUCCESS) {
      dbg("Network", "SDRP: Failed to send pre-check\n");
      drop_message(m);
    } else {
      dbg("Network", "SDRP: send pre-check\n");
    }
  }

  void process_discover_msg(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    sdrp_discover_t *header = (sdrp_discover_t*)payload;
    uint16_t new_cost = get_link_cost(msg, payload, len) + header->cost;

    dbg("Network", "SDRP drop_message discover msg\n");

    if ((new_cost < cost_to_data) || (id < header->id)) {
      if (getFennecStatus( F_BRIDGING )) {
        if (sdrp_paths_counter < SDRP_BRIDGE_MAX_PATHS) {
          dbg("Network", "Bridge drop_message discover message %d\n", header->id);
          dbg("Network", "Saving id: %d, disc %d, cost %d, last %d\n", header->id, header->discover, new_cost, header->last);
          save_data_discovery(header->id, header->discover, new_cost, header->last);
          sdrp_state = S_BRIDGE_DELAY;
          call Timer0.startOneShot((call Random.rand16() % (BRIDGE_DELAY * 4)) + (BRIDGE_DELAY/2));
        }
      } else {
        if (sdrp_paths_counter == 0) {
          save_data_discovery(header->id, header->discover, new_cost, header->last);
          //dbg("Network", "Node %d drop_message discover message %d, forwards\n", TOS_NODE_ID, header->id);
          post send_discover();
          sdrp_state = S_DISCOVER_DELAY;
          call Timer0.startOneShot((call Random.rand16() % (DISCOVER_DELAY * 4)) + (DISCOVER_DELAY/2));
        } 
        
      }
    } else {
      if ((id == header->id) && (header->cost > get_link_cost(msg, payload, len) + cost_to_data) 
        					&& !getFennecStatus( F_BRIDGING )) { 
          post send_discover();
      }
    }
    drop_message(msg);
  }

  void process_bridge_reply_msg(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    sdrp_discover_t *header = (sdrp_discover_t*)payload;

    dbg("Network", "SDRP drop_message bridge reply msg\n");

    if (getFennecStatus( F_DATA_SRC )) {
      dbg("Network", "Data Source drop_message bridge reply message\n");
      /* send another discovery */
      if (save_to_sdrp_list(header) == SUCCESS) {
        /* Let's try to send another discover message */
        dbg("Network", "Found new valid path so let's try again\n");
        id++;
        post send_discover();
      } else {
        dbg("Network", "Found some path, but that's all folks for now\n");
        call MacCall.ack();  /* in TOSSIM creates segmentation faul */
      }

    } else {
      if (save_to_sdrp_list(header) == SUCCESS) {
        call Leds.led1On();
        dbg("Network", "Node %d drop_message bridge reply message, forwards\n", TOS_NODE_ID);
        post send_bridge_reply();
      } else {
        call MacCall.ack();
      }
    }
    drop_message(msg);
  }

  void process_bridge_reply_failed_msg(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    sdrp_discover_t *header = (sdrp_discover_t*)payload;

    dbg("Network", "SDRP drop_message bridge reply failed msg\n");

    if (getFennecStatus( F_BRIDGING)) {
      remove_path(header);
    } else {
      post send_bridge_reply_failed();
    }
  }

  void process_pre_check_msg(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    sdrp_discover_t *header = (sdrp_discover_t*)payload;

    dbg("Network", "SDRP drop_message pre_check msg\n");

    pre_check_insert(header->last);
    drop_message(msg);
  }

  void process_data_msg(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    sdrp_header_t *header = (sdrp_header_t*) payload;

    dbg("Network", "SDRP drop_message data msg\n");

    if (getFennecStatus( F_BRIDGING) ) {
      dbg("Network", "Bridge drop_message data message\n");
      /* OK, I'm a bridge, so do something about it */
      msg->len -= sizeof(sdrp_header_t);
      signal NetworkReceive.receive(msg, (uint8_t*)header->payload, msg->len);
      call MacCall.ack();
    } else {
      forward(msg, payload, len);
    }
  }

  uint16_t get_link_cost(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    sdrp_discover_t *header = (sdrp_discover_t*)payload;
    uint8_t i;

    switch(link_cost_metric) {
      case JUST_ONE:
        return 1;

      case SIMPLE_LQI:
        if (msg->lqi < SDRP_MIN_LQI) {
          return SDRP_MAX_COST;
        } else {
          return 1;
        }

      case PRE_CHECK:
        for(i = 0; i < PRE_CHECK_SIZE; i++) {
          if (pre_check_list[i].addr == header->last) {
            return PRE_CHECK_REPEAT - pre_check_list[i].value + 1;
          }
        }
        return PRE_CHECK_REPEAT + 1;
    }

    return SDRP_MAX_COST;
  }

  void save_data_discovery(uint16_t new_id, uint16_t addr, uint16_t new_cost, uint16_t next_hop)
  {
    id = new_id;
    data_src = addr;
    cost_to_data = new_cost;
    next_to_data = next_hop;
  }

  void forward(msg_t *msg, uint8_t *payload, uint8_t len)
  {
    msg->next_hop = get_next_to_bridge();
    if (msg->next_hop != UNKNOWN) {
#ifdef FENNEC_DBG
    serialSend(F_NETWORK, 4, msg->next_hop, 0, 0, 0);
#endif
      dbg("Network", "SDRP: sends next message next hop to %d\n", msg->next_hop);
      if (call MacCall.send(msg) == SUCCESS) {
        return;
      }
    }
    drop_message(msg);
  }

  uint16_t get_cost_to_data()
  {
    if (sdrp_paths_counter > 0) {
      return sdrp_paths_list[sdrp_paths_counter-1].cost;
    } else {
      return UNKNOWN;
    }
  }

  uint16_t get_next_to_data()
  {
    if (sdrp_paths_counter > 0) {
      return sdrp_paths_list[sdrp_paths_counter-1].next_to_data;
    } else {
      return UNKNOWN;
    }
  }

  uint16_t get_next_to_bridge()
  {
    uint8_t entry = 0;
    uint32_t min;
    uint8_t i = 0;

    if (!sdrp_paths_counter) return UNKNOWN;

    min = sdrp_paths_list[i].usage;
    
    for(i = 1; i < sdrp_paths_counter; i++) {
      if (min > sdrp_paths_list[i].usage) {
         min = sdrp_paths_list[i].usage;
         entry = i;
      }
    }

    sdrp_paths_list[entry].usage += sdrp_paths_list[entry].cost;
    return sdrp_paths_list[entry].next_to_bridge;
  }

  uint16_t get_data_src()
  {
    if (sdrp_paths_counter > 0) {
      return sdrp_paths_list[sdrp_paths_counter-1].data_src;
    } else {
      return UNKNOWN;
    }
  } 

  uint16_t get_bridge_dest()
  {
    if (sdrp_paths_counter > 0) {
      return sdrp_paths_list[sdrp_paths_counter-1].bridge;
    } else {
      return UNKNOWN;
    }
  }

  void pre_check_insert(uint16_t addr)
  {
    uint8_t i;

    for(i = 0; i < PRE_CHECK_SIZE; i++) {
      if (pre_check_list[i].addr == addr) {
        pre_check_list[i].value++;
        return;
      }
    }

    for(i = 0; i < PRE_CHECK_SIZE; i++) {
      if (pre_check_list[i].addr == UNKNOWN) {
        pre_check_list[i].addr = addr;
        pre_check_list[i].value = 1;
        return;
      }
    }
  }

  error_t save_to_sdrp_list( sdrp_discover_t *header )
  {
    uint8_t i;
    if (!(getFennecStatus(F_BRIDGING) || getFennecStatus(F_DATA_SRC))) {
      if (sdrp_paths_counter > 0) {
	/* non bridge and non data src can be on maximum one path */
        return FAIL;
      }
    } 

    if (sdrp_paths_counter <  SDRP_MAX_PATHS) {

      for(i = 0; i < sdrp_paths_counter; i++) {
        if (sdrp_paths_list[i].next_to_bridge == header->last) {
          /* this next hop is taken, so can't use */
          return FAIL;
        }
      }

      dbg("Network", "PATH: Saving new path: id %d, next_to_data %d, next_to_bridge %d, cost %d\n",
       header->id, next_to_data, header->last, header->cost);

      sdrp_paths_list[sdrp_paths_counter].id = header->id;
      sdrp_paths_list[sdrp_paths_counter].data_src = header->discover;
      sdrp_paths_list[sdrp_paths_counter].bridge = header->bridge;
      sdrp_paths_list[sdrp_paths_counter].next_to_data = next_to_data;
      sdrp_paths_list[sdrp_paths_counter].next_to_bridge = header->last;
      sdrp_paths_list[sdrp_paths_counter].cost = header->cost;
      sdrp_paths_list[sdrp_paths_counter].usage = 0;
      sdrp_paths_counter++;
    }
  
    if (sdrp_paths_counter < SDRP_MAX_PATHS) {
      return SUCCESS;
    } else {
      return FAIL;
    }
  }

  void remove_path( sdrp_discover_t *header )
  {
    uint8_t i;

    /* Find the path */
    for(i = 0; i < sdrp_paths_counter; i++) {
      if ((sdrp_paths_list[i].bridge == header->bridge) && 
         (sdrp_paths_list[i].data_src == header->discover) && 
         (sdrp_paths_list[i].id == header->id)) {
         break;
      }
    }

    /* move the rest to the new place */
    for(; (i < sdrp_paths_counter) && (i + 1 < SDRP_MAX_PATHS); i++) {
      if (sdrp_paths_list[i].data_src != UNKNOWN) {
        sdrp_paths_list[i].id = sdrp_paths_list[i+1].id;
        sdrp_paths_list[i].data_src = sdrp_paths_list[i+1].data_src;
        sdrp_paths_list[i].bridge = sdrp_paths_list[i+1].bridge;
        sdrp_paths_list[i].next_to_data = sdrp_paths_list[i+1].next_to_data;
        sdrp_paths_list[i].next_to_bridge = sdrp_paths_list[i+1].next_to_bridge;
        sdrp_paths_list[i].cost = sdrp_paths_list[i+1].cost;
        sdrp_paths_list[i].usage = sdrp_paths_list[i+1].usage;
      }
    }

    sdrp_paths_list[i].id = 0;
    sdrp_paths_list[i].data_src = UNKNOWN;
    sdrp_paths_list[i].bridge = UNKNOWN;
    sdrp_paths_list[i].next_to_data = UNKNOWN;
    sdrp_paths_list[i].next_to_bridge = UNKNOWN;
    sdrp_paths_list[i].cost = UNKNOWN;
    sdrp_paths_list[i].usage = 0;
  }
}
