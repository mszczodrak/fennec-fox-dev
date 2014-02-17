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

typedef struct sim_io_t {
	double* ioData;
	double* ioTime; 
	int dataLen;
	int dataIndex;
	int lastData;
} sim_io_t;

typedef struct sim_node_ios_t {
	sim_io_t input[MAX_SENSOR_INPUTS];
	sim_io_t output[MAX_ACTUATOR_OUTPUTS];
} sim_node_ios_t;

void save_input(uint16_t node_id, double data_val, int input_id, double time_val);
void save_output(uint16_t node_id, double data_val, int input_id, double time_val);
void double_memory(sim_io_t *channel);
double retrieve_output(uint16_t node_id, int input_id, double time_val);
double retrieve_input(uint16_t node_id, int input_id, double time_val);


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
double sim_outside_read_output(uint16_t node_id, int input_id)__attribute__ ((C, spontaneous)) {
	return retrieve_output(node_id, input_id, sim_time());
}

/* 
 * call from Python interface
 */
void sim_outside_write_input(uint16_t node_id, double val, int input_id)__attribute__ ((C, spontaneous)) {
	save_input(node_id, val, input_id, sim_time());
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
	double *ioTime = NULL;

	if (new_size == 0) {
		new_size = MIN_IO_TRACE;
	} else {
		new_size *= 2;
	}

	ioData = (double*)(malloc(sizeof(double) * new_size));
	ioTime = (double*)(malloc(sizeof(double) * new_size));

	if ((ioData == NULL) || (ioTime == NULL)) {
		printf("Malloc failed in sim_io_init()\n");
		exit(1);
	}

	memcpy(ioData, channel->ioData, sizeof(double) * channel->dataLen);
	memcpy(ioTime, channel->ioTime, sizeof(double) * channel->dataLen);
	free(channel->ioData);	
	free(channel->ioTime);	
	channel->ioData = ioData;
	channel->ioTime = ioTime;
	channel->dataLen = new_size;
}


void save_input(uint16_t node_id, double data_val, int input_id, double time_val) {
	sim_io_t *ch = &node_ios[node_id].input[input_id];
	if ((ch->ioData == NULL) || (ch->dataIndex == ch->dataLen)) {
		double_memory(ch);
	}
	ch->ioData[ch->dataIndex] = data_val;
	ch->ioTime[ch->dataIndex] = time_val;
	ch->dataIndex++;
}

void save_output(uint16_t node_id, double data_val, int input_id, double time_val) {
	sim_io_t *ch = &node_ios[node_id].output[input_id];
	if ((ch->ioData == NULL) || (ch->dataIndex == ch->dataLen)) {
		double_memory(ch);
	}
	ch->ioData[ch->dataIndex] = data_val;
	ch->ioTime[ch->dataIndex] = time_val;
	ch->dataIndex++;
}

double retrieve_output(uint16_t node_id, int input_id, double time_val) {

	return 0;
}


double retrieve_input(uint16_t node_id, int input_id, double time_val) {

	return 0;
}


