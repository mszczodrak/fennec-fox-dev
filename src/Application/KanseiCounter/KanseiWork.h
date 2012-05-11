#ifndef __KANSEI_WORKS_
#define __KANSEI_WORKS_

enum {
	K_DATA_LENGTH	= 4,


	K_SEND		= 1,
	K_RECEIVE	= 2,
	K_TIMER_FIRED	= 3,

};


nx_struct kansei_msg {
	nx_uint8_t layer;
	nx_uint16_t data[K_DATA_LENGTH];	
};



#endif
