#ifndef GTTYPES_H
#define GTTYPES_H

#include <inttypes.h>

typedef uint8_t   GT_bool ;
typedef uint64_t  GT_size ;
typedef int64_t   GT_int  ;

#if defined(_WIN64) || defined(_WIN32)
#    define GT_size_cfmt "%" PRIu64
#    define GT_size_sfmt PRIu64
#    define GT_int_cfmt  "%" PRId64
#    define GT_int_sfmt  PRId64
#else
#    define GT_size_cfmt "%'" PRIu64
#    define GT_size_sfmt PRIu64
#    define GT_int_cfmt  "%'" PRId64
#    define GT_int_sfmt  PRId64
#endif

#endif
