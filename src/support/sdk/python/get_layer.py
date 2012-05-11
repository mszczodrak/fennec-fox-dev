
from fennec_h import *
from dbgs_h import *


def get_layer(layer):
        if (layer == F_RADIO):
                return "Radio"

        if (layer == F_ADDRESSING):
                return "Addressing"

        if (layer == F_MAC):
                return "MAC"

        if (layer == F_QOI):
                return "QOI"

        if (layer == F_NETWORK):
                return "Network"

        if (layer == F_APPLICATION):
		return "Application"

        if (layer == F_SYSTEM):
		return "System"

        if (layer == F_MEMORY):
		return "Memory"

        if (layer == F_ENGINE):
		return "Engine"

        if (layer == F_CONTROL_UNIT):
		return "ControlUnit"

	return "UNKNOWN"



