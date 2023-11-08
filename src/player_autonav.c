/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file player_autonav.c
 *
 * @brief Contains all the player autonav related stuff.
 */


/** @cond */
#include <math.h>
#include <time.h>

#include "naev.h"
/** @endcond */

#include "player.h"

#include "array.h"
#include "board.h"
#include "conf.h"
#include "map.h"
#include "pause.h"
#include "pilot.h"
#include "pilot_ew.h"
#include "player.h"
#include "sound.h"
#include "space.h"
#include "toolkit.h"


extern double player_acc; /**< Player acceleration. */

static double tc_mod = 1.; /**< Time compression modifier. */
static double tc_down = 0.; /**< Rate of decrement. */
static int tc_rampdown = 0; /**< Ramping down time compression? */
static double lasts;
static double lasta;
static int hailed;
static int informed;

/*
 * Prototypes.
 */
static int player_autonavSetup (void);
static void player_autonavHyperspaceAbort(int show_message);
static void player_autonav (void);
static int player_autonavApproach( const Vector2d *pos, double *dist2, int count_target );
static void player_autonavFollow( const Vector2d *pos, const Vector2d *vel, const int follow, double *dist2 );
static int player_autonavApproachBoard( const Vector2d *pos, const Vector2d *vel, double *dist2, double sw );
static int player_autonavBrake (void);


/**
 * @brief Resets the game speed.
 */
void player_autonavResetSpeed (void)
{
   tc_mod = player_dt_default() * player.speed;
   player_resetSpeed();
}


/**
 * @brief Starts autonav.
 */
void player_autonavStart (void)
{
   /* Not under manual control or disabled. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ) ||
         pilot_isDisabled(player.p))
      return;

   if ((player.p->nav_hyperspace == -1) && (player.p->nav_planet== -1))
      return;
   else if ((player.p->nav_planet != -1) && !player_getHypPreempt()) {
      player_setFlag(PLAYER_BASICAPPROACH);
      player_autonavPnt(cur_system->planets[player.p->nav_planet]->name);
      return;
   }

   if (player.p->fuel < player.p->fuel_consumption) {
      player_message(_("#rNot enough fuel to jump for autonav."));
      return;
   }

   if (pilot_isFlag( player.p, PILOT_NOJUMP)) {
      player_message(_("#rHyperspace drive is offline."));
      return;
   }

   if (!player_autonavSetup())
      return;

   player_message(_("#oAutonav: auto-hyperspace sequence engaged."));
   player.autonav = AUTONAV_JUMP_APPROACH;
}


/**
 * @brief Prepares the player to enter autonav.
 *
 *    @return 1 on success, 0 on failure (disabled, etc.)
 */
static int player_autonavSetup (void)
{
   /* Not under manual control or disabled. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ) ||
         pilot_isDisabled(player.p))
      return 0;

   /* Autonav is mutually-exclusive with other autopilot methods. */
   player_restoreControl( PINPUT_AUTONAV, NULL );

   if (!player_isFlag(PLAYER_AUTONAV)) {
      tc_mod = player_dt_default() * player.speed;
      player.tc_max = player_dt_max();
   }

   /* Safe values. */
   free( player.autonavmsg );
   player.autonavmsg = NULL;
   tc_rampdown = 0;
   tc_down = 0.;
   lasts = player.p->shield / player.p->shield_max;
   lasta = player.p->armour / player.p->armour_max;
   hailed = 0;
   informed = 0;

   /* Set flag and tc_mod just in case. */
   player_setFlag(PLAYER_AUTONAV);
   pause_setSpeed(tc_mod);
   sound_setSpeed(tc_mod);

   /* Make sure time acceleration starts immediately. */
   player.autonav_timer = 0.;

   return 1;
}


/**
 * @brief Aborts hyperspacing if hyperspacing is in progress.
 *
 *    @param show_message Whether to show a message to the player.
 */
static void player_autonavHyperspaceAbort(int show_message)
{
   if (pilot_isFlag(player.p, PILOT_HYP_PREP)) {
      pilot_hyperspaceAbort(player.p);
      if (show_message)
         player_message(_("#oAutonav: auto-hyperspace sequence aborted."));
   }
}


/**
 * @brief Ends the autonav.
 */
void player_autonavEnd (void)
{
   player_rmFlag(PLAYER_AUTONAV);
   player_autonavResetSpeed();
   free( player.autonavmsg );
   player.autonavmsg = NULL;
   player_accelOver();
}


/**
 * @brief Starts autonav and closes the window.
 */
void player_autonavStartWindow(unsigned int wid, char *str)
{
   (void) str;
   player_hyperspacePreempt(1);
   player_autonavStart();
   window_destroy( wid );
}


/**
 * @brief Starts autonav with a local position destination.
 */
void player_autonavPos( double x, double y )
{
   if (!player_autonavSetup())
      return;

   /* Break possible hyperspacing. */
   player_autonavHyperspaceAbort(1);

   player.autonav = AUTONAV_POS_APPROACH;
   player.autonavmsg = strdup(p_("autonav_target", "position"));
   player.autonavcol = '0';
   vect_cset( &player.autonav_pos, x, y );
}


/**
 * @brief Starts autonav with a planet destination.
 */
void player_autonavPnt( char *name )
{
   Planet *p;

   p = planet_get( name );
   if (!player_autonavSetup())
      return;

   /* Break possible hyperspacing. */
   player_autonavHyperspaceAbort(1);

   /* Resting on the assumption that initialization of auto-landing
    * starts with an attempt to land normally (as it should), this
    * variable is here to ensure that double-messages don't happen,
    * which otherwise occurs with planets where landing clearance was
    * denied due to how it works. Essentially, if we're in range,
    * that means the previous player.land call already had a chance
    * to give the player the planet faction's explanation, and so we
    * make a note of this so that they don't immediately repeat
    * themselves as a part of the hailing step. */
   informed = pilot_inRangePlanet(player.p, player.p->nav_planet);

   player.autonav = AUTONAV_PNT_APPROACH;
   player.autonavmsg = strdup( _(p->name) );
   player.autonavcol = planet_getColourChar( p );
   vect_cset( &player.autonav_pos, p->pos.x, p->pos.y );
}


/**
 * @brief Starts autonav with a pilot to follow.
 */
void player_autonavPil(pilotId_t p)
{
   Pilot *pilot;
   int inrange;

   pilot = pilot_get(p);

   inrange = pilot_inRangePilot(player.p, pilot, NULL);
   if (!player_autonavSetup() || !inrange)
      return;

   /* Break possible hyperspacing. */
   player_autonavHyperspaceAbort(1);

   player.autonav = AUTONAV_PLT_FOLLOW;
   player.autonavmsg = strdup(pilot->name);
   player.autonavcol = '0';
   player_message(_("#oAutonav: following %s."),
         inrange ? pilot->name : _("Unknown"));
}


/**
 * @brief Starts autonav with a pilot to board.
 */
void player_autonavBoard(pilotId_t p)
{
   Pilot *pilot;
   int inrange;

   pilot = pilot_get(p);

   inrange = pilot_inRangePilot(player.p, pilot, NULL);
   if (!player_autonavSetup() || !inrange)
      return;

   /* Detected fuzzy, can't board. */
   if (!inrange) {
      player_autonavPil(p);
      return;
   }

   player_message(_("#oAutonav: boarding %s."), pilot->name);
   player.autonav = AUTONAV_PLT_BOARD_APPROACH;
   player.autonavmsg = strdup(pilot->name);
   player.autonavcol = '0';
}


/**
 * @brief Handles common time accel ramp-down for autonav to positions and planets.
 */
static void player_autonavRampdown( double d )
{
   double t, tint;
   double vel;
   double tc_base;

   tc_base = player_dt_default() * player.speed;
   vel = MIN(1.5 * player.p->speed, VMOD(player.p->solid->vel));
   t = d / vel * (1. - 0.075*tc_base);
   tint = 3. + 0.5*(3.*(tc_mod-tc_base));
   if (t < tint) {
      tc_rampdown = 1;
      tc_down = (tc_mod-tc_base) / 3.;
   }
}


/**
 * @brief Aborts regular interstellar autonav, but not in-system autonav.
 *
 *    @param reason Human-readable string describing abort condition.
 */
void player_autonavAbortJump( const char *reason )
{
   /* No point if player is beyond aborting. */
   if ((player.p==NULL) || pilot_isFlag(player.p, PILOT_HYPERSPACE))
      return;

   if (!player_isFlag(PLAYER_AUTONAV) || ((player.autonav != AUTONAV_JUMP_APPROACH) &&
         (player.autonav != AUTONAV_JUMP_BRAKE)))
      return;

   /* It's definitely not in-system autonav. */
   player_autonavAbort(reason, 0);
}


/**
 * @brief Aborts autonav.
 *
 *    @param reason Human-readable string describing abort condition.
 *    @param force Whether or not to force abortion even if pilot is
 *       under manual control.
 */
void player_autonavAbort(const char *reason, int force)
{
   /* No point if player is beyond aborting. */
   if ((player.p==NULL) || pilot_isFlag(player.p, PILOT_HYPERSPACE))
      return;

   /* Cooldown (handled later) may be script-initiated and we don't
    * want to make it player-abortable while under manual control. */
   if (!force && pilot_isFlag(player.p, PILOT_MANUAL_CONTROL))
      return;

   if (player_isFlag(PLAYER_AUTONAV)) {
      if (reason != NULL)
         player_message(_("#rAutonav aborted: %s"), reason);
      else
         player_message(_("#rAutonav aborted"));
      player_rmFlag(PLAYER_AUTONAV);

      /* Get rid of acceleration. */
      player_accelOver();

      /* Break possible hyperspacing. */
      player_autonavHyperspaceAbort(0);

      /* Reset time compression. */
      player_autonavEnd();
   }
}


/**
 * @brief Handles the autonavigation process for the player.
 */
static void player_autonav (void)
{
   StarSystem *sys;
   JumpPoint *jp;
   Planet *pnt;
   Pilot *p;
   int ret, map_npath;
   double d, t, tint;
   double vel;
   double a, diff;
   double error_margin;
   double tc_base;

   (void)map_getDestination(&map_npath);

   tc_base = player_dt_default() * player.speed;

   switch (player.autonav) {
      case AUTONAV_JUMP_APPROACH:
         /* Target jump. */
         jp = &cur_system->jumps[player.p->nav_hyperspace];
         ret = player_autonavApproach(&jp->pos, &d, 0);
         if (ret)
            player.autonav = AUTONAV_JUMP_BRAKE;
         else if (!tc_rampdown && (map_npath<=1)) {
            vel = MIN(1.5 * player.p->speed, VMOD(player.p->solid->vel));
            t = d/vel * (1.2 - 0.1*tc_base);
            /* tint is the integral of the time in per time units.
             *
             * tc_mod
             *    ^
             *    |
             *    |\
             *    | \
             *    |  \___
             *    |
             *    +------> time
             *    0   3
             *
             * We decompose integral in a rectangle (3*1) and a triangle (3*(tc_mod-1.))/2.
             *  This is the "elapsed time" when linearly decreasing the tc_mod. Which we can
             *  use to calculate the actual "game time" that'll pass when decreasing the
             *  tc_mod to 1 during 3 seconds. This can be used then to compare when we want to
             *  start decrementing.
             */
            tint = 3. + 0.5*(3.*(tc_mod-tc_base));
            if (t < tint) {
               tc_rampdown = 1;
               tc_down = (tc_mod-tc_base) / 3.;
            }
         }
         break;

      case AUTONAV_JUMP_BRAKE:
         /* Target jump. */
         jp = &cur_system->jumps[player.p->nav_hyperspace];
         if (player.p->stats.misc_instant_jump) {
            ret = 0;

            /* Check to see if headed toward the jump point. */
            a = atan2(jp->pos.y - player.p->solid->pos.y,
                  jp->pos.x - player.p->solid->pos.x);
            diff = angle_diff(VANGLE(player.p->solid->vel), a);

            /* The line representing the distance is at a right angle
             * with the line representing the radius. */
            error_margin = atan(jp->radius
                  / vect_dist(&player.p->solid->pos, &jp->pos));

            if (ABS(diff) < error_margin) {
               /* Face system headed to. */
               sys = cur_system->jumps[player.p->nav_hyperspace].target;
               a = ANGLE(sys->pos.x - cur_system->pos.x,
                     sys->pos.y - cur_system->pos.y);
               diff = pilot_face(player.p, a);
               if (ABS(diff) < MAX_DIR_ERR)
                  pilot_setTurn(player.p, 0.);

               if (space_canHyperspace(player.p))
                  /* Hyperspace time! */
                  ret = 1;
            }
            else {
               /* Trajectory is bad; fall back to the braking method,
                * which is more reliable. */
               ret = player_autonavBrake();
            }
         }
         else {
            ret = player_autonavBrake();
         }

         /* Try to jump or see if braked. */
         if (ret) {
            if (space_canHyperspace(player.p))
               player_jump(0);
            player.autonav = AUTONAV_JUMP_APPROACH;
         }

         /* See if should ramp down. */
         if (!tc_rampdown && (map_npath<=1)) {
            tc_rampdown = 1;
            tc_down = (tc_mod-tc_base) / 3.;
         }
         break;

      case AUTONAV_POS_APPROACH:
         ret = player_autonavApproach( &player.autonav_pos, &d, 1 );
         if (ret) {
            player_message( _("#oAutonav: arrived at position.") );
            player_autonavEnd();
         }
         else if (!tc_rampdown)
            player_autonavRampdown(d);
         break;

      case AUTONAV_PNT_APPROACH:
         if (!hailed && !player_isFlag(PLAYER_BASICAPPROACH)
               && !player_isFlag(PLAYER_LANDACK)
               && (player.p->nav_planet != -1)) {
            pnt = cur_system->planets[player.p->nav_planet];
            if (!pnt->can_land && !pnt->bribed && (pnt->land_override <= 0)) {
               ret = player_hailPlanet(0);
               if (ret) {
                  if (pnt->faction == 0) {
                     player_autonavAbort(NULL, 0);
                     break;
                  }
                  else {
                     if (!informed) {
                        /* Call player_land so the player knows what's up. */
                        player_land(0, 0);
                        informed = 1;
                     }

                     player_message(
                        _("#oAutonav: hailing planet; please negotiate land"
                           " clearance."));
                     hailed = 1;
                  }
               }
            }
            else {
               /* Call player_land to let player know of clearance. If
                * it is an approved land, we're done; happens when
                * autoland was started while taking off and can
                * theoretically happen by astounding coincidence in
                * other circumstances. Not returning here in that case
                * leads to an amusing, but harmless bug where the ship
                * moves while landing. */
               if (player_land(0, 0) == PLAYER_LAND_OK)
                  return;
            }
         }

         ret = player_autonavApproach( &player.autonav_pos, &d, 1 );
         if (ret) {
            if (player_isFlag(PLAYER_BASICAPPROACH)) {
               player_rmFlag(PLAYER_BASICAPPROACH);
               player_message( _("#oAutonav: arrived at #%c%s#0."),
                     player.autonavcol,
                     player.autonavmsg );
               player_autonavEnd();
            }
            else
               player.autonav = AUTONAV_PNT_BRAKE;
         }
         else if (!tc_rampdown)
            player_autonavRampdown(d);
         break;

      case AUTONAV_PNT_BRAKE:
         ret = player_autonavBrake();

         /* Try to land. */
         if (ret) {
            ret = player_land(0, 0);
            if (ret == PLAYER_LAND_OK)
               return;
            else if (ret == PLAYER_LAND_AGAIN)
               player.autonav = AUTONAV_PNT_APPROACH;
            else
               player_autonavAbort(NULL, 0);
         }

         /* See if should ramp down. */
         if (!tc_rampdown) {
            tc_rampdown = 1;
            tc_down     = (tc_mod-tc_base) / 3.;
         }
         break;

      case AUTONAV_PLT_FOLLOW:
         p = pilot_get( player.p->target );
         if (p == NULL)
            p = pilot_get( PLAYER_ID );
         if ((p->id == PLAYER_ID) || (!pilot_inRangePilot( player.p, p, NULL ))) {
            /* TODO : handle the different reasons: pilot is too far, jumped, landed or died. */
            player_message(_("#oAutonav: following target %s has been lost."),
                  player.autonavmsg);
            player_accel( 0. );
            player_autonavEnd();
         }
         else {
            ret = (pilot_isDisabled(p) || pilot_isFlag(p,PILOT_BOARDABLE));
            player_autonavFollow( &p->solid->pos, &p->solid->vel, !ret, &d );
            if (ret && (!tc_rampdown))
               player_autonavRampdown(d);
         }
         break;

      case AUTONAV_PLT_BOARD_APPROACH:
         p = pilot_get(player.p->target);
         if (p == NULL)
            p = pilot_get(PLAYER_ID);
         ret = player_autonavApproachBoard(&p->solid->pos, &p->solid->vel, &d,
               p->ship->gfx_space->sw);
         if (!tc_rampdown)
            player_autonavRampdown(d);

         /* Try to board. */
         if (ret) {
            ret = player_board();
            if (ret == PLAYER_BOARD_OK)
               player_autonavEnd();
            else if (ret != PLAYER_BOARD_RETRY)
               player_autonavAbort(NULL, 0);
         }
         break;
   }
}


/**
 * @brief Handles approaching a position with autonav.
 *
 *    @param[in] pos Position to go to.
 *    @param[out] dist2 Square distance left to target.
 *    @param count_target If 1 it subtracts the braking distance from dist2. Otherwise it returns the full distance.
 *    @return 1 on completion.
 */
static int player_autonavApproach( const Vector2d *pos, double *dist2, int count_target )
{
   double d, t, vel, dist;

   /* Only accelerate if facing move dir. */
   d = pilot_face( player.p, vect_angle( &player.p->solid->pos, pos ) );
   if (FABS(d) < MIN_DIR_ERR) {
      if (player_acc < 1.)
         player_accel( 1. );
   }
   else if (player_acc > 0.)
      player_accelOver();

   /* Get current time to reach target. */
   t  = MIN( 1.5*player.p->speed, VMOD(player.p->solid->vel) ) /
      (player.p->thrust / player.p->solid->mass);

   /* Get velocity. */
   vel   = MIN( player.p->speed, VMOD(player.p->solid->vel) );

   /* Get distance. */
   dist  = vel*(t+1.1*M_PI/player.p->turn) -
      0.5*(player.p->thrust/player.p->solid->mass)*t*t;

   /* Output distance^2 */
   d        = vect_dist( pos, &player.p->solid->pos );
   dist     = d - dist;
   if (count_target)
      *dist2   = dist;
   else
      *dist2   = d;

   /* See if should start braking. */
   if (dist < 0.) {
      player_accelOver();
      return 1;
   }
   return 0;
}


/**
 * @brief Handles following a moving point with autonav (PD controller).
 *
 *    @param[in] pos Position to go to.
 *    @param[in] vel Velocity of the target.
 *    @param[in] follow Whether to follow, or arrive at
 *    @param[out] dist2 Distance left to target.
 */
static void player_autonavFollow( const Vector2d *pos, const Vector2d *vel, const int follow, double *dist2 )
{
   double Kp, Kd, angle, radius, d, timeFactor;
   Vector2d dir, point;

   /* timeFactor is a time constant of the ship, used to heuristically
    * determine the ratio Kd/Kp. */
   timeFactor = M_PI/player.p->turn
         + player.p->speed/player.p->thrust*player.p->solid->mass;

   /* Define the control coefficients.
      Maybe radius could be adjustable by the player. */
   Kp = 10;
   Kd = MAX(5., 10.84*timeFactor-10.82);
   radius = 100;

   /* Find a point behind the target at a distance of radius unless stationary, or not following. */
   if ( !follow || ( vel->x == 0 && vel->y == 0 ) )
      radius = 0;
   angle = M_PI + vel->angle;
   vect_cset( &point, pos->x + radius * cos(angle),
              pos->y + radius * sin(angle) );

   vect_cset( &dir, (point.x - player.p->solid->pos.x) * Kp +
         (vel->x - player.p->solid->vel.x) *Kd,
         (point.y - player.p->solid->pos.y) * Kp +
         (vel->y - player.p->solid->vel.y) *Kd );

   d = pilot_face( player.p, VANGLE(dir) );

   if ((FABS(d) < MIN_DIR_ERR) && (VMOD(dir) > 300))
      player_accel( 1. );
   else
      player_accel( 0. );

   /* If aiming exactly at the point, should say when approaching. */
   if (!follow)
      *dist2 = vect_dist( pos, &player.p->solid->pos );
}


static int player_autonavApproachBoard( const Vector2d *pos, const Vector2d *vel, double *dist2, double sw )
{
   double d, timeFactor;
   Vector2d dir;

   /* timeFactor is a time constant of the ship, used to heuristically
    * determine the ratio Kd/Kp. */
   timeFactor = M_PI/player.p->turn
         + player.p->speed/player.p->thrust*player.p->solid->mass;

   /* Define the control coefficients. */
   const double Kp = 10.;
   const double Kd = MAX(5., 10.84*timeFactor-10.82);

   vect_cset( &dir, (pos->x - player.p->solid->pos.x) * Kp +
         (vel->x - player.p->solid->vel.x) *Kd,
         (pos->y - player.p->solid->pos.y) * Kp +
         (vel->y - player.p->solid->vel.y) *Kd );

   d = pilot_face( player.p, VANGLE(dir) );

   if ((FABS(d) < MIN_DIR_ERR) && (VMOD(dir) > 300.))
      player_accel( 1. );
   else
      player_accel( 0. );

   /* Distance for TC-rampdown. */
   *dist2 = vect_dist( pos, &player.p->solid->pos );

   /* Check if velocity and position allow to board. */
   if (*dist2 > sw * PILOT_SIZE_APPROX)
      return 0;
   if (vect_dist(&player.p->solid->vel, vel) > MAX_HYPERSPACE_VEL)
      return 0;
   return 1;
}


/**
 * @brief Handles the autonav braking.
 *
 *    @return 1 on completion.
 */
static int player_autonavBrake (void)
{
   int ret;
   JumpPoint *jp;
   Vector2d pos;

   if ((player.autonav == AUTONAV_JUMP_BRAKE) && (player.p->nav_hyperspace != -1)) {
      jp  = &cur_system->jumps[ player.p->nav_hyperspace ];

      pilot_brakeDist( player.p, &pos );
      if (vect_dist2( &pos, &jp->pos ) > pow2(jp->radius))
         ret = pilot_interceptPos( player.p, jp->pos.x, jp->pos.y );
      else
         ret = pilot_brake( player.p );
   }
   else
      ret = pilot_brake(player.p);

   player_acc = player.p->solid->thrust / player.p->thrust;

   return ret;
}

/**
 * @brief Checks whether the speed should be reset due to damage or missile locks.
 *
 *    @return 1 if the speed should be reset.
 */
int player_autonavShouldResetSpeed (void)
{
   double failpc, shield, armour;
   double dist;
   double careful_dist;
   double their_range, my_range;
   int i, j;
   Pilot * const *pstk;
   Pilot *p;
   int hostiles, will_reset;

   if (!player_isFlag(PLAYER_AUTONAV))
      return 0;

   /* Always reset speed during cinematics. */
   if (player_isFlag(PLAYER_CINEMATICS)) {
      player_autonavResetSpeed();
      return 1;
   }

   hostiles = 0;
   will_reset = 0;

   failpc = conf.autonav_reset_speed;
   shield = player.p->shield / player.p->shield_max;
   armour = player.p->armour / player.p->armour_max;

   pstk = pilot_getAll();
   for (i=0; i<array_size(pstk); i++) {
      p = pstk[i];

      /* Must not be the player. */
      if (p->id == PLAYER_ID)
         continue;

      /* If autonav_ignore_passive is true, must be actively hostile. */
      if (conf.autonav_ignore_passive && !pilot_isFlag(p, PILOT_HOSTILE))
         continue;

      /* Must be an enemy. */
      if (!pilot_isHostile(p))
         continue;

      /* Must not be disabled. */
      if (pilot_isDisabled(p))
         continue;

      /* Must be detected non-fuzzily by the player. */
      if (pilot_inRangePilot(player.p, p, NULL) != 1)
         continue;

      dist = vect_dist(&p->solid->pos, &player.p->solid->pos);

      /* If the pilot is hostile and can see the player, check
       * against their range as well as player's range. */
      if (pilot_inRangePilot(p, player.p, NULL)
            && pilot_isFlag(p, PILOT_HOSTILE))
         careful_dist = dist;
      else
         careful_dist = INFINITY;
      
      /* Check weapon set ranges of both the hostile pilot and the
       * player. Only count it as hostile presence if one of the two
       * is near their weapon range. Weapon sets with infinite range
       * (i.e. those with fighter bays) are not counted */
      for (j=0; j<PILOT_WEAPON_SETS; j++) {
         their_range = pilot_weapSetRange(p, j, -1);
         my_range = pilot_weapSetRange(player.p, j, -1);
         if ((isfinite(their_range) && (their_range >= careful_dist))
               || (isfinite(my_range) && (my_range >= dist))) {
            hostiles = 1;
            break;
         }
      }

      if (hostiles)
         break;
   }

   if (hostiles) {
      if (failpc > .995) {
         will_reset = 1;
         player.autonav_timer = MAX( player.autonav_timer, 0. );
      }
      else if ((shield < lasts && shield < failpc) || armour < lasta) {
         will_reset = 1;
         player.autonav_timer = MAX( player.autonav_timer, 2. );
      }
   }

   lasts = shield;
   lasta = armour;

   if (will_reset || (player.autonav_timer > 0)) {
      player_autonavResetSpeed();
      return 1;
   }
   return 0;
}


/**
 * @brief Handles autonav thinking.
 *
 *    @param pplayer Player doing the thinking.
 *    @param dt Current delta tick.
 */
void player_thinkAutonav( Pilot *pplayer, double dt )
{
   if (player.autonav_timer > 0.)
      player.autonav_timer -= dt;

   player_autonavShouldResetSpeed();
   if ((player.autonav == AUTONAV_JUMP_APPROACH) ||
         (player.autonav == AUTONAV_JUMP_BRAKE)) {
      /* If we're already at the target. */
      if (player.p->nav_hyperspace == -1)
         player_autonavAbort(
            _("Hyperspace target changed to current system"), 0);

      /* Need fuel. */
      else if (pplayer->fuel < pplayer->fuel_consumption)
         player_autonavAbort(_("Not enough fuel for autonav to continue"), 0);

      else
         player_autonav();
   }

   /* Keep on moving. */
   else
      player_autonav();
}


/**
 * @brief Updates the player's autonav.
 *
 *    @param dt Current delta tick (should be real delta tick, not game delta tick).
 */
void player_updateAutonav( double dt )
{
   const double dis_dead = 1.0;
   const double dis_mod = 5.0;
   const double dis_max = 10.0;
   const double dis_ramp = 2.0;
   double tc_base;

   if (paused || (player.p==NULL) || pilot_isFlag(player.p, PILOT_DEAD))
      return;

   tc_base = player_dt_default() * player.speed;

   /* We handle disabling here. */
   if (pilot_isFlag(player.p, PILOT_DISABLED)) {
      /* It is somewhat like:
       *        /------------\        4x
       *       /              \
       * -----/                \----- 1x
       *
       * <---><-><----------><-><--->
       *   5   6     X        6   5    Real time
       *   5   15    X        15  5    Game time
       *
       * For triangles we have to add the rectangle and triangle areas.
       */
      /* 5 second deadtime. */
      if (player.p->dtimer_accum < dis_dead)
         tc_mod = tc_base;
      else {
         /* Ramp down. */
         if (player.p->dtimer - player.p->dtimer_accum
               < dis_dead + (dis_max-tc_base)*dis_ramp/2 + tc_base*dis_ramp)
            tc_mod = MAX(tc_base, tc_mod - dis_mod*dt);
         /* Normal. */
         else
            tc_mod = MIN(dis_max, tc_mod + dis_mod*dt);
      }
      pause_setSpeed(tc_mod);
      sound_setSpeed(tc_mod);
      return;
   }

   /* Must be autonaving. */
   if (!player_isFlag(PLAYER_AUTONAV))
      return;

   /* Ramping down. */
   if (tc_rampdown) {
      if (tc_mod != tc_base) {
         tc_mod = MAX(tc_base, tc_mod - tc_down*dt);
         pause_setSpeed(tc_mod);
         sound_setSpeed(tc_mod);
      }
      return;
   }

   /* We'll update the time compression here. */
   if (tc_mod == player.tc_max)
      return;
   else
      tc_mod += 0.2 * dt * (player.tc_max-tc_base);
   /* Avoid going over. */
   if (tc_mod > player.tc_max)
      tc_mod = player.tc_max;
   pause_setSpeed(tc_mod);
   sound_setSpeed(tc_mod);
}


