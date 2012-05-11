#include "Msp430Adc12.h"

module phidget_1127_0_confP {
  provides interface AdcConfigure<const msp430adc12_channel_config_t*>;
}

implementation {

  msp430adc12_channel_config_t configinit = {
    inch: INPUT_CHANNEL_A7,
    sref: REFERENCE_AVcc_AVss,
    ref2_5v: REFVOLT_LEVEL_NONE,
    adc12ssel: SHT_SOURCE_ACLK,
    adc12div: SHT_CLOCK_DIV_1,
    sht: SAMPLE_HOLD_4_CYCLES,
    sampcon_ssel: SAMPCON_SOURCE_SMCLK,
    sampcon_id: SAMPCON_CLOCK_DIV_1
  };

  async command const msp430adc12_channel_config_t* 
				AdcConfigure.getConfiguration() {
    return &configinit;
  }
}

