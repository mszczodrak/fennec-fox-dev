
from fennec_h import *
from dbgs_h import *


def get_state(state):
	
        if (state == S_NONE):
                return "None"

        if (state == S_STOPPED):
                return "Stopped"

        if (state == S_STARTING):
                return "Starting"

        if (state == S_STARTED):
                return "Started"

        if (state == S_STOPPING):
                return "Stopping"

        if (state == S_TRANSMITTING):
		return "Transmitting"

        if (state == S_LOADING):
		return "Loading"

        if (state == S_LOADED):
		return "Loaded"

        if (state == S_CANCEL):
		return "Cancel"

        if (state == S_ACK_WAIT):
		return "Wait ACK"

        if (state == S_SAMPLE_CCA):
		return "Sample CCA"

        if (state == S_SENDING_ACK):
		return "Sending ACK"

        if (state == S_NOT_ACKED):
		return "Not Acked"

        if (state == S_BROADCASTING):
		return "Broadcasting"

        if (state == S_HALTED):
		return "Halted"

        if (state == S_BRIDGE_DELAY):
		return "Bridge Delay"

        if (state == S_DISCOVER_DELAY):
		return "Discover Delay"

        if (state == S_INIT):
		return "Init"

        if (state == S_SYNC):
		return "Sync"

        if (state == S_SYNC_SEND):
		return "Sync Send"

        if (state == S_SYNC_RECEIVE):
		return "Sync Receive"

        if (state == S_SEND_DONE):
		return "Send Done"

        if (state == S_SLEEPING):
		return "Sleeping"

        if (state == S_OPERATIONAL):
		return "Operational"

        if (state == S_TURN_ON):
		return "Turn On"

        if (state == S_TURN_OFF):
		return "Turn Off"

        if (state == S_PREAMBLE):
		return "Preamble"

        if (state == S_RECEIVING):
		return "Transmitting"

        if (state == S_BEGIN_TRANSMIT):
		return "Begin TX"

        if (state == S_LOAD):
		return "Loading"

        if (state == S_RECONFIGURING):
		return "Reconfiguring"

        if (state == S_RECONF_ENABLED):
		return "Rec Enabled"

        if (state == S_COMPLETED):
		return "Completed"

        if (state == S_BUSY):
		return "Busy"

        if (state == S_SERIAL):
		return "Serial"

        if (state == S_NEW_STATE):
		return "New State"

        if (state == S_RESET):
		return "Reset"

        if (state == S_ERROR):
		return "Error"



        if (state == S_SFD):
		return "SFD"

        if (state == S_EFD):
		return "EFD"

        if (state == S_RX_LENGTH):
		return "RX LEN"

        if (state == S_RX_FCF):
		return "RX FCF"

        if (state == S_RX_PAYLOAD):
		return "RX Payload"

	return "UNKNOWN"



