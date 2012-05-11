/* Swift Fox generated code for Fennec Fox CachesM module */

#include "caches.h"
#include <Fennec.h>

module CachesP @safe() {
  provides interface SimpleStart;
  provides interface EventCache;
  provides interface PolicyCache;
}

implementation {

  command void SimpleStart.start() {
    signal SimpleStart.startDone(SUCCESS);
  }

  command struct fennec_event *EventCache.getEntry(uint8_t ev) {
    return &eventsTable[--ev];
  }

  module_t get_protocol(layer_t layer, conf_t conf) {

    if (conf == POLICY_CONFIGURATION) {
      if (layer == F_NETWORK) return conf;
      conf = active_state;
    }

    if (conf >= NUMBER_OF_CONFIGURATIONS) {
      return UNKNOWN_LAYER;
    }

    switch(layer) {

      case F_APPLICATION:
        return configurations[ conf ].application;

      case F_NETWORK:
        return configurations[ conf ].network;

      case F_MAC:
        return configurations[ conf ].mac;

      case F_RADIO:
        return configurations[ conf ].radio;

      default:
        return UNKNOWN_LAYER;
    }
  }

  module_t get_next_module(module_t module_id, uint8_t flag) @C() {
    conf_t conf_id = get_conf_id();
    module_t next_module_id = UNKNOWN_ID;
    uint16_t temp_id;
    if (module_id == POLICY_CONFIGURATION) return POLICY_CONFIGURATION;
    temp_id = configurations[conf_id].application;
    if ((temp_id < next_module_id) && (temp_id > module_id)) next_module_id = temp_id;
    temp_id = configurations[conf_id].network;
    if ((temp_id < next_module_id) && (temp_id > module_id)) next_module_id = temp_id;
    temp_id = configurations[conf_id].mac;
    if ((temp_id < next_module_id) && (temp_id > module_id)) next_module_id = temp_id;
    temp_id = configurations[conf_id].radio;
    if ((temp_id < next_module_id) && (temp_id > module_id)) next_module_id = temp_id;
    return next_module_id;
  }

  command error_t PolicyCache.set_active_configuration(conf_t new_state) {
    atomic active_state = new_state;
    return SUCCESS;
  }

  command uint16_t PolicyCache.get_number_of_configurations() {
    return NUMBER_OF_CONFIGURATIONS;
  }

  command void PolicyCache.control_unit_support(bool status) {
    control_unit_support = status;  
  }

  command bool PolicyCache.valid_policy_msg(nx_struct FFControl *policy_msg) {
    if (policy_msg->conf_id >= NUMBER_OF_CONFIGURATIONS)
      return FALSE;
    return TRUE;
  }

  command uint8_t PolicyCache.add_accepts(nx_struct FFControl *conf) {
    return 1;
  }

  task void wrong_conf() {
    signal PolicyCache.wrong_conf();
  }

  module_t get_module_id(state_t state_id, conf_t conf_id, layer_t layer_id) @C() {
    return get_protocol(layer_id, conf_id);
  }

  conf_t get_conf_id() @C() {
    return get_state_id();
  }

  state_t get_state_id() @C() {
    return active_state;
  }

  command void EventCache.clearMask() {
    event_mask = 0;
  }

  command void EventCache.setBit(uint16_t bit) {
    event_mask |= (1 << (bit - 1));
    checkEvent();
  }

  command void EventCache.clearBit(uint16_t bit) {
    event_mask &= ~(1 << (bit - 1));
    checkEvent();
  }

  command bool EventCache.eventStatus(uint16_t event_num) {
    return eventStatus(event_num);
  }

}
