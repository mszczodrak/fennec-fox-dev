#ifndef _H_VIRTUAL_BATTERY_H
#define _H_VIRTUAL_BATTERY_H

error_t removeVoltage(double value);
error_t addVoltage(double value);

enum {
  VIRTUAL_MINIMUM_VOLTAGE_LEVEL = 1,
  VIRTUAL_MAXIMUM_VOLTAGE_LEVEL = 3000,
};

#endif

