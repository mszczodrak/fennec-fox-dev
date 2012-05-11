#ifndef PRINTF_CAPE_FOX
#define PRINTF_CAPE_FOX

int printf(const char *format, ...)
{

#ifdef ENABLE_CAPE_PRINTF
    va_list arg;

    va_start (arg, format);
    dbg("CapeFoxPrintf", format, arg);
    va_end (arg);
#endif

  return 0;
}

#endif
