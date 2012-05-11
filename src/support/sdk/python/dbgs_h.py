#!/usr/bin/python
# Author: Marcin Szczodrak
# Constants defined in Dbgs.h as Python Module

DBGS_SEND_DATA       			= 1
DBGS_SEND_BEACON    			= 2
DBGS_RECEIVE_DATA     			= 3
DBGS_RECEIVE_BEACON 			= 4

DBGS_MGMT_START         		= 5
DBGS_MGMT_STOP          		= 6

DBGS_MEMORY_EMPTY       		= 7
DBGS_BLINK_LED				= 8

DBGS_GOT_SEND                           = 20
DBGS_GOT_SEND_HEADER_NULL_FAIL          = 21
DBGS_GOT_SEND_STATE_FAIL                = 22
DBGS_GOT_SEND_FULL_QUEUE_FAIL           = 23
DBGS_GOT_SEND_EMPTY_QUEUE_FAIL          = 24
DBGS_GOT_SEND_FURTHER_SEND_FAIL         = 25
DBGS_FORWARDING				= 26

DBGS_GOT_RECEIVE                        = 30
DBGS_GOT_RECEIVE_HEADER_NULL_FAIL       = 31
DBGS_GOT_RECEIVE_STATE_FAIL             = 32
DBGS_GOT_RECEIVE_FULL_QUEUE_FAIL        = 33
DBGS_GOT_RECEIVE_EMPTY_QUEUE_FAIL       = 34
DBGS_GOT_RECEIVE_FURTHER_SEND_FAIL      = 35
DBGS_GOT_RECEIVE_FORWARDING             = 36
DBGS_GOT_RECEIVE_TYPE_FAIL              = 37
DBGS_GOT_RECEIVE_DUPLICATE              = 38

DBGS_NEW_CHANNEL                        = 40
DBGS_CHANNEL_RESET                      = 41
DBGS_SYNC_PARAMS                        = 42
DBGS_CHANNEL_TIMEOUT_NEXT               = 43
DBGS_CHANNEL_TIMEOUT_RESET              = 44
DBGS_SYNC_PARAMS_FAIL              	= 45
DBGS_RADIO_START_V_REG                  = 46
DBGS_RADIO_STOP_V_REG                   = 47
DBGS_RADIO_ON_PERIOD                   	= 48

DBGS_NOT_ACKED_RESEND                   = 50
DBGS_NOT_ACKED_FAILED                   = 51
DBGS_NOT_ACKED                          = 52
DBGS_ACKED                              = 53

DBGS_SEND_CONTROL_MSG                   = 101
DBGS_RECEIVE_CONTROL_MSG                = 102
DBGS_RECEIVE_FIRST_CONTROL_MSG          = 103
DBGS_RECEIVE_UNKNOWN_CONTROL_MSG        = 104
DBGS_RECEIVE_LOWER_CONTROL_MSG          = 105
DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG   = 106
DBGS_RECEIVE_HIGHER_CONTROL_MSG         = 107


DBGS_TEST_SIGNAL        		= 32767


