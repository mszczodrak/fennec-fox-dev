/*
 *  Fennec Fox platform.
 *
 *  Copyright (C) 2010-2012 Marcin Szczodrak
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/*
 * author: 	Marcin Szczodrak
 * date:   	10/02/2009
 * last update:	07/16/2012
 */

#ifndef FENNEC_H
#define FENNEC_H


#ifdef FENNEC_TOS_PRINTF
#define NEW_PRINTF_SEMANTICS
#include "printf.h"
#else
#ifdef CAPEFOX
#include "printf_cape.h"
#else
#include "printf_default.h"
#endif
#endif

#include "Dbgs.h"
#include "AM.h"

#include "ff_structs.h"
#include "ff_flags.h"
#include "ff_states.h"
#include "ff_sensors.h"
#include "ff_functions.h"
#include "ff_consts.h"


#include "message.h"
#include <Ieee154.h>


#endif
