

interface Write<val_t> {

command error_t write(val_t val);
event void writeDone(error_t result);

}
