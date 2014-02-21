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
#include "sim_io.h"
#include "sensor_input_pkt.h"

struct sim_sensor_client_list *sim_sensor_clients;
int sim_sensor_server_socket;
int sim_sensor_num_clients;

int sim_sensor_unix_check(const char *msg, int result) {
	if (result < 0) {
		perror(msg);
		exit(2);
	}

	return result;
}

void *sim_sensor_xmalloc(size_t s) {
	void *p = malloc(s);

	if (!p) {
		fprintf(stderr, "out of memory\n");
		exit(2);
	}
	return p;
}

void sim_sensor_fd_wait(fd_set *fds, int *maxfd, int fd) {
	if (fd > *maxfd)
		*maxfd = fd;
	FD_SET(fd, fds);
}


void sim_sensor_pstatus(void) {
	printf("clients %d\n", sim_sensor_num_clients);
}

void sim_sensor_add_client(int fd) {
	struct sim_sensor_client_list *c = (struct sim_sensor_client_list*)
		sim_sensor_xmalloc(sizeof(struct sim_sensor_client_list));

	c->next = sim_sensor_clients;
	sim_sensor_clients = c;
	sim_sensor_num_clients++;
	sim_sensor_pstatus();

	c->fd = fd;
}


void sim_sensor_rem_client(struct sim_sensor_client_list **c) {
	struct sim_sensor_client_list *dead = *c;

	*c = dead->next;
	sim_sensor_num_clients--;
	sim_sensor_pstatus();
	close(dead->fd);
	free(dead);
}


int sim_sensor_init_source(int fd) {
	const char *welcome = "Welcome to Testbed Sensor Input\n\n"
		"The server accepts the following packets:\n\n"
		"struct sensor_input_pkt {\n"
		"\tuint16_t node_id;\n"
		"\tuint16_t sensor_id;\n"
		"\tuint32_t value;\n};\n\n";
	return send(fd, welcome, strlen(welcome), 0);
}


void sim_sensor_new_client(int fd) {
	fcntl(fd, F_SETFL, 0);
	if (sim_sensor_init_source(fd) < 0)
		close(fd);
	else
		sim_sensor_add_client(fd);
}


void *sim_sensor_read_packet(int fd, int *len) {
	unsigned char l;
	void *packet = malloc(sizeof(struct sensor_input_pkt));
	if (!packet) 
		return NULL;

	if (recv(fd, packet, sizeof(sensor_input_pkt), 0) == -1) {
		free(packet);
		return NULL;
	}

	*len = sizeof(sensor_input_pkt);
	return packet;
}


void sim_sensor_check_clients(fd_set *fds) {
	struct sim_sensor_client_list **c;

	for (c = &sim_sensor_clients; *c; ) {
		int isNext = 1;

		if (FD_ISSET((*c)->fd, fds)) {
			int len;
			const void *packet = sim_sensor_read_packet((*c)->fd, &len);

			if (packet) {
				sim_sensor_forward_packet(packet, len);
				free((void *)packet);
			} else {
				sim_sensor_rem_client(c);
				isNext = 0;
			}
		}
		if (isNext)
			c = &(*c)->next;
	}
}


void sim_sensor_wait_clients(fd_set *fds, int *maxfd) {
	struct sim_sensor_client_list *c;

	for (c = sim_sensor_clients; c; c = c->next)
		sim_sensor_fd_wait(fds, maxfd, c->fd);
}

void sim_sensor_check_new_client(void) {
	int clientfd = accept(sim_sensor_server_socket, NULL, NULL);

	if (clientfd >= 0)
		sim_sensor_new_client(clientfd);
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
	struct sensor_input_pkt *pkt = (struct sensor_input_pkt *)packet;
	//printf("receive a packet\n");
	//printf("rec node: %d\n", ntohs(pkt->node_id));
	//printf("rec sensor: %d\n", ntohs(pkt->sensor_id));
	//printf("rec val: %d\n", ntohl(pkt->value));

	sim_outside_write_input(ntohs(pkt->node_id), ntohl(pkt->value), 
						ntohs(pkt->sensor_id), 0);
}


void sim_sensor_process() {
	fd_set rfds;
	int maxfd = -1;
	struct timeval zero;
	int ret;

	zero.tv_sec = zero.tv_usec = 0;

	FD_ZERO(&rfds);
	sim_sensor_fd_wait(&rfds, &maxfd, sim_sensor_server_socket);
	sim_sensor_wait_clients(&rfds, &maxfd);

	ret = select(maxfd + 1, &rfds, NULL, NULL, &zero);
	if (ret >= 0) {
		if (FD_ISSET(sim_sensor_server_socket, &rfds))
			sim_sensor_check_new_client();

		sim_sensor_check_clients(&rfds);
	}
}


