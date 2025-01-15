#ifndef _PILOT_LINK_EXPORT_H_
#define _PILOT_LINK_EXPORT_H_

#if defined(_WIN32) || defined(__CYGWIN__)
  #ifdef BUILDING_PISOCK
    #define PI_EXPORT __declspec(dllexport)
  #else
    #define PI_EXPORT __declspec(dllimport)
  #endif
#else
  #if __GNUC__ >= 4
    #define PI_EXPORT __attribute__ ((visibility ("default")))
  #else
    #define PI_EXPORT
  #endif
#endif

#endif /* _PILOT_LINK_EXPORT_H_ */
