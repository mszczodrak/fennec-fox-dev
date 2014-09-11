#include <Fennec.h>

interface FennecData {
	command uint16_t getDataSeq();
	command error_t fillDataHist(void *history, uint8_t len);
	command uint8_t fillNxDataUpdate(void *ptr, uint8_t max_size);

	command error_t setDataHistSeq(nx_struct global_data_msg* data, nx_uint8_t* history, uint16_t seq);
	command void syncNetwork();

	command void* getNxDataPtr();
	command uint16_t getNxDataLen();
	event void resend();
	event void dump();
	
}
