/*
 *  Fennec Fox platform.
 *
 *  Copyright (C) 2010-2013 Marcin Szczodrak
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
 * author:      Marcin Szczodrak
 * date:        10/02/2009
 * last update: 02/14/2013
 */



#include <Fennec.h>

module FennecP {
uses interface Boot;

uses interface Leds;
uses interface SimpleStart as DbgSerial;
uses interface SimpleStart as RandomStart;
uses interface SimpleStart as Caches;
uses interface SimpleStart as NetworkScheduler;
}

implementation {

event void Boot.booted() {
	dbg("Fennec", "Starting... here");
	//call Leds.led1On();
	call DbgSerial.start();
}

task void start_random() {
	dbg("Fennec", "Starting... Random");
	call RandomStart.start();
}

task void start_network_scheduler() {
	dbg("Fennec", "Starting... NetworkScheduler");
	call NetworkScheduler.start();
}

task void start_caches() {
	dbg("Fennec", "Starting... Caches");
	call Caches.start();
}

event void DbgSerial.startDone(error_t err) {
	if (err == SUCCESS) {
		post start_random();
	} else {
		call DbgSerial.start();
	}
}

event void RandomStart.startDone(error_t err) {
	if (err == SUCCESS) {
		post start_caches();
	} else {
		post start_random();
	}
}

event void NetworkScheduler.startDone(error_t err) {
}

event void Caches.startDone(error_t err) {
	if (err == SUCCESS) {
		call NetworkScheduler.start();
	} else {
		post start_caches();
	}
}

}

