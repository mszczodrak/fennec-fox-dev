#include <seh.h>
#include <sim_seh.h>

SEH::SEH() {}
SEH::~SEH() {}

double SEH::solarCellSize() {return sim_seh_solar_cell_size();}
double SEH::solarCellEfficiency() {return sim_seh_solar_cell_efficiency();}
/*
int MAC::high() {return sim_csma_high();}
int MAC::low() {return sim_csma_low();}
int MAC::symbolsPerSec() {return sim_csma_symbols_per_sec();}
int MAC::bitsPerSymbol() {return sim_csma_bits_per_symbol();}
int MAC::preambleLength() {return sim_csma_preamble_length();}
int MAC::exponentBase() {return sim_csma_exponent_base();}
int MAC::maxIterations() {return sim_csma_max_iterations();}
int MAC::minFreeSamples() {return sim_csma_min_free_samples();}
int MAC::rxtxDelay() {return sim_csma_rxtx_delay();}
int MAC::ackTime() {return sim_csma_ack_time();}
*/

void SEH::setSolarCellSize(double val) {sim_seh_set_solar_cell_size(val);}
void SEH::setSolarCellEfficiency(double val) {sim_seh_set_solar_cell_efficiency(val);}
/*
void MAC::setHigh(int val) {sim_csma_set_high(val);}
void MAC::setLow(int val) {sim_csma_set_low(val);}
void MAC::setSymbolsPerSec(int val) {sim_csma_set_symbols_per_sec(val);}
void MAC::setBitsBerSymbol(int val) {sim_csma_set_bits_per_symbol(val);}
void MAC::setPreambleLength(int val) {sim_csma_set_preamble_length(val);}
void MAC::setExponentBase(int val) {sim_csma_set_exponent_base(val);}
void MAC::setMaxIterations(int val) {sim_csma_set_max_iterations(val);}
void MAC::setMinFreeSamples(int val) {sim_csma_set_min_free_samples(val);}
void MAC::setRxtxDelay(int val) {sim_csma_set_rxtx_delay(val);}
void MAC::setAckTime(int val) {sim_csma_set_ack_time(val);}
*/

