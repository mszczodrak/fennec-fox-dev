/*
 * Copyright (c) 2014 Columbia University. All rights reserved.
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
 * Implementation Input/Output (Sensor/Actuator) channels
 *
 * @author Marcin Szczodrak
 * @date   February 16 2014
 */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <time.h>
#include "randomlib.h"
#include "hashtable.h"
#include "sim_io.h"

#define MAX_SENSOR_INPUTS	4
#define MAX_ACTUATOR_OUTPUTS	4
#define MIN_IO_TRACE		8
#define IO_TIME_ERROR		100

typedef struct sim_io_t {
	double* ioData;
	long long int* ioTime; 
	int dataLen;
	int dataIndex;
	int lastData;
} sim_io_t;


typedef struct sim_node_ios_t {
	sim_io_t input[MAX_SENSOR_INPUTS];
	sim_io_t output[MAX_ACTUATOR_OUTPUTS];
} sim_node_ios_t;


void save_input(uint16_t node_id, double data_val, int input_id, long long int time_val);
void save_output(uint16_t node_id, double data_val, int input_id, long long int time_val);
void double_memory(sim_io_t *channel);
double retrieve_output(uint16_t node_id, int input_id, long long int time_val);
double retrieve_input(uint16_t node_id, int input_id, long long int time_val);
double simulateData(long long int time_val);
void do_saving(sim_io_t *channel, double data_val, long long int time_val);
double do_retrieve(sim_io_t *channel,  long long int time_val);

sim_node_ios_t node_ios[TOSSIM_MAX_NODES]; 


void sim_io_init()__attribute__ ((C, spontaneous))
{
	int i, j;

	for (i = 0; i < TOSSIM_MAX_NODES; i++) {
		for(j = 0; j < MAX_SENSOR_INPUTS; j++) {	
			node_ios[i].input[j].ioData = NULL;
			node_ios[i].input[j].ioTime = NULL;
			node_ios[i].input[j].dataLen = 0;
			node_ios[i].input[j].dataIndex = 0;
			node_ios[i].input[j].lastData = 0;
			
		}
		for(j = 0; j < MAX_ACTUATOR_OUTPUTS; j++) {	
			node_ios[i].output[j].ioData = NULL;
			node_ios[i].output[j].ioTime = NULL;
			node_ios[i].output[j].dataLen = 0;
			node_ios[i].output[j].dataIndex = 0;
			node_ios[i].output[j].lastData = 0;
		}
	}
}


/* 
 * call from Python interface
 */
double sim_outside_read_output(uint16_t node_id, int input_id, long long int time_val)__attribute__ ((C, spontaneous)) {
	printf("hello\n");
	if (time_val) {
		return retrieve_output(node_id, input_id, time_val);
	} else {
		return retrieve_output(node_id, input_id, sim_time());
	}
}

/* 
 * call from Python interface
 */
void sim_outside_write_input(uint16_t node_id, double data_val, int input_id, long long int time_val)__attribute__ ((C, spontaneous)) {
	printf("wringing %f\n", data_val);
	if (time_val) {
		save_input(node_id, data_val, input_id, time_val);
	} else {
		save_input(node_id, data_val, input_id, sim_time());
	}
}

/*
 * call from Mote
 */
double sim_node_read_input(uint16_t node_id, int input_id)__attribute__ ((C, spontaneous)) {
	return retrieve_input(node_id, input_id, sim_time());
}

/*
 * call from Mote
 */
void sim_node_write_output(uint16_t node_id, double val, int input_id)__attribute__ ((C, spontaneous)) {
	save_output(node_id, val, input_id, sim_time());
}


/*
 * Utility functions
 */
void double_memory(sim_io_t *channel) {
	int new_size = channel->dataLen;
	double *ioData = NULL;
	long long int *ioTime = NULL;

	if (new_size == 0) {
		new_size = MIN_IO_TRACE;
	} else {
		new_size *= 2;
	}

	ioData = (double*)(malloc(sizeof(double) * new_size));
	ioTime = (long long int*)(malloc(sizeof(long long int) * new_size));

	if ((ioData == NULL) || (ioTime == NULL)) {
		printf("Malloc failed in sim_io_init()\n");
		exit(1);
	}

	memcpy(ioData, channel->ioData, sizeof(double) * channel->dataLen);
	memcpy(ioTime, channel->ioTime, sizeof(long long int) * channel->dataLen);
	free(channel->ioData);	
	free(channel->ioTime);	
	channel->ioData = ioData;
	channel->ioTime = ioTime;
	channel->dataLen = new_size;
}

void do_saving(sim_io_t *channel, double data_val, long long int time_val) {
	if ((channel->ioData == NULL) || (channel->dataIndex == channel->dataLen)) {
		double_memory(channel);
	}
	//printf("saving length %d\n", channel->dataLen);
	channel->ioData[channel->dataIndex] = data_val;
	channel->ioTime[channel->dataIndex] = time_val;
	channel->dataIndex++;
}

void save_input(uint16_t node_id, double data_val, int input_id, long long int time_val) {
	sim_io_t *ch = &node_ios[node_id].input[input_id];
	//printf("save input 1 %d %f %d %llu\n", node_id, data_val, input_id, time_val);
	do_saving(ch, data_val, time_val);
}

void save_output(uint16_t node_id, double data_val, int output_id, long long int time_val) {
	sim_io_t *ch = &node_ios[node_id].output[output_id];
	//printf("save input 1 %d %f %d %llu\n", node_id, data_val, output_id, time_val);
	do_saving(ch, data_val, time_val);
}

double do_retrieve(sim_io_t *channel,  long long int time_val) {
	if (channel->ioData == NULL) {
		//printf("it is null\n");
		return simulateData(time_val);
	}
	if (fabs(channel->ioTime[channel->dataIndex - 1] - time_val) < IO_TIME_ERROR) {
		//printf("here\n");
		return channel->ioData[channel->dataIndex - 1];
	} else {
		int time_trace = channel->ioTime[channel->dataIndex - 1] - channel->ioTime[0]; 
		int data_for_time = (int)time_val % time_trace;
		int index_step = time_trace / channel->dataIndex;
		int data_index = index_step * data_for_time;
		//printf("here n\n");
		return channel->ioData[data_index];
	}
}

double retrieve_output(uint16_t node_id, int output_id, long long int time_val) {
	sim_io_t *ch = &node_ios[node_id].output[output_id];
	return do_retrieve(ch, time_val);
}


double retrieve_input(uint16_t node_id, int input_id, long long int time_val) {
	sim_io_t *ch = &node_ios[node_id].input[input_id];
	return do_retrieve(ch, time_val);
}

double simulateData(long long int time_val) {
	return sin(time_val);
}
