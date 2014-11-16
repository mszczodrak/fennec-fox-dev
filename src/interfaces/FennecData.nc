#include <Fennec.h>

interface FennecData {


command void load(void* pkt);
command void update(void* pkt, uint8_t global_id);

command void* getNxDataPtr();
command uint16_t getNxDataLen();
command uint16_t getDataCrc();
command uint8_t getNumOfGlobals();

command void checkDataSeq(uint8_t msg_type);

event void updated(uint8_t global_id, uint8_t var_index);
event void resend();
	
}
