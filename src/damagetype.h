/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef _DTYPE_H
#  define _DTYPE_H


#include "outfit.h"

/*
 * stack manipulation
 */
int dtype_get( char* name );
char* dtype_damageTypeToStr( int type );

/*
 * dtype effect loading and freeing
 */
int dtype_load (void);
void dtype_free (void);

/*
 * misc
 */
int dtype_raw(int type, double *shield, double *armour, double *knockback,
      double *recoil);
void dtype_calcDamage(double *dshield, double *darmour, double *knockback,
      double *recoil, double absorb, const Damage *dmg, const ShipStats *s);


#endif /* _DTYPE_H */

