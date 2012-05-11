interface RadioDutyCycle
{
  command void channel_status();
  event void detection_status(uint8_t status);
}

