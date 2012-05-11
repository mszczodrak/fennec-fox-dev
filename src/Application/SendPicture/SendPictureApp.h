/*
 * Application: 
 * Author: 
 * Date: 
 */

#ifndef __SEND_PICTURE_APP_H_
#define __SEND_PICTURE_APP_H_

#define VGA_SIZE_RGB (640*480*3)

uint8_t pic_frame[VGA_SIZE_RGB] __attribute__((section(".sdram")));

#define PICTURE_FRAME_ADDRESS      pic_frame

typedef nx_struct {
  nx_uint32_t offset;
  nx_uint8_t (COUNT(0) frame)[0];
} pic_header_t;

#endif
