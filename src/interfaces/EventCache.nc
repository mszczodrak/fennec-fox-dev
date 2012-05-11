interface EventCache {
  command void clearMask();
  command struct fennec_event *getEntry(uint8_t ev);

  command void setBit(uint16_t bit);
  command void clearBit(uint16_t bit);

  command bool eventStatus(uint16_t event_num);
}


