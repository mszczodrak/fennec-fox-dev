module LoggerP {
provides interface Logger;
uses interface Alarm<T32khz,uint32_t> as Timer;
}

implementation {

#define MAX_NUM_LOGS 100

uint16_t log_count = 0;

typedef struct log_msg {
	uint32_t time;
	uint16_t from;
	uint16_t msg;
} log_msg_t;

log_msg_t logs[MAX_NUM_LOGS];

void insertLog(uint16_t from, uint16_t message) @C() {
	call Logger.insert(from, message);
}

void cleanLog() @C() {
	call Logger.clean();
}

void printLog() @C() {
	call Logger.print();
}


command void Logger.insert(uint16_t from, uint16_t message) {
	logs[log_count].time = call Timer.getNow();
	logs[log_count].from = from;
	logs[log_count].msg = message;
	log_count++;
}

command void Logger.clean() {
	for (log_count = 0; log_count < MAX_NUM_LOGS; log_count++) {
		memset(logs + log_count, 0, sizeof(log_msg_t));
	}
	log_count = 0;
}

command void Logger.print() {
	uint16_t i;
	for (i = 0; i < log_count; i++) {
		printf("%lu %d %d\n", logs[i].time, logs[i].from, logs[i].msg);
	}
	printf("\n");
	printfflush();
	call Logger.clean();
}

async event void Timer.fired() {


}

}
