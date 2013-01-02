#include "ff_sensor_type.h"
#include "ff_sensor_ids.h"

interface SensorInfo {
  /**
    * Returns sensor's type as defined in ff_sensor_type.h.
    *
    * @return sensor's type
    */
  command sensor_type_t getType();

  /**
    * Returns sensor's unique id. This ID is unique in Fennec Fox
    * framework. Each new sensor hardware has assigned a new ID.
    * The sensor IDs are defined in src/sensors/ff_sensor_ids.h
    *
    * @return sensor_id_t
    */
  command sensor_id_t getId();
}
