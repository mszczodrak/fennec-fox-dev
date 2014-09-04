#include <Fennec.h>

interface FennecData {
	command void* getData();
	command void* getNxData();
	command uint16_t getDataSeq();
	command error_t setDataAndSeq(nx_struct global_data_msg* data, uint16_t seq);
	command void syncNetwork();
	event void resend();
}
