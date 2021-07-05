/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef PILOT_EW_H
#  define PILOT_EW_H


#include "pilot.h"



/*
 * Sensors and range.
 */
int pilot_inRange( const Pilot *p, double x, double y );
int pilot_inRangePilot( const Pilot *p, const Pilot *target, double *dist);
int pilot_inRangePlanet( const Pilot *p, int target );
int pilot_inRangeAsteroid( const Pilot *p, int ast, int fie );
int pilot_inRangeJump( const Pilot *p, int target );

/*
 * Weapon tracking.
 */
double pilot_weaponTrack(
      const Pilot *p, const Pilot *t, double track_optimal, double track_max );



#endif /* PILOT_EW_H */
