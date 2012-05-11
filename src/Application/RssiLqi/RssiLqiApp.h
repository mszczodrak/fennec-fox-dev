/*
 * Application: 
 * Author: 
 * Date: 
 */

#ifndef __RSSILQI_APP_H_
#define __RSSILQI_APP_H_

#define EXTRA_SIZE 0

typedef nx_struct {
   nx_uint16_t counter;
   nx_uint8_t value[EXTRA_SIZE];
} rssilqi_msg_t;


#endif
