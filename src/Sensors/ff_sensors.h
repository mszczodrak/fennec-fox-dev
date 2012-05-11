#ifndef __FF_SENSORS_H_
#define __FF_SENSORS_H_

struct ff_sensor_accelerometer {
	uint16_t x;
	uint16_t y;
	uint16_t z;
};

struct ff_sensor_temperature {
	uint16_t temp;
	uint16_t raw;
};

struct ff_sensor_light {
	uint16_t light;
	uint16_t raw;
};

struct ff_sensor_humidity {
	uint16_t humidity;
	uint16_t raw;
};

struct ff_sensor_pir {
	uint16_t presence;
	uint16_t raw;
};

struct ff_sensor_sound {
	uint16_t sound;
	uint16_t raw;
};

struct ff_sensor_battery {
	uint16_t battery;
	uint16_t raw;
};

struct ff_sensor_vibration {
	uint16_t vibration;
	uint16_t raw;
};

struct ff_sensor_thinforce {
	uint16_t thinforce;
	uint16_t raw;
};

struct ff_sensor_camera {
	uint16_t camera;
	uint16_t raw;
};

struct ff_sensor_magnetic {
	uint16_t magnetic;
	uint16_t raw;
};


#endif
