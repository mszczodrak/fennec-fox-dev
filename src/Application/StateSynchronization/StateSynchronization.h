#ifndef STATE_SYNCHRONIZATION_APP_H
#define STATE_SYNCHRONIZATION_APP_H

nx_struct fennec_network_state {
	nx_uint16_t seq;
	nx_uint16_t state_id;
	nx_uint16_t crc;
};

#endif
