module LoggerP {
provides interface Logger;
uses interface Alarm<T32khz,uint32_t> as Timer;
}

implementation {

#ifdef FENNEC_LOGGER
#define MAX_NUM_LOGS 100

uint16_t log_count = 0;

typedef struct log_msg {
	uint32_t time;
	uint16_t from;
	uint16_t msg;
} log_msg_t;

log_msg_t logs[MAX_NUM_LOGS];
#endif

void insertLog(uint16_t from, uint16_t message) @C() {
#ifdef FENNEC_LOGGER
	call Logger.insert(from, message);
#endif
}

void cleanLog() @C() {
#ifdef FENNEC_LOGGER
	call Logger.clean();
#endif
}

void printLog() @C() {
#ifdef FENNEC_LOGGER
	call Logger.print();
#endif
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
