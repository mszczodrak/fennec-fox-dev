#include <Fennec.h>

interface FennecData {


command void load(void* pkt);
command void update(void* pkt);

command void* getNxDataPtr();
command uint16_t getNxDataLen();
command uint16_t getDataCrc();

command void checkDataSeq(uint8_t msg_type);

event void updated();
event void resend();
	
}
