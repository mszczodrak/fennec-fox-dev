#ifndef __DBGS_H_
#define __DBGS_H_


#define DBGS_SEND_DATA		1
#define DBGS_SEND_BEACON	2
#define DBGS_RECEIVE_DATA 	3
#define DBGS_RECEIVE_BEACON  	4

#define DBGS_MGMT_START		5
#define DBGS_MGMT_STOP		6

#define DBGS_MEMORY_EMPTY	7
#define DBGS_BLINK_LED		8

#define DBGS_GOT_SEND				20
#define DBGS_GOT_SEND_HEADER_NULL_FAIL		21
#define DBGS_GOT_SEND_STATE_FAIL		22
#define DBGS_GOT_SEND_FULL_QUEUE_FAIL		23
#define DBGS_GOT_SEND_EMPTY_QUEUE_FAIL		24
#define DBGS_GOT_SEND_FURTHER_SEND_FAIL		25
#define DBGS_FORWARDING				26

#define DBGS_GOT_RECEIVE			30
#define DBGS_GOT_RECEIVE_HEADER_NULL_FAIL	31
#define DBGS_GOT_RECEIVE_STATE_FAIL		32
#define DBGS_GOT_RECEIVE_FULL_QUEUE_FAIL	33
#define DBGS_GOT_RECEIVE_EMPTY_QUEUE_FAIL	34
#define DBGS_GOT_RECEIVE_FURTHER_SEND_FAIL	35
#define DBGS_GOT_RECEIVE_FORWARDING		36
#define DBGS_GOT_RECEIVE_TYPE_FAIL		37
#define DBGS_GOT_RECEIVE_DUPLICATE		38

#define DBGS_NEW_CHANNEL			40
#define DBGS_CHANNEL_RESET			41
#define DBGS_SYNC_PARAMS			42
#define DBGS_CHANNEL_TIMEOUT_NEXT		43
#define DBGS_CHANNEL_TIMEOUT_RESET		44
#define DBGS_SYNC_PARAMS_FAIL			45
#define DBGS_RADIO_START_V_REG			46
#define DBGS_RADIO_STOP_V_REG			47
#define DBGS_RADIO_ON_PERIOD			48

#define DBGS_NOT_ACKED_RESEND			50
#define DBGS_NOT_ACKED_FAILED			51
#define DBGS_NOT_ACKED				52
#define DBGS_ACKED				53

#define DBGS_SEND_CONTROL_MSG			101
#define DBGS_RECEIVE_CONTROL_MSG		102
#define DBGS_RECEIVE_FIRST_CONTROL_MSG		103
#define DBGS_RECEIVE_UNKNOWN_CONTROL_MSG	104
#define DBGS_RECEIVE_LOWER_CONTROL_MSG		105
#define DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG	106
#define DBGS_RECEIVE_HIGHER_CONTROL_MSG		107



#define DBGS_TEST_SIGNAL	32767

#endif
