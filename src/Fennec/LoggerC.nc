configuration LoggerC {
#ifdef FENNEC_LOGGER
provides interface Logger;
#endif
}

implementation {

components LoggerP;
#ifdef FENNEC_LOGGER
Logger = LoggerP;

components AlarmMultiplexC as Timer;
LoggerP.Timer -> Timer;
#endif
}

