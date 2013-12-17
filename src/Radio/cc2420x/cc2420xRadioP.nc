/*
 *  cc2420x radio module for Fennec Fox platform.
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
 * Network: cc2420x Radio Protocol
 * Author: Marcin Szczodrak
 * Date: 8/20/2010
 * Last Modified: 1/5/2012
 */


#include <Fennec.h>
#include <Tasklet.h>
#include "cc2420xRadio.h"

module cc2420xRadioP @safe()
{
provides interface SplitControl;
uses interface cc2420xRadioParams;
uses interface RadioState;
}

implementation {

uint8_t channel;
norace uint8_t state = S_STOPPED;
norace message_t *m;
error_t m_error = FALSE;


task void start_done() {
	state = S_STARTED;
	signal SplitControl.startDone(m_error);
}

task void finish_starting_radio() {
	post start_done();
}

task void stop_done() {
	state = S_STOPPED;
	signal SplitControl.stopDone(m_error);
}

task void stateDoneTask()
{
/*
      uint8_t s;

      s = state;

      // change the state before so we can be reentered from the event
      state = STATE_READY;

      if( s == STATE_TURN_ON )
               signal SplitControl.startDone(SUCCESS);
      else if( s == STATE_TURN_OFF )
               signal SplitControl.stopDone(SUCCESS);
        else if( s == STATE_CHANNEL )
               signal RadioChannel.setChannelDone();
        else    // not our event, ignore it
               state = s;
*/
}


tasklet_async event void RadioState.done()
{
	post stateDoneTask();
}


command error_t SplitControl.start() {
	m_error = call RadioState.turnOn();
	post start_done();
	return m_error;
}

command error_t SplitControl.stop() {
	m_error = call RadioState.turnOff();
	post stop_done();
	return m_error;
}






}

