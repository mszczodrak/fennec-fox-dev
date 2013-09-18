interface EventCache {
command void clearMask();
command void setBit(uint16_t bit);
command void clearBit(uint16_t bit);

command bool eventStatus(uint16_t event_num);
}


