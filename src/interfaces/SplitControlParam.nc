interface SplitControlParam
{
  command error_t start(uint8_t param);
  event void startDone(error_t error, uint8_t param);
  command error_t stop(uint8_t param);
  event void stopDone(error_t error, uint8_t param);
}
