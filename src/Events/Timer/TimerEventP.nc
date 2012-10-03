/*
 *  timer-based event engine for Fennec Fox platform.
 *
 *  Copyright (C) 2009-2011 Marcin Szczodrak
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
 * Author: Marcin Szczodrak
 * Date: 12/8/2009
 * Last Modified: 6/4/2011
 */

#include <Fennec.h>
#include "ff_structs.h"
#include "ff_consts.h"

generic module TimerEventP()
{
  provides interface Event;
  provides interface TimerEvent;

  uses interface Timer<TMilli>;

  uses interface Timer<TMilli> as SensorTimer;
}

implementation {

  uint16_t threshold;
  uint8_t op;
  am_addr_t addr;
  bool occures;
  uint32_t scale;

  command void Event.start(struct fennec_event *en) {
    occures = FALSE;
    threshold = en->value;
    op = en->operation;
    addr = en->addr;

    scale = 1;

    if (en->scale == TYPE_SECOND) {
      scale = 1024U;
    }

    if (en->scale == TYPE_MINUTE) {
      scale = 61440U;
    }
 
    if (en->scale == TYPE_DAY) {
      scale = 1474560U;
    }

    if ((NODE == addr) || (TOS_NODE_ID == addr)) {
      call SensorTimer.startOneShot(threshold * scale);
      call Timer.startPeriodic(DEFAULT_FENNEC_SENSE_PERIOD);
      dbg("TimerEvent", "TimerEvent started with op %d and value %d\n", op, threshold);
    }
  }

  command void Event.stop() {
    call Timer.stop();
    call SensorTimer.stop();
    dbg("TimerEvent", "TimerEvent stopped\n");
  }

  command void TimerEvent.setFrequency(uint16_t ms_delay) {
    call Timer.startPeriodic(ms_delay);
  }

  command void TimerEvent.setOperation(uint8_t new_op) {
    op = new_op;
  }

  command void TimerEvent.setThreshold(uint16_t value) {
    threshold = value;
  }

  event void Timer.fired() {
    bool flag = call SensorTimer.isRunning();
    dbg("TimerEvent", "TimerEvent: fired to check the event occurance\n");

    switch(op) {

      case EQ:
        if (occures) {
          occures = FALSE;
          signal Event.occured(FALSE);
        }
        break; 
        
      case NQ:
        if (!occures) {
          occures = TRUE;
          signal Event.occured(TRUE); 
        }
        break;

      case LT:
      case LE:
        if (flag && !occures) {
          occures = TRUE;
          signal Event.occured(TRUE);
        }
        if (!flag && occures) {
          occures = FALSE;
          signal Event.occured(FALSE);
        }
        break;

      case GT:
      case GE:
        if (!flag && !occures) {
          occures = TRUE;
          signal Event.occured(TRUE);
        }
        if (flag && occures) {
          occures = FALSE;
          signal Event.occured(FALSE);
        }
        break;

      default:
        dbg("TimerEvent", "TimerEvent testing event occrence but with unknown operator\n");
    }
  }

  event void SensorTimer.fired() {
    dbg("TimerEvent", "TimerEvent: Sensor fired\n");

    switch(op) {
      case EQ:
      case LE:
      case GE:
        if (!occures) {
          occures = TRUE;
          dbg("TimerEvent", "TimerEvent: signal occurance\n");
          signal Event.occured(TRUE);
        }
        break;

      case NQ:
      case LT:
      case GT:
        if (occures) {
          occures = FALSE;
          signal Event.occured(FALSE);
        }
        break;

      default:
        dbg("TimerEvent", "TimerEvent testing event occrence but with unknown operator\n");

    }
  }
}


