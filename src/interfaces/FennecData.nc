#include <Fennec.h>

interface FennecData {


command void loadDataMsg(void* pkt);
command void networkUpdate(void* pkt);

command void* getNxDataPtr();
command uint16_t getNxDataLen();
command uint16_t getDataCrc();

command void* getHistory();
command uint8_t fillNxDataUpdate(void *ptr, uint8_t max_size);

command void updateData(void* in_data, uint8_t in_data_len, 
	uint16_t in_data_crc, nx_uint8_t* history, uint8_t in_seq);

command void checkDataSeq(uint8_t msg_type);

event void updated();
	
}
