interface SensorCtrl {
//  command error_t start();
//  command error_t stop();

//  event void startDone(error_t err);
//  event void stopDone(error_t err);

//  command error_t set_sensitivity(uint16_t new_sensitivity);
  command error_t setRate(uint32_t new_rate);
//  command error_t setSignaling(uint8_t new_signaling);

//  command uint16_t getSensitivity();
  command uint32_t getRate();
//  command uint8_t getSignaling();
}
