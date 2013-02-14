#include "Fennec.h"
#include "ff_caches.h"
#include "ff_defaults.h"


module ProtocolStackP {
provides interface Mgmt;

uses interface Mgmt as FennecEngine;

}

implementation {


command error_t Mgmt.start() {
	return call FennecEngine.start();
}

command error_t Mgmt.stop() {
	return call FennecEngine.stop();
}

event void FennecEngine.startDone(error_t error) {
	signal Mgmt.startDone(error);
}


event void FennecEngine.stopDone(error_t error) {
	signal Mgmt.stopDone(error);
}



/*

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

*/



}
