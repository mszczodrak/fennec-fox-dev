configuration CachesC {
provides interface Fennec;
provides interface SimpleStart;
provides interface EventCache;
}

implementation {
components CachesP;
SimpleStart = CachesP;
Fennec = CachesP;
EventCache = CachesP;

components NetworkSchedulerC;
CachesP.SplitControl -> NetworkSchedulerC;

}
