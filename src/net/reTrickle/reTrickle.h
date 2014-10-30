#ifndef __reTrickle_H_
#define __reTrickle_H_

nx_struct reTrickle_header {
        nx_uint8_t repeat;
	nx_uint16_t crc;
	nx_uint32_t left;
};

nx_struct reTrickle_footer {
	nx_uint32_t offset;
};

#endif
