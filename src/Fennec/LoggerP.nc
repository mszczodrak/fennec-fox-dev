module LoggerP {
provides interface Logger;
uses interface Alarm<T32khz,uint32_t> as Timer;
}

implementation {


command void Logger.insert(uint8_t from, uint8_t message) {

}

command void Logger.clean() {

}

command void Logger.print() {

}

async event void Timer.fired() {


}

}
