configuration CachesC {
provides interface SimpleStart;
provides interface Fennec;
provides interface FennecWarnings;
}

implementation {

components CachesP;
SimpleStart = CachesP;
Fennec = CachesP;
FennecWarnings = CachesP;

components NetworkSchedulerC;
CachesP.SplitControl -> NetworkSchedulerC;

}
