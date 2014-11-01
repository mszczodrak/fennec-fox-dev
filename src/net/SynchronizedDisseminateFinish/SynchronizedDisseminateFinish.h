#ifndef __SynchronizedDisseminateFinish_H_
#define __SynchronizedDisseminateFinish_H_

nx_struct SDF_header {
	nx_uint32_t left;
	nx_uint16_t crc;
};

nx_struct SDF_footer {
	nx_uint32_t offset;
};

#endif
