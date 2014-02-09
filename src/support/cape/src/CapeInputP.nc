generic module CapeInputP() {
provides interface Read<uint16_t> as Read16[uint8_t id];
//provides interface Read<uint32_t> as Read32[uint8_t id];
}

implementation {

norace uint8_t reader_id;

task void do_read() {
	signal Read16.readDone[reader_id](SUCCESS, 17);
}


command error_t Read16.read[uint8_t id]() {
	reader_id = id;	
	post do_read();
	return SUCCESS;
}



}
