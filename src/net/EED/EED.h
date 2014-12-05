#ifndef __EED_H_
#define __EED_H_

nx_struct EED_header {
	nx_uint16_t crc;
	nx_uint32_t left;
};

nx_struct EED_footer {
	nx_uint32_t left;
};

#endif
