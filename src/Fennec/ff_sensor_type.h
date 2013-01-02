#ifndef FF_SENSOR_TYPE_H
#define FF_SENSOR_TYPE_H

/**
  * Define sensor types 
  */
typedef enum {
  F_SENSOR_TEMPERATURE    = 1,
  F_SENSOR_LIGHT          = 2,
  F_SENSOR_HUMIDITY       = 3,
  F_SENSOR_SOUND          = 4,
  F_SENSOR_MOTION         = 5,
  F_SENSOR_CAMERA         = 6,
  F_SENSOR_VIBRATION      = 7,
  F_SENSOR_MAGNETIC       = 8,
  F_SENSOR_ACCELERATION   = 9
} sensor_type_t;

#endif
