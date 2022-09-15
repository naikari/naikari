/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef NTIME_H
#  define NTIME_H


/** @cond */
#include <stdint.h>
/** @endcond */


#define NT_YEAR_HOURS (3600) /**< galactic hours in a galactic year */
#define NT_HOUR_SECONDS (10000) /**< galactic seconds in a galactic hour */


typedef int64_t ntime_t; /**< Core time type. */

/* Create. */
ntime_t ntime_create(int year, int hour, int second);

/* update */
void ntime_update( double dt );

/* get */
ntime_t ntime_get (void);
void ntime_getR(int *years, int *hours, int *seconds, double *rem);
int ntime_getYears(ntime_t t);
int ntime_getHours(ntime_t t);
int ntime_getSeconds(ntime_t t);
double ntime_convertSeconds( ntime_t t );
double ntime_getRemainder( ntime_t t );
char* ntime_pretty( ntime_t t, int d );
void ntime_prettyBuf( char *str, int max, ntime_t t, int d );

/* set */
void ntime_set( ntime_t t );
void ntime_setR( int cycles, int periods, int seconds, double rem );
void ntime_inc( ntime_t t );
void ntime_incLagged( ntime_t t );

/* misc */
void ntime_refresh (void);
void ntime_allowUpdate( int enable );


#endif /* NTIME_H */
