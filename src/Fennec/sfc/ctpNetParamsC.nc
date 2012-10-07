#include <Fennec.h>
#include "ctpNetParams.h"

module ctpNetParamsC {
	 provides interface ctpNetParams;
}

implementation {

	command void ctpNetParams.send_status(uint16_t status_flag) {
	}

	command uint16_t ctpNetParams.get_root() {
		return ctpNet_data.root;
	}

	command error_t ctpNetParams.set_root(uint16_t new_root) {
		ctpNet_data.root = new_root;
		return SUCCESS;
	}

}

