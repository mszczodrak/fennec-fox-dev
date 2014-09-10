#include <Fennec.h>

interface FennecData {
	command uint16_t getDataSeq();
	command error_t getDataHist(nx_uint8_t *history, uint8_t len);
	command error_t getNxData(nx_struct global_data_msg *ptr);
	command error_t setDataHistSeq(nx_struct global_data_msg* data, nx_uint8_t* history, uint16_t seq);
	command void syncNetwork();
	event void resend();
}
