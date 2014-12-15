#ifndef __EED_H_
#define __EED_H_

#define SUPPRESS_BROADCAST	1

nx_struct EED_header {
	nx_uint16_t crc;
	nx_uint32_t now;
	nx_uint32_t end;
	nx_int32_t left;
};

nx_struct EED_footer {
	nx_uint32_t left;
};

#endif
