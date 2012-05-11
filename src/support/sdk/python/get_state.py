
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

        if (state == S_ACK_WAIT):
		return "Wait ACK"

        if (state == S_RECEIVING):
		return "Transmitting"

	return "UNKNOWN"



