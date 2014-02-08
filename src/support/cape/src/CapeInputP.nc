generic model CapeInputP() {
provides interface Read<uint16_t> as Read16[uint8_t id];
//provides interface Read<uint32_t> as Read32[uint8_t id];
}

implementation {

task void do_read() {
	signal Read16.readDone(SUCCESS, 17);
}


command error_t Read16.read() {
	post do_read();
	return SUCCESS;
}



}
