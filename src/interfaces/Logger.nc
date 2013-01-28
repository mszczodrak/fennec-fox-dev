interface Logger {
	command void insert(uint16_t from, uint16_t message);
	command void clean();
	command void print();
}
