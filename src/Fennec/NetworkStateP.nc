/*
 * Copyright (c) 2009, Columbia University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *  - Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  - Neither the name of the Columbia University nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL COLUMBIA UNIVERSITY BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
  * Fennec Fox Network Scheduler
  *
  * @author: Marcin K Szczodrak
  * @updated: 09/08/2013
  */


#include <Fennec.h>

module NetworkStateP @safe() {
provides interface SplitControl;
uses interface NetworkProcess;
uses interface Fennec;
}

implementation {

struct network_process **privileged = NULL;
struct network_process **ordinary = NULL;

task void start_stack() {
	if ((privileged != NULL) && (*privileged != NULL)) {
		dbg("NetworkState", "[-] NetworkState call NetworkProcess.start(%d) (privileged)",
						(*privileged)->process_id);
		call NetworkProcess.start((*privileged)->process_id);		
		return;
	}

	if ((ordinary != NULL) && (*ordinary != NULL)) {
		dbg("NetworkState", "[-] NetworkState call NetworkProcess.start(%d) (ordinary)",
						(*ordinary)->process_id);
		call NetworkProcess.start((*ordinary)->process_id);		
		return;	
	}

	/* that's all folks, all processes are running */
	dbg("NetworkState", "[-] NetworkState finished starting all processes");
	signal SplitControl.startDone(SUCCESS);
}

task void stop_stack() {
	if ((privileged != NULL) && (*privileged != NULL)) {
//		dbg("NetworkState", "[-] NetworkState call NetworkProcess.stop(%d) (privileged)",
//						(*privileged)->process_id);
//		call NetworkProcess.stop((*privileged)->process_id);		
		*privileged = NULL;
//		return;
	}

	if ((ordinary != NULL) && (*ordinary != NULL)) {
		dbg("NetworkState", "[-] NetworkState call NetworkProcess.stop(%d) (ordinary)",
						(*ordinary)->process_id);
		call NetworkProcess.stop((*ordinary)->process_id);		
		return;	
	}

	/* that's all folks, all processes are running */
	dbg("NetworkState", "[-] NetworkState finished stopping all processes");
	signal SplitControl.stopDone(SUCCESS);
}

command error_t SplitControl.start() {
	dbg("NetworkState", "[-] NetworkState SplitControl.start()");
	printf("starting\n");
	printfflush();
	privileged = call Fennec.getPrivilegedProcesses();
	ordinary = call Fennec.getOrdinaryProcesses();
	post start_stack();
	return SUCCESS;
}

command error_t SplitControl.stop() {
	dbg("NetworkState", "[-] NetworkState SplitControl.stop()");
	privileged = call Fennec.getPrivilegedProcesses();
	privileged = NULL;
	ordinary = call Fennec.getOrdinaryProcesses();
	post stop_stack();
	return SUCCESS;
}

event void NetworkProcess.startDone(error_t err) {
	dbg("NetworkState", "[-] NetworkState NetworkProcess.startDone(%d)", err);
        if (err == SUCCESS) {
		if ((privileged) && (*privileged != NULL)) {
			privileged++;
		} else {
			ordinary++;
		}
        }
	post start_stack();
}

event void NetworkProcess.stopDone(error_t err) {
	dbg("NetworkState", "[-] NetworkState NetworkProcess.stopDone(%d)", err);
        if (err == SUCCESS) {
		if ((privileged) && (*privileged != NULL)) {
			privileged++;
		} else {
			ordinary++;
		}
	}
	post stop_stack();
}

}
