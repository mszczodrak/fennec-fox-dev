configuration CachesC {
provides interface Fennec;
provides interface SimpleStart;
}

implementation {
components CachesP;
SimpleStart = CachesP;
Fennec = CachesP;

components NetworkSchedulerC;
CachesP.SplitControl -> NetworkSchedulerC;

}
