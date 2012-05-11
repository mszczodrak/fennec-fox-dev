configuration CachesC {
  provides interface SimpleStart;
  provides interface EventCache;
  provides interface PolicyCache;
}

implementation {
  components CachesP;
  SimpleStart = CachesP;
  EventCache = CachesP;
  PolicyCache = CachesP;
}
