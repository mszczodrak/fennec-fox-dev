/*
 * Copyright (c) 2012 Columbia University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Implementation of remote sensor data feeding
 *
 * @author Marcin Szczodrak
 * @last_updated   February 19 2014
 */

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <signal.h>

#include "sim_sensor_input.h"
#include "sim_tossim.h"

int sim_sensor_server_socket;

int sim_sensor_unix_check(const char *msg, int result) {
	if (result < 0) {
		perror(msg);
		exit(2);
	}

	return result;
}


void sim_sensor_open_socket(int port) {
	struct sockaddr_in me;
	int opt;

	sim_sensor_server_socket = sim_sensor_unix_check("socket", socket(AF_INET, SOCK_STREAM, 0));
	sim_sensor_unix_check("socket", fcntl(sim_sensor_server_socket, F_SETFL, O_NONBLOCK));
	memset(&me, 0, sizeof me);
	me.sin_family = AF_INET;
	me.sin_port = htons(port);

	opt = 1;
	sim_sensor_unix_check("setsockopt", setsockopt(sim_sensor_server_socket, SOL_SOCKET, SO_REUSEADDR,
                                        (char *)&opt, sizeof(opt)));

	sim_sensor_unix_check("bind", bind(sim_sensor_server_socket, (struct sockaddr *)&me, sizeof me));
	sim_sensor_unix_check("listen", listen(sim_sensor_server_socket, 5));
}


void sim_sensor_forward_packet(const void *packet, const int len) {



}


void sim_sf_fd_wait(fd_set *fds, int *maxfd, int fd) {
	if (fd > *maxfd)
		*maxfd = fd;
	FD_SET(fd, fds);
}


void sim_sensor_process() {

/*
	fd_set rfds;
	int maxfd = -1;
	struct timeval zero;
	int ret;

	zero.tv_sec = zero.tv_usec = 0;

	FD_ZERO(&rfds);
        sim_sensor_fd_wait(&rfds, &maxfd, sim_sf_server_socket);
        sim_sensor_wait_clients(&rfds, &maxfd);

        ret = select(maxfd + 1, &rfds, NULL, NULL, &zero);
        if (ret >= 0)
        {
            if (FD_ISSET(sim_sf_server_socket, &rfds))
                sim_sf_check_new_client();

            sim_sensor_check_clients(&rfds);
        }

*/
}


