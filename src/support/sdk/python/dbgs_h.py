#!/usr/bin/python
# Author: Marcin Szczodrak
# Constants defined in Dbgs.h as Python Module

DBGS_NONE				= 0
DBGS_SEND_DATA       			= 1
DBGS_SEND_BEACON    			= 2
DBGS_RECEIVE_DATA     			= 3
DBGS_RECEIVE_BEACON 			= 4

DBGS_MGMT_START         		= 5
DBGS_MGMT_STOP          		= 6

DBGS_START				= 7
DBGS_START_DONE				= 8
DBGS_STOP				= 9
DBGS_STOP_DONE 				= 10

DBGS_LED_ON				= 15
DBGS_LED_OFF				= 16

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
DBGS_RADIO_START                        = 46
DBGS_RADIO_START_DONE                   = 47
DBGS_RADIO_STOP                         = 48
DBGS_RADIO_STOP_DONE                    = 49

DBGS_NOT_ACKED_RESEND                   = 50
DBGS_NOT_ACKED_FAILED                   = 51
DBGS_NOT_ACKED                          = 52
DBGS_ACKED                              = 53
DBGS_CONGESTION				= 54

DBGS_STATUS_UPDATE			= 60

DBGS_ADD_NODE				= 70
DBGS_REMOVE_NODE			= 71

DBGS_SEND_CONTROL_MSG                   = 101
DBGS_RECEIVE_CONTROL_MSG                = 102
DBGS_RECEIVE_FIRST_CONTROL_MSG          = 103
DBGS_RECEIVE_UNKNOWN_CONTROL_MSG        = 104
DBGS_RECEIVE_LOWER_CONTROL_MSG          = 105
DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG   = 106
DBGS_RECEIVE_HIGHER_CONTROL_MSG         = 107
DBGS_RECEIVE_WRONG_CONF_MSG		= 108
DBGS_RECEIVE_AND_RECONFIGURE		= 109
DBGS_SEND_CONTROL_MSG_FAILED            = 110

DBGS_ERROR				= 130
DBGS_ERROR_SEND_DONE			= 131
DBGS_ERROR_RECEIVE			= 132

DBGS_TIMER_FIRED                        = 160
DBGS_BUSY                               = 161
DBGS_TIMER_SETUP			= 162
DBGS_NEW_LOCAL_PAYLOAD			= 163
DBGS_NEW_REMOTE_PAYLOAD			= 164

DBGS_START_PERIOD			= 165
DBGS_FINISH_PERIOD			= 166
DBGS_SIGNAL_FINISH_PERIOD		= 167

DBGS_SAME_LOCAL_PAYLOAD			= 168
DBGS_SAME_REMOTE_PAYLOAD		= 169

DBGS_SERIAL_SEND_MESSAGE                = 190
DBGS_SERIAL_SEND_FAIL                   = 191
DBGS_SERIAL_QUEUE_FULL                  = 192
DBGS_SERIAL_NULL_PTR                    = 193

DBGS_NETWORK_ROUTING_UPDATE		= 199

DBGS_TEST_SIGNAL        		= 32767


def dbg_translate(dbg_num):
	if dbg_num == DBGS_NONE:
		return "None"

	if dbg_num == DBGS_SEND_DATA:
		return "Send Data"

	if dbg_num == DBGS_SEND_BEACON:
		return "Send Beacon"

	if dbg_num == DBGS_RECEIVE_DATA:
		return "Receive Data"

	if dbg_num == DBGS_RECEIVE_BEACON:
		return "Receive Beacon"

	if dbg_num == DBGS_MGMT_START:
		return "Mgmt Start"

	if dbg_num == DBGS_MGMT_STOP:
		return "Mgmt Stop"

	if dbg_num == DBGS_START:
		return "Start"

	if dbg_num == DBGS_START_DONE:
		return "Start Done"

	if dbg_num == DBGS_STOP:
		return "Stop"

	if dbg_num == DBGS_STOP_DONE:
		return "Stop Done"

	if dbg_num == DBGS_LED_ON:
		return "Led On"

	if dbg_num == DBGS_LED_OFF:
		return "Led Off"

	if dbg_num == DBGS_GOT_SEND:
		return "Got Send"

	if dbg_num == DBGS_GOT_SEND_HEADER_NULL_FAIL:
		return "Got Send Header Null Fail"

	if dbg_num == DBGS_GOT_SEND_STATE_FAIL:
		return "Got Send State Fail"

	if dbg_num == DBGS_GOT_SEND_FULL_QUEUE_FAIL:
		return "Got Send Full Queue Fail"

	if dbg_num == DBGS_GOT_SEND_EMPTY_QUEUE_FAIL:
		return "Got Send Empty Queue Fail"

	if dbg_num == DBGS_GOT_SEND_FURTHER_SEND_FAIL:
		return "Got Send Further Send Fail"

	if dbg_num == DBGS_FORWARDING:
		return "Forwarding"

	if dbg_num == DBGS_GOT_RECEIVE:
		return "Got Receive"

	if dbg_num == DBGS_GOT_RECEIVE_HEADER_NULL_FAIL:
		return "Got Receive Header Null Fail"

	if dbg_num == DBGS_GOT_RECEIVE_STATE_FAIL:
		return "Got Receive State Fail"

	if dbg_num == DBGS_GOT_RECEIVE_FULL_QUEUE_FAIL:
		return "Got Receive Full Queue Fail"

	if dbg_num == DBGS_GOT_RECEIVE_EMPTY_QUEUE_FAIL:
		return "Got Receive Empty Queue Fail"

	if dbg_num == DBGS_GOT_RECEIVE_FURTHER_SEND_FAIL:
		return "Got Receive Further Send Fail"

	if dbg_num == DBGS_GOT_RECEIVE_FORWARDING:
		return "Got Receive Forwarding"

	if dbg_num == DBGS_GOT_RECEIVE_TYPE_FAIL:
		return "Got Receive Type Fail"

	if dbg_num == DBGS_GOT_RECEIVE_DUPLICATE:
		return "Got Receive Duplicate"

	if dbg_num == DBGS_NEW_CHANNEL:
		return "New Channel"

	if dbg_num == DBGS_CHANNEL_RESET:
		return "Channel Reset"

	if dbg_num == DBGS_SYNC_PARAMS:
		return "Sync Params"

	if dbg_num == DBGS_CHANNEL_TIMEOUT_NEXT:
		return "Channel Timeout Next"

	if dbg_num == DBGS_CHANNEL_TIMEOUT_RESET:
		return "Channel Timeout Reset"

	if dbg_num == DBGS_SYNC_PARAMS_FAIL:
		return "Sync Params Fail"

	if dbg_num == DBGS_RADIO_START:
		return "Radio Start"

	if dbg_num == DBGS_RADIO_START_DONE:
		return "Radio Start Done"

	if dbg_num == DBGS_RADIO_STOP:
		return "Radio Stop"

	if dbg_num == DBGS_RADIO_STOP_DONE:
		return "Radio Stop Done"

	if dbg_num == DBGS_NOT_ACKED_RESEND:
		return "Not Acked Resend"

	if dbg_num == DBGS_NOT_ACKED_FAILED:
		return "Not Acked Failed"

	if dbg_num == DBGS_NOT_ACKED:
		return "Not Acked"

	if dbg_num == DBGS_CONGESTION:
		return "Congestion"

	if dbg_num == DBGS_STATUS_UPDATE:
		return "Status Update"

	if dbg_num == DBGS_ADD_NODE:
		return "Add Node"

	if dbg_num == DBGS_REMOVE_NODE:
		return "Remove Node"

	if dbg_num == DBGS_SEND_CONTROL_MSG:
		return "Send Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_CONTROL_MSG:
		return "Receive Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_FIRST_CONTROL_MSG:
		return "Receive First Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_UNKNOWN_CONTROL_MSG:
		return "Receive Unknown Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_LOWER_CONTROL_MSG:
		return "Receive Lower Ctrl Msg"
		
	if dbg_num == DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG:
		return "Receive Inconsistent Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_HIGHER_CONTROL_MSG:
		return "Receive Higher Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_WRONG_CONF_MSG:
		return "Receive Wrong Ctrl Msg"

	if dbg_num == DBGS_RECEIVE_AND_RECONFIGURE:
		return "Receive and Reconfigure"

	if dbg_num == DBGS_SEND_CONTROL_MSG_FAILED:
		return "Send Ctrl Msg Failed"

	if dbg_num == DBGS_ERROR:
		return "Error"

	if dbg_num == DBGS_ERROR_SEND_DONE:
		return "Error Send Done"

	if dbg_num == DBGS_ERROR_RECEIVE:
		return "Error Receive"

	if dbg_num == DBGS_TIMER_FIRED:
		return "Timer Fired"

	if dbg_num == DBGS_BUSY:
		return "Busy"

	if dbg_num == DBGS_TIMER_SETUP:
		return "Timer Setup"

	if dbg_num == DBGS_NEW_LOCAL_PAYLOAD:
		return "New Local Payload"

	if dbg_num == DBGS_NEW_REMOTE_PAYLOAD:
		return "New Remote Payload"

	if dbg_num == DBGS_START_PERIOD:
		return "Start Period"

	if dbg_num == DBGS_FINISH_PERIOD:
		return "Finish Period"

	if dbg_num == DBGS_SAME_LOCAL_PAYLOAD:
		return "Same Local Payload"

	if dbg_num == DBGS_SAME_REMOTE_PAYLOAD:
		return "Same Remote Payload"

	if dbg_num == DBGS_SIGNAL_FINISH_PERIOD:
		return "Signal Finish Period"

	if dbg_num == DBGS_SERIAL_SEND_MESSAGE:
		return "Serial Send Message"

	if dbg_num == DBGS_SERIAL_SEND_FAIL:
		return "Serial Send Fail"

	if dbg_num == DBGS_SERIAL_QUEUE_FULL:
		return "Serial Queue Fail"

	if dbg_num == DBGS_SERIAL_NULL_PTR:
		return "Serial Null Ptr"

	if dbg_num == DBGS_NETWORK_ROUTING_UPDATE:
		return "Network Routing Update"

	if dbg_num == DBGS_TEST_SIGNAL:
		return "Test Signal"

	return None


