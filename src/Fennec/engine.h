#ifndef __FF__ENGINE_H_
#define __FF__ENGINE_H_

#include "Fennec.h"
#include "ff_caches.h"
#include "ff_defaults.h"

bool ctrl_module(uint16_t module_id, uint8_t ctrl);
void ctrl_module_done(uint8_t status);

#endif
