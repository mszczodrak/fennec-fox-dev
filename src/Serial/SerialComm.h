#ifndef _SERIAL_COMM_H_
#define _SERIAL_COMM_H_

#define BIGMSG_HEADER_LENGTH 2
#define BIGMSG_DATA_SHIFT 6
#define BIGMSG_DATA_LENGTH (1<<BIGMSG_DATA_SHIFT)
#define TOSH_DATA_LENGTH  (BIGMSG_HEADER_LENGTH+BIGMSG_DATA_LENGTH)

enum
{
  AM_BIGMSG_FRAME_PART=0x6E,
  AM_BIGMSG_FRAME_REQUEST=0x6F,
};

typedef nx_struct bigmsg_frame_part{
	nx_uint16_t part_id;
	nx_uint8_t buf[BIGMSG_DATA_LENGTH];
} bigmsg_frame_part_t;

typedef nx_struct bigmsg_frame_request{
	nx_uint16_t part_id;
	nx_uint16_t send_next_n_parts;
} bigmsg_frame_request_t;
#endif 


