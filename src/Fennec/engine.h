#ifndef __FF__ENGINE_H_
#define __FF__ENGINE_H_

#include "Fennec.h"
#include "ff_caches.h"
#include "ff_defaults.h"

uint8_t active_layer = UNKNOWN_LAYER;
uint8_t ctrl_turn;

void next_layer();
uint16_t next_module();
void ctrl_module(uint16_t module_id, uint8_t ctrl);
void ctrl_module_done(uint8_t status);
uint8_t ctrl_conf(uint16_t conf_id, uint8_t ctrl);
void ctrl_conf_done(uint8_t status, uint8_t ctrl);
uint8_t ctrl_state(uint8_t ctrl);
void ctrl_state_done(uint8_t status, uint8_t ctrl);
void copy_default_params(uint16_t conf_id);

void next_layer() {
  if (ctrl_turn == ON) {
    if (active_layer == F_APPLICATION) active_layer = UNKNOWN_LAYER; 
    if (active_layer == F_NETWORK) active_layer = F_APPLICATION; 
    if (active_layer == F_MAC) active_layer = F_NETWORK; 
    if (active_layer == F_RADIO) active_layer = F_MAC; 
  } else {
    if (active_layer == F_RADIO) active_layer = UNKNOWN_LAYER; 
    if (active_layer == F_MAC) active_layer = F_RADIO; 
    if (active_layer == F_NETWORK) active_layer = F_MAC; 
    if (active_layer == F_APPLICATION) active_layer = F_NETWORK; 
  }
}

uint16_t next_module() {
  switch(active_layer) {
    case F_APPLICATION:
      return configurations[active_state].application;
    case F_NETWORK:
      return configurations[active_state].network;
    case F_MAC:
      return configurations[active_state].mac;
    case F_RADIO:
      return configurations[active_state].radio;
  }
  return UNKNOWN;
}

void ctrl_module_done(uint8_t status) {
  if (status) {
    ctrl_module(next_module(), ctrl_turn);
  } else {
    next_layer();
    //dbg("FennecEngine", "Done, next layer is %d\n", active_layer);
    if (active_layer == UNKNOWN_LAYER) {
      ctrl_conf_done(0, ctrl_turn);
    } else {
      ctrl_module(next_module(), ctrl_turn);
    }
  }
}

uint8_t ctrl_conf(uint16_t conf_id, uint8_t ctrl) {
  if (ctrl_turn == ON) {
    //dbg("FennecEngine", "Start conf %d\n", conf_id);
    copy_default_params(conf_id);
    active_layer = F_RADIO;
  } else {
    //dbg("FennecEngine", "Stop conf %d\n", conf_id);
    active_layer = F_APPLICATION;
  }
  ctrl_module(next_module(), ctrl_turn);
  return 0;
}

void ctrl_conf_done(uint8_t status, uint8_t ctrl) {
  ctrl_state_done(status, ctrl);
}

uint8_t ctrl_state(uint8_t ctrl) {
  ctrl_turn = ctrl;
  return ctrl_conf(active_state, ctrl);
}

void copy_default_params(uint16_t conf_id) {
        //dbg("FennecEngine", "Copying Default Params\n");
	memcpy(	defaults[conf_id].application_cache, 
		defaults[conf_id].application_default_params,
		defaults[conf_id].application_default_size);

	memcpy(	defaults[conf_id].network_cache, 
		defaults[conf_id].network_default_params,
		defaults[conf_id].network_default_size);

	memcpy(	defaults[conf_id].mac_cache, 
		defaults[conf_id].mac_default_params,
		defaults[conf_id].mac_default_size);
		
	memcpy(	defaults[conf_id].radio_cache, 
		defaults[conf_id].radio_default_params,
		defaults[conf_id].radio_default_size);
}

#endif
