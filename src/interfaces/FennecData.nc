#include <Fennec.h>

interface FennecData {

command nx_uint8_t getDataSeq();
command void* getNxDataPtr();
command uint16_t getNxDataLen();

command void* getHistory();
command uint8_t fillNxDataUpdate(void *ptr, uint8_t max_size);

command void updateData(void* data, uint8_t len, nx_uint8_t* history, nx_uint16_t seq);

event void resend(bool immediate);
event void dump();
	
}
