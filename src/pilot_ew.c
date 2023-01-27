/*
 * See Licensing and Copyright notice in naev.h
 */


/**
 * @file pilot_ew.c
 *
 * @brief Pilot electronic warfare information.
 */



/** @cond */
#include <assert.h>
#include <math.h>

#include "naev.h"
/** @endcond */

#include "log.h"
#include "pilot.h"
#include "player.h"
#include "space.h"



/**
 * @brief Check to see if a position is in range of the pilot.
 *
 *    @param p Pilot to check to see if position is in their sensor range.
 *    @param x X position to check.
 *    @param y Y position to check.
 *    @return 1 if the position is in range, 0 if it isn't.
 */
int pilot_inRange( const Pilot *p, double x, double y )
{
   double d, sense;

   /* Get distance. */
   d = hypot(x - p->solid->pos.x, y - p->solid->pos.y);

   sense = p->rdr_range * cur_system->rdr_range_mod;
   if (d < sense)
      return 1;

   return 0;
}


/**
 * @brief Check to see if a pilot is in sensor range of another.
 *
 *    @param p Pilot who is trying to check to see if other is in sensor range.
 *    @param target Target of p to check to see if is in sensor range.
 *    @param[out] dist Distance of the two pilots. Set to NULL if you're not interested.
 *    @return 1 if they are in range, 0 if they aren't and -1 if they are detected fuzzily.
 */
int pilot_inRangePilot( const Pilot *p, const Pilot *target, double *dist)
{
   double d, sense, tempmod;

   /* Get distance. */
   d = vect_dist(&p->solid->pos, &target->solid->pos);
   if (dist != NULL)
      *dist = d;

   /* Special case player or omni-visible. */
   if ((pilot_isPlayer(p) && pilot_isFlag(target, PILOT_VISPLAYER)) ||
         pilot_isFlag(target, PILOT_VISIBLE) ||
         target->parent == p->id)
      return 1;
   
   tempmod = (1 - ((target->heat_T-CONST_SPACE_STAR_TEMP)
            / (target->heat_C-CONST_SPACE_STAR_TEMP)));

   sense = (p->rdr_range * cur_system->rdr_range_mod
         * target->stats.rdr_enemy_range_mod * tempmod);
   if (d < sense)
      return 1;
   else if (d < sense * 1.1)
      return -1;

   return 0;
}


/**
 * @brief Check to see if a planet is in sensor range of the pilot.
 *
 *    @param p Pilot who is trying to check to see if the planet is in sensor range.
 *    @param target Planet to see if is in sensor range.
 *    @return 1 if they are in range, 0 if they aren't.
 */
int pilot_inRangePlanet( const Pilot *p, int target )
{
   double d;
   Planet *pnt;
   double sense;

   /* pilot must exist */
   if (p == NULL)
      return 0;

   /* Get the planet. */
   pnt = cur_system->planets[target];

   /* target must not be virtual */
   if (!pnt->real)
      return 0;

   /* Get distance. */
   d = vect_dist(&p->solid->pos, &pnt->pos);

   sense = p->rdr_range * cur_system->rdr_range_mod * pnt->rdr_range_mod;
   if (d < sense)
      return 1;

   return 0;
}


/**
 * @brief Check to see if an asteroid is in sensor range of the pilot.
 *
 *    @param p Pilot who is trying to check to see if the asteroid is in sensor range.
 *    @param ast Asteroid to see if is in sensor range.
 *    @param fie Field the Asteroid belongs to to see if is in sensor range.
 *    @return 1 if they are in range, 0 if they aren't.
 */
int pilot_inRangeAsteroid( const Pilot *p, int ast, int fie )
{
   double d;
   Asteroid *as;
   AsteroidAnchor *f;
   double sense;

   /* pilot must exist */
   if (p == NULL)
      return 0;

   /* Get the asteroid. */
   f = &cur_system->asteroids[fie];
   as = &f->asteroids[ast];

   /* Get distance. */
   d = vect_dist(&p->solid->pos, &as->pos);

   sense = p->rdr_range * cur_system->rdr_range_mod;
   if (d < sense)
      return 1;

   return 0;
}


/**
 * @brief Check to see if a jump point is in sensor range of the pilot.
 *
 *    @param p Pilot who is trying to check to see if the jump point is in sensor range.
 *    @param i target Jump point to see if is in sensor range.
 *    @return 1 if they are in range, 0 if they aren't.
 */
int pilot_inRangeJump( const Pilot *p, int i )
{
   double d;
   JumpPoint *jp;
   double sense;

   /* pilot must exist */
   if (p == NULL)
      return 0;

   /* Get the jump point. */
   jp = &cur_system->jumps[i];

   /* We don't want exit-only jumps. */
   if (jp_isFlag(jp, JP_EXITONLY))
      return 0;

   /* We don't want hidden jumps. */
   if (jp_isFlag(jp, JP_HIDDEN))
      return 0;

   /* Immediate success if express. */
   if (jp_isFlag(jp, JP_EXPRESS))
      return 1;

   /* Get distance. */
   d = vect_dist(&p->solid->pos, &jp->pos);

   sense = p->rdr_jump_range * cur_system->rdr_range_mod * jp->rdr_range_mod;
   if (d < sense)
      return 1;

   return 0;
}


/**
 * @brief Calculates the weapon lead (1. is 100%, 0. is 0%).
 *
 *    @param p Pilot tracking.
 *    @param t Pilot being tracked.
 *    @param track_optimal Optimal tracking distance.
 *    @param track_max Maximum tracking distance.
 */
double pilot_weaponTrack(
      const Pilot *p, const Pilot *t, double track_optimal, double track_max )
{
   double d;
   double tempmod, mod;
   double sense, sense_max;

   /* pilot must exist */
   if ((p == NULL) || (t == NULL))
      return 0.;

   d = vect_dist(&p->solid->pos, &t->solid->pos);
   
   tempmod = (1 - ((t->heat_T-CONST_SPACE_STAR_TEMP)
            / (t->heat_C-CONST_SPACE_STAR_TEMP)));
   mod = (cur_system->rdr_range_mod * p->stats.rdr_range_mod
         * t->stats.rdr_enemy_range_mod * tempmod);

   sense = track_optimal * mod;
   sense_max = track_max * mod;

   if (d >= sense_max)
      return 0.;

   if (d <= sense)
      return 1.;

   /* It shouldn't be possible to get here if sense_max is not greater
    * than sense, because in all such cases, one of the above two checks
    * should return true. */
   assert(sense_max > sense);

   return CLAMP(0., 1., 1. - (d-sense) / (sense_max-sense));
}
