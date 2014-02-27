interface TrickleTimerParams {
        command uint16_t get_low();
        command error_t set_low(uint16_t new_low);
        command uint16_t get_high();
        command error_t set_high(uint16_t new_high);
        command uint8_t get_k();
        command error_t set_k(uint8_t new_k);
        command uint8_t get_scale();
        command error_t set_scale(uint8_t new_scale);
}
