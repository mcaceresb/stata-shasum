#ifndef SHASUM_H
#define SHASUM_H    1

#include "gttypes.h"
#include "spi/stplugin.h"
#include "common/sf_wrappers.c"

#include <openssl/md5.h>
#include <openssl/sha.h>
#include <inttypes.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#ifdef __APPLE__
#else
void * memcpy (void *dest, const void *src, size_t n);

/**
 * @brief Implement memcpy as a dummy function for memset (not on OSX)
 *
 * Stata requires plugins to be compied as shared executables. Since
 * this is being compiled on a relatively new linux system (by 2017
 * standards), some of the dependencies set in this way cannot be
 * fulfilled by older Linux systems. In particular, using memcpy as
 * provided by my system creates a dependency to Glib 2.14, which cannot
 * be fulfilled on some older systems (notably the servers where I
 * intend to use the plugin; hence I implement memcpy and get rid of
 * that particular dependency).
 *
 * @param dest pointer to place in memory to copy @src
 * @param src pointer to place in memory that is source of data
 * @param n how many bytes to copy
 * @return move @src to @dest
 */
void * memcpy (void *dest, const void *src, size_t n)
{
    return memmove(dest, src, n);
}
#endif

// #include <math.h>
// #include <stdio.h>
// #include <limits.h>
// #include <stdint.h>
// #include <sys/types.h>

// Some useful macros
#define SHASUM_CHAR(cvar, len)                   \
    char *(cvar) = malloc(sizeof(char) * (len)); \
    memset ((cvar), '\0', sizeof(char) * (len))

#define SHASUM_MIN(x, N, min, _i)             \
    typeof (*x) (min) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
    }                                         \

#define SHASUM_MAX(x, N, max, _i)             \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

#define SHASUM_MINMAX(x, N, min, max, _i)     \
    typeof (*x) (min) = *x;                   \
    typeof (*x) (max) = *x;                   \
    for (_i = 1; _i < N; ++_i) {              \
        if (min > *(x + _i)) min = *(x + _i); \
        if (max < *(x + _i)) max = *(x + _i); \
    }                                         \

#define SHASUM_PWMAX(a, b) ( (a) > (b) ? (a) : (b) )
#define SHASUM_PWMIN(a, b) ( (a) > (b) ? (b) : (a) )

// Container structure for Stata-provided info
struct StataInfo {
    GT_size in1;
    GT_size in2;
    GT_size N;
    GT_size Nread;
    GT_size strmax;
    GT_size rowbytes;
    GT_size strbuffer;
    GT_size free;
    //
    GT_bool any_if;
    GT_bool verbose;
    GT_bool debug;
    GT_bool benchmark;
    GT_bool concat;
    GT_bool flist;
    //
    GT_size kvars_sources;
    GT_size kvars_targets;
    GT_size kvars_num;
    GT_size kvars_str;
    GT_size lpath;
    //
    GT_size *inlens;
    GT_size *outlens;
    GT_size *shalens;
    GT_size *shacodes;
    GT_size *positions;
    //
    GT_size *index;
    GT_size *rowix;
    unsigned char *st_hash;
    char *st_charx;
};

// Main functions
ST_retcode ssf_parse_info   (struct StataInfo *st_info, int level);
ST_retcode ssf_read_varlist (struct StataInfo *st_info, int level);
ST_retcode ssf_hash_varlist (struct StataInfo *st_info, int level);
void ssf_free (struct StataInfo *st_info);


#endif /* shasum.h */
