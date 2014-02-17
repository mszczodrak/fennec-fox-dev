#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/time.h>
#include <time.h>
#include "randomlib.h"
#include "hashtable.h"
#include "sim_io.h"

//Tal Debug, to count how often simulation hits the one match case
//int numCase1 = 0;
//int numCase2 = 0;
//int numTotal = 0;
//End Tal Debug

//uint32_t FreqKeyNum = 0;

//sim_noise_node_t noiseData[TOSSIM_MAX_NODES];

//static unsigned int sim_noise_hash(void *key);
//static int sim_noise_eq(void *key1, void *key2);

//void makeNoiseModel(uint16_t node_id);
//void makePmfDistr(uint16_t node_id);
//uint8_t search_bin_num(char noise);

//int (*read_fp)(uint16_t, uint32_t);
//int (*write_fp)(uint16_t, uint32_t, int);

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
	sim_io_t inputs[MAX_SENSOR_INPUTS];
	sim_io_t outputs[MAX_ACTUATOR_OUTPUTS];
} sim_node_ios_t;

sim_node_ios_t node_ios[TOSSIM_MAX_NODES]; 


void sim_io_init()__attribute__ ((C, spontaneous))
{
	int i, j;

	for (i = 0; i < TOSSIM_MAX_NODES; i++) {
		for(j = 0; j < MAX_SENSOR_INPUTS; j++) {	
			node_ios[i].inputs[j].ioData = NULL;
/*
			node_ios[i].inputs[j].inputData = (double*)(malloc(sizeof(double) * MIN_IO_TRACE));
			if (node_ios[i].inputs[j].inputData == NULL) {
				printf("Malloc failed in sim_io_init()\n");
				exit(1);
			}
*/
			node_ios[i].inputs[j].ioTime = NULL;
			node_ios[i].inputs[j].dataLen = 0;
			node_ios[i].inputs[j].dataIndex = 0;
			node_ios[i].inputs[j].lastData = 0;
			
		}
		for(j = 0; j < MAX_ACTUATOR_OUTPUTS; j++) {	
			node_ios[i].outputs[j].ioData = NULL;
			node_ios[i].outputs[j].ioTime = NULL;
			node_ios[i].outputs[j].dataLen = 0;
			node_ios[i].outputs[j].dataIndex = 0;
			node_ios[i].outputs[j].lastData = 0;
		}
	}
}

double sim_read_output(uint16_t node_id, int input_id)__attribute__ ((C, spontaneous)) {
	return 0;
}

void sim_write_input(uint16_t node_id, double val, int input_id)__attribute__ ((C, spontaneous)) {
	//return 0;
}

//char sim_real_noise(uint16_t node_id, uint32_t cur_t) {

/*
uint8_t search_bin_num(char noise)__attribute__ ((C, spontaneous))
{
  uint8_t bin;
  if (noise > NOISE_MAX || noise < NOISE_MIN) {
    noise = NOISE_MIN;
  }
  bin = (noise-NOISE_MIN)/NOISE_QUANTIZE_INTERVAL + 1;
  return bin;
}

char search_noise_from_bin_num(int i)__attribute__ ((C, spontaneous))
{
  char noise;
  noise = NOISE_MIN + (i-1)*NOISE_QUANTIZE_INTERVAL;
  return noise;
}

static unsigned int sim_noise_hash(void *key) {
  char *pt = (char *)key;
  unsigned int hashVal = 0;
  int i;
  for (i=0; i< NOISE_HISTORY; i++) {
    hashVal = pt[i] + (hashVal << 6) + (hashVal << 16) - hashVal;
  }
  return hashVal;
}
*/
