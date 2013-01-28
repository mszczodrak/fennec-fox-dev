configuration LoggerC {
provides interface Logger;
}

implementation {

components LoggerP;
Logger = LoggerP;

components AlarmMultiplexC as Timer;
LoggerP.Timer -> Timer;

}

