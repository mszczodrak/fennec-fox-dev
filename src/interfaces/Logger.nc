interface Logger {
	command void insert(uint8_t from, uint8_t message);
	command void clean();
	command void print();
}
