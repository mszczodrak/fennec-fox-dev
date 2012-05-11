#ifndef TEST_SERIAL_H
#define TEST_SERIAL_H

#define EXTRA_SIZE 0

nx_struct serial_pkt {
  nx_uint16_t counter;
};

enum {
  AM_SERIAL_PKT = 100,
};

#endif
