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

int (*read_fp)(uint16_t, uint32_t);
int (*write_fp)(uint16_t, uint32_t, int);


void sim_io_init()__attribute__ ((C, spontaneous))
{
}

int sim_read_io(uint16_t node_id)__attribute__ ((C, spontaneous)) {
	return 0;
}

int sim_write_io(uint16_t node_id, uint32_t val)__attribute__ ((C, spontaneous)) {
	return 0;
}

int sim_add_read_io(uint16_t node_id, uint8_t io_size, int (*op) (uint16_t, uint32_t))__attribute__ ((C, spontaneous)) {
	read_fp = op;
	return 0;
}

int sim_add_write_io(uint16_t node_id, uint8_t io_size, int (*op) (uint16_t, uint32_t, int))__attribute__ ((C, spontaneous)) {
	write_fp = op;
	return 0;
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
