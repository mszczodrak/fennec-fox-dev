#ifndef __DEBUG_SERIAL_H
#define __DEBUG_SERIAL_H

nx_struct debug_msg {
  nx_uint8_t layer;
  nx_uint8_t state;
  nx_uint16_t action;
  nx_uint16_t d0;
  nx_uint16_t d1;
};

enum {
  AM_DEBUG_MSG = 100,
  DBG_BUFFER_SIZE  = 250,	
};

#endif
