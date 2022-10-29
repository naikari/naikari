/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef NTIME_H
#  define NTIME_H


/** @cond */
#include <stdint.h>
/** @endcond */


#define NT_YEAR_DAYS (360) /**< galactic days in a galactic year */
#define NT_DAY_HOURS (10) /**< galactic hours in a galactic day */
#define NT_HOUR_MINUTES (100) /**< galactic minutes in a galactic hour */
#define NT_MINUTE_SECONDS (100) /**< galactic seconds in a galactic minute */

/** galactic hours in a galactic year */
#define NT_YEAR_HOURS ((ntime_t)NT_YEAR_DAYS*(ntime_t)NT_DAY_HOURS)
/** galactic seconds in a galactic hour */
#define NT_HOUR_SECONDS ((ntime_t)NT_HOUR_MINUTES*(ntime_t)NT_MINUTE_SECONDS)
/** galactic seconds in a galactic day */
#define NT_DAY_SECONDS ((ntime_t)NT_HOUR_SECONDS*(ntime_t)NT_DAY_HOURS)


typedef int64_t ntime_t; /**< Core time type. */

/* Create. */
ntime_t ntime_create(int year, int day, int second);

/* update */
void ntime_update( double dt );

/* get */
ntime_t ntime_get (void);
void ntime_getR(int *years, int *days, int *seconds, double *rem);
int ntime_getYears(ntime_t t);
int ntime_getDays(ntime_t t);
int ntime_getSeconds(ntime_t t);
double ntime_convertSeconds( ntime_t t );
double ntime_getRemainder( ntime_t t );
char* ntime_pretty( ntime_t t, int d );
void ntime_prettyBuf( char *str, int max, ntime_t t, int d );

/* set */
void ntime_set( ntime_t t );
void ntime_setR(int years, int days, int seconds, double rem);
void ntime_inc( ntime_t t );
void ntime_incLagged( ntime_t t );

/* misc */
void ntime_refresh (void);
void ntime_allowUpdate( int enable );


#endif /* NTIME_H */
