interface Mgmt
{
  command error_t start();
  event void startDone(error_t error);
  command error_t stop();
  event void stopDone(error_t error);
//  event uint16_t currentStateId();
}
