
from fennec_h import *
from dbgs_h import *


def get_action(action):
        if (action == DBGS_SEND_DATA):
                return "Send Data"

        if (action == DBGS_SEND_BEACON):
                return "Send Beacon"

        if (action == DBGS_RECEIVE_DATA):
                return "Receive Data"

        if (action == DBGS_RECEIVE_BEACON):
                return "Receive Beacon"



        if (action == DBGS_MGMT_START):
                return "Starting Module"

	if (action == DBGS_MGMT_STOP):
		return "Stopping Module"



	if (action == DBGS_MEMORY_EMPTY):
		return "No memory left"

	if (action == DBGS_BLINK_LED):
		return "Blink LED"

	if (action == DBGS_TEST_SIGNAL):
		return "Send Test Signal"



        if (action == DBGS_GOT_SEND):
                return "Got Send"

        if (action == DBGS_GOT_SEND_HEADER_NULL_FAIL):
                return "Got Send: Header Null Fail"

        if (action == DBGS_GOT_SEND_STATE_FAIL):
                return "Got Send: State Fail"

        if (action == DBGS_GOT_SEND_FULL_QUEUE_FAIL):
                return "Got Send: Full Queue Fail"

        if (action == DBGS_GOT_SEND_EMPTY_QUEUE_FAIL):
                return "Got Send: Send Empty Queue Fail"

        if (action == DBGS_GOT_SEND_FURTHER_SEND_FAIL):
                return "Got Send: Further Send Fail"

	if (action == DBGS_FORWARDING):
		return "Send-Forwarding"



        if (action == DBGS_GOT_RECEIVE):
                return "Got Receive"

        if (action == DBGS_GOT_RECEIVE_HEADER_NULL_FAIL):
                return "Got Receive: Header Null Fail"

        if (action == DBGS_GOT_RECEIVE_STATE_FAIL):
                return "Got Receive: State Fail"

        if (action == DBGS_GOT_RECEIVE_FULL_QUEUE_FAIL):
                return "Got Receive: Full Queue Fail"

        if (action == DBGS_GOT_RECEIVE_EMPTY_QUEUE_FAIL):
                return "Got Receive: Empty Queue Fail"

        if (action == DBGS_GOT_RECEIVE_FURTHER_SEND_FAIL):
                return "Got Receive: Further Send Fail"

        if (action == DBGS_GOT_RECEIVE_FORWARDING):
                return "Got Receive: Forwarding"

        if (action == DBGS_GOT_RECEIVE_TYPE_FAIL):
                return "Got Receive: Type Fail"

        if (action == DBGS_GOT_RECEIVE_DUPLICATE):
                return "Got Receive: Duplicate"



        if (action == DBGS_NEW_CHANNEL):
                return "New Channel"

        if (action == DBGS_CHANNEL_RESET):
                return "Channel Reset"

        if (action == DBGS_SYNC_PARAMS):
                return "Sync Params"

        if (action == DBGS_RADIO_START_V_REG):
                return "Start VReg"

        if (action == DBGS_RADIO_STOP_V_REG):
                return "Stop VReg"

        if (action == DBGS_RADIO_ON_PERIOD):
                return "Radio On"



        if (action == DBGS_CHANNEL_TIMEOUT_NEXT):
                return "Channel Timeout-Next"

        if (action == DBGS_CHANNEL_TIMEOUT_RESET):
                return "Channel Timeout-Reset"

        if (action == DBGS_SYNC_PARAMS_FAIL):
                return "Sync Params Fail"




        if (action == DBGS_NOT_ACKED_RESEND):
                return "Not Acked - Resend"

        if (action == DBGS_NOT_ACKED_FAILED):
                return "Not Acked - Failed"

        if (action == DBGS_NOT_ACKED):
                return "Not Acked"

        if (action == DBGS_ACKED):
                return "Acked"


        if (action == DBGS_SEND_CONTROL_MSG):
                return "Send Ctrl Msg"

        if (action == DBGS_RECEIVE_CONTROL_MSG):
                return "Receive Ctrl Msg"

        if (action == DBGS_RECEIVE_FIRST_CONTROL_MSG):
                return "Receive Ctrl FirstMsg"

        if (action == DBGS_RECEIVE_UNKNOWN_CONTROL_MSG):
                return "Receive Ctrl UnMsg"

        if (action == DBGS_RECEIVE_LOWER_CONTROL_MSG):
                return "Receive Ctrl LowMsg"

        if (action == DBGS_RECEIVE_INCONSISTENT_CONTROL_MSG):
                return "Receive Ctrl InMsg"

        if (action == DBGS_RECEIVE_HIGHER_CONTROL_MSG):
                return "Receive Ctrl HiMsg"

        if (action == DBGS_RECEIVE_WRONG_CONF_MSG):
                return "Receive Wrong Conf"

	return "UNKNOWN"

