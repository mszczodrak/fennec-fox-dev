configuration CachesC {
provides interface Fennec;
  provides interface SimpleStart;
  provides interface EventCache;
  provides interface PolicyCache;
}

implementation {
  components CachesP;
  SimpleStart = CachesP;
Fennec = CachesP;
  EventCache = CachesP;
  PolicyCache = CachesP;
}
