/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file space.c
 *
 * @brief Handles all the space stuff, namely systems and planets.
 */

/** @cond */
#include <float.h>
#include <math.h>
#include <stdlib.h>
#include "physfs.h"

#include "naev.h"
/** @endcond */

#include "space.h"

#include "background.h"
#include "conf.h"
#include "credits.h"
#include "damagetype.h"
#include "dev_uniedit.h"
#include "economy.h"
#include "faction.h"
#include "gui.h"
#include "hook.h"
#include "land.h"
#include "log.h"
#include "map.h"
#include "map_overlay.h"
#include "menu.h"
#include "mission.h"
#include "music.h"
#include "ndata.h"
#include "nebula.h"
#include "nfile.h"
#include "nlua.h"
#include "nlua_pilot.h"
#include "nlua_planet.h"
#include "nluadef.h"
#include "nmath.h"
#include "nstring.h"
#include "ntime.h"
#include "nxml.h"
#include "opengl.h"
#include "pause.h"
#include "pilot.h"
#include "player.h"
#include "queue.h"
#include "rng.h"
#include "sound.h"
#include "spfx.h"
#include "toolkit.h"
#include "weapon.h"

#define XML_PLANET_TAG        "asset" /**< Individual planet xml tag. */
#define XML_SYSTEM_TAG        "ssys" /**< Individual systems xml tag. */

#define PLANET_GFX_EXTERIOR_PATH_W 400 /**< Planet exterior graphic width. */
#define PLANET_GFX_EXTERIOR_PATH_H 400 /**< Planet exterior graphic height. */

/* used to overcome warnings due to 0 values */
#define FLAG_XSET             (1<<0) /**< Set the X position value. */
#define FLAG_YSET             (1<<1) /**< Set the Y position value. */
#define FLAG_INTERFERENCESET  (1<<3) /**< Set the interference value. */
#define FLAG_SERVICESSET      (1<<4) /**< Set the service value. */
#define FLAG_FACTIONSET       (1<<5) /**< Set the faction value. */

#define DEBRIS_BUFFER         1000 /**< Buffer to smooth appearance of debris */

#define ASTEROID_EXPLODE_INTERVAL 5. /**< Interval of asteroids randomly exploding */
#define ASTEROID_EXPLODE_CHANCE   0.1 /**< Chance of asteroid exploding each interval */

/*
 * planet <-> system name stack
 */
static char** planetname_stack = NULL; /**< Planet name stack corresponding to system. */
static char** systemname_stack = NULL; /**< System name stack corresponding to planet. */


/*
 * Star system stack.
 */
StarSystem *systems_stack = NULL; /**< Star system stack. */

/*
 * Planet stack.
 */
static Planet *planet_stack = NULL; /**< Planet stack. */

/*
 * Asteroid types stack.
 */
static AsteroidType *asteroid_types = NULL; /**< Asteroid types stack. */

/*
 * Misc.
 */
static int systems_loading = 1; /**< Systems are loading. */
StarSystem *cur_system = NULL; /**< Current star system. */
glTexture *jumppoint_gfx = NULL; /**< Jump point graphics. */
static glTexture *jumpbuoy_gfx = NULL; /**< Jump buoy graphics. */
static nlua_env landing_env = LUA_NOREF; /**< Landing lua env. */
static int space_fchg = 0; /**< Faction change counter, to avoid unnecessary calls. */
static int space_simulating = 0; /**< Are we simulating space? */
glTexture **asteroid_debris_gfx = NULL;
static size_t nasterogfx = 0; /**< Nb of asteroid debris gfx. */
static Planet *space_landQueuePlanet = NULL;

/*
 * fleet spawn rate
 */
int space_spawn = 1; /**< Spawn enabled by default. */


/*
 * Internal Prototypes.
 */
/* space load */
static void space_clear(void);
/* planet load */
static int planet_parse( Planet *planet, const xmlNodePtr parent, Commodity **stdList );
static int space_parseAssets( xmlNodePtr parent, StarSystem* sys );
/* system load */
static void system_init( StarSystem *sys );
static void asteroid_init( Asteroid *ast, AsteroidAnchor *field );
static void debris_init( Debris *deb );
static int systems_load (void);
static int asteroidTypes_load (void);
static StarSystem* system_parse( StarSystem *system, const xmlNodePtr parent );
static int system_parseJumpPoint( const xmlNodePtr node, StarSystem *sys );
static int system_parseAsteroidField( const xmlNodePtr node, StarSystem *sys );
static int system_parseAsteroidExclusion( const xmlNodePtr node, StarSystem *sys );
static void system_parseJumps( const xmlNodePtr parent );
static void system_parseAsteroids( const xmlNodePtr parent, StarSystem *sys );
/* misc */
static int getPresenceIndex(StarSystem *sys, factionId_t faction);
static void system_scheduler( double dt, int init );
static void asteroid_explode ( Asteroid *a, AsteroidAnchor *field, int give_reward );
/* Render. */
static void space_renderJumpPoint( const JumpPoint *jp, int i );
static void space_renderPlanet( const Planet *p );
static void space_renderAsteroid( const Asteroid *a );
static void space_renderDebris( const Debris *d, double x, double y );
/*
 * Externed prototypes.
 */
int space_sysSave( xmlTextWriterPtr writer );
int space_sysLoad( xmlNodePtr parent );


/**
 * @brief Gets the (English) name for a service code.
 *
 * @param service One of the \p PLANET_SERVICE_* enum values.
 * @return English name, reversible via \p planet_getService()
 * and presentable via \p _().
 */
const char* planet_getServiceName( int service )
{
   switch (service) {
      case PLANET_SERVICE_LAND:        return N_("Land");
      case PLANET_SERVICE_INHABITED:   return N_("Inhabited");
      case PLANET_SERVICE_REFUEL:      return N_("Refuel");
      case PLANET_SERVICE_BAR:         return N_("Bar");
      case PLANET_SERVICE_MISSIONS:    return N_("Missions");
      case PLANET_SERVICE_COMMODITY:   return N_("Commodity");
      case PLANET_SERVICE_OUTFITS:     return N_("Outfits");
      case PLANET_SERVICE_SHIPYARD:    return N_("Shipyard");
      case PLANET_SERVICE_BLACKMARKET: return N_("Black Market");
   }
   return NULL;
}

int planet_getService( char *name )
{
   if (strcmp(name,"Land")==0)
      return PLANET_SERVICE_LAND;
   else if (strcmp(name,"Inhabited")==0)
      return PLANET_SERVICE_INHABITED;
   else if (strcmp(name,"Refuel")==0)
      return PLANET_SERVICE_REFUEL;
   else if (strcmp(name,"Bar")==0)
      return PLANET_SERVICE_BAR;
   else if (strcmp(name,"Missions")==0)
      return PLANET_SERVICE_MISSIONS;
   else if (strcmp(name,"Commodity")==0)
      return PLANET_SERVICE_COMMODITY;
   else if (strcmp(name,"Outfits")==0)
      return PLANET_SERVICE_OUTFITS;
   else if (strcmp(name,"Shipyard")==0)
      return PLANET_SERVICE_SHIPYARD;
   else if (strcmp(name,"Black Market")==0)
      return PLANET_SERVICE_BLACKMARKET;
   return -1;
}


/**
 * @brief Gets the price of a commodity at a planet.
 *
 *    @param p Planet to get price at.
 *    @param c Commodity to get price of.
 */
credits_t planet_commodityPrice( const Planet *p, const Commodity *c )
{
   char *sysname;
   StarSystem *sys;

   sysname = planet_getSystem( p->name );
   sys = system_get( sysname );

   return economy_getPrice( c, sys, p );
}

/**
 * @brief Gets the price of a commodity at a planet at given time.
 *
 *    @param p Planet to get price at.
 *    @param c Commodity to get price of.
 *    @param t Time to get price at.
 */
credits_t planet_commodityPriceAtTime( const Planet *p, const Commodity *c, ntime_t t )
{
   char *sysname;
   StarSystem *sys;

   sysname = planet_getSystem( p->name );
   sys = system_get( sysname );

   return economy_getPriceAtTime( c, sys, p, t );
}


/**
 * @brief Gets the average price of a commodity at a planet that has been seen so far.
 *
 * @param p Planet to get average price at.
 * @param c Commodity to get average price of.
 * @param[out] mean Sample mean, rounded to nearest credit.
 * @param[out] std Sample standard deviation (via uncorrected population formula).
 */
int planet_averagePlanetPrice( const Planet *p, const Commodity *c, credits_t *mean, double *std)
{
  return economy_getAveragePlanetPrice( c, p, mean, std );
}

/**
 * @brief Changes the planets faction.
 *
 *    @param p Planet to change faction of.
 *    @param faction Faction to change to.
 *    @return 0 on success.
 */
int planet_setFaction(Planet *p, factionId_t faction)
{
   p->faction = faction;
   return 0;
}


/**
 * @brief Checks to make sure if pilot is far enough away to hyperspace.
 *
 *    @param p Pilot to check if he can hyperspace.
 *    @return 1 if he can hyperspace, 0 else.
 */
int space_canHyperspace( Pilot* p )
{
   double d, r;
   JumpPoint *jp;

   /* Must not have the nojump flag. */
   if (pilot_isFlag(p, PILOT_NOJUMP))
      return 0;

   /* Must have fuel. */
   if (p->fuel < p->fuel_consumption)
      return 0;

   /* Must have hyperspace target. */
   if (p->nav_hyperspace < 0)
      return 0;

   /* Get the jump. */
   jp = &cur_system->jumps[ p->nav_hyperspace ];

   /* Check distance. */
   r = jp->radius * p->stats.jump_distance;
   d = vect_dist2( &p->solid->pos, &jp->pos );
   if (d > r*r)
      return 0;
   return 1;
}


/**
 * @brief Tries to get the pilot into hyperspace.
 *
 *    @param p Pilot to try to start hyperspacing.
 *    @return 0 on success.
 */
int space_hyperspace( Pilot* p )
{
   if (pilot_isFlag(p, PILOT_NOJUMP))
      return -2;
   if (p->fuel < p->fuel_consumption)
      return -3;
   if (!space_canHyperspace(p))
      return -1;

   /* pilot is now going to get automatically ready for hyperspace */
   pilot_setFlag(p, PILOT_HYP_PREP);
   pilot_rmFlag(p, PILOT_LOCALJUMP);

   return 0;
}


/**
 * @brief Calculates the jump in pos for a pilot.
 *
 *    @param in Star system entering.
 *    @param out Star system exiting.
 *    @param[out] pos Position calculated.
 *    @param[out] vel Velocity calculated.
 *    @param[out] dir Angle calculated.
 */
int space_calcJumpInPos( StarSystem *in, StarSystem *out, Vector2d *pos, Vector2d *vel, double *dir )
{
   int i;
   JumpPoint *jp;
   double a, d, x, y;
   double ea, ed;

   /* Find the entry system. */
   jp = NULL;
   for (i=0; i<array_size(in->jumps); i++)
      if (in->jumps[i].target == out)
         jp = &in->jumps[i];

   /* Must have found the jump. */
   if (jp == NULL) {
      WARN(_("Unable to find jump in point for '%s' in '%s': not connected"), out->name, in->name);
      return -1;
   }

   /* Base position target. */
   x = jp->pos.x;
   y = jp->pos.y;

   /* Calculate offset from target position. */
   a = 2*M_PI - jp->angle + RNGF()*HYPERSPACE_ENTER_ARC - HYPERSPACE_ENTER_ARC/2;
   d = RNGF()*(HYPERSPACE_ENTER_MAX-HYPERSPACE_ENTER_MIN) + HYPERSPACE_ENTER_MIN;

   /* Calculate new position. */
   x += d*cos(a);
   y += d*sin(a);

   /* Add some error. */
   ea = 2*M_PI*RNGF();
   ed = jp->radius/2.;
   x += ed*cos(ea);
   y += ed*sin(ea);

   /* Set new position. */
   vect_cset( pos, x, y );

   /* Set new velocity. */
   a += M_PI;
   vect_cset( vel, HYPERSPACE_VEL*cos(a), HYPERSPACE_VEL*sin(a) );

   /* Set direction. */
   *dir = a;

   return 0;
}

/**
 * @brief Gets the name of all the planets that belong to factions.
 *
 *    @param factions Array (array.h): Factions to check against.
 *    @param landable Whether the search is limited to landable planets.
 *    @return An array (array.h) of faction names.  Individual names are not allocated.
 */
char** space_getFactionPlanet(factionId_t *factions, int landable)
{
   int i,j,k, f;
   Planet* planet;
   char **tmp;

   tmp = array_create( char* );

   for (i=0; i<array_size(systems_stack); i++) {
      for (j=0; j<array_size(systems_stack[i].planets); j++) {
         planet = systems_stack[i].planets[j];

         /* Important to ignore virtual assets. */
         if (planet->real != ASSET_REAL)
            continue;

         /* Check if it's in factions. */
         f = 0;
         for (k=0; k<array_size(factions); k++) {
            if (planet->faction == factions[k]) {
               f = 1;
               break;
            }
         }
         if (!f)
            continue;

         /* Check landable. */
         if (landable) {
            planet_updateLand( planet );
            if (!planet->can_land)
               continue;
         }

         /* This is expensive so we probably want to do it last. */
         if (!space_sysReallyReachable( systems_stack[i].name ))
            continue;

         array_push_back( &tmp, planet->name );
         break; /* no need to check all factions */
      }
   }

   return tmp;
}


/**
 * @brief Gets the name of a random planet.
 *
 *    @param landable Whether the planet must let the player land normally.
 *    @param services Services the planet must have.
 *    @param filter Filter function for including planets.
 *    @return The name (internal/English) of a random planet.
 */
char* space_getRndPlanet( int landable, unsigned int services,
      int (*filter)(Planet *p))
{
   int i,j;
   Planet **tmp;
   char *res;
   Planet *pnt;
   char *sysname;

   res   = NULL;
   tmp   = array_create( Planet* );

   for (i=0; i<array_size(systems_stack); i++) {
      for (j=0; j<array_size(systems_stack[i].planets); j++) {
         pnt = systems_stack[i].planets[j];

         if (pnt->real != ASSET_REAL)
            continue;

         if (services && planet_hasService(pnt, services) != services)
            continue;

         if (filter != NULL && !filter(pnt))
            continue;

         array_push_back( &tmp, pnt );
      }
   }

   /* Second filter. */
   arrayShuffle( (void**)tmp );
   for (i=0; i < array_size(tmp); i++) {
      pnt = tmp[i];

      /* We put expensive calculations here to minimize executions. */
      if (landable) {
         planet_updateLand( pnt );
         if (!pnt->can_land)
            continue;
      }
      sysname = planet_getSystem(pnt->name);
      if (sysname == NULL)
         continue;
      if (!space_sysReallyReachable(sysname))
         continue;

      /* We want the name, not the actual planet. */
      res = tmp[i]->name;
      break;
   }
   array_free(tmp);

   return res;
}


/**
 * @brief Gets the closest feature to a position in the system.
 *
 *    @param sys System to get closest feature from a position.
 *    @param[out] pnt ID of closest planet or -1 if a jump point is closer (or none is close).
 *    @param[out] jp ID of closest jump point or -1 if a planet is closer (or none is close).
 *    @param[out] ast ID of closest asteroid or -1 if something else is closer (or none is close).
 *    @param[out] fie ID of the asteroid anchor the asteroid belongs to.
 *    @param x X position to get closest from.
 *    @param y Y position to get closest from.
 */
double system_getClosest( const StarSystem *sys, int *pnt, int *jp, int *ast, int *fie, double x, double y )
{
   int i, k;
   double d, td;
   Planet *p;
   JumpPoint *j;
   Asteroid *as;
   AsteroidAnchor *f;

   /* Default output. */
   *pnt = -1;
   *jp  = -1;
   *ast = -1;
   *fie = -1;
   d    = INFINITY;

   /* Planets. */
   for (i=0; i<array_size(sys->planets); i++) {
      p  = sys->planets[i];
      if (p->real != ASSET_REAL)
         continue;
      if (!planet_isKnown(p))
         continue;
      td = pow2(x-p->pos.x) + pow2(y-p->pos.y);
      if (td < d) {
         *pnt  = i;
         d     = td;
      }
   }

   /* Asteroids. */
   for (i=0; i<array_size(sys->asteroids); i++) {
      f = &sys->asteroids[i];
      for (k=0; k<f->nb; k++) {
         as = &f->asteroids[k];

         /* Skip invisible asteroids */
         if (as->appearing == ASTEROID_INVISIBLE)
            continue;

         /* Skip out of range asteroids */
         if (!pilot_inRangeAsteroid( player.p, k, i ))
            continue;

         td = pow2(x-as->pos.x) + pow2(y-as->pos.y);
         if (td < d) {
            *pnt  = -1; /* We must clear planet target as asteroid is closer. */
            *ast  = k;
            *fie  = i;
            d     = td;
         }
      }
   }

   /* Jump points. */
   for (i=0; i<array_size(sys->jumps); i++) {
      j  = &sys->jumps[i];
      if (!jp_isKnown(j))
         continue;
      td = pow2(x-j->pos.x) + pow2(y-j->pos.y);
      if (td < d) {
         *pnt  = -1; /* We must clear planet target as jump point is closer. */
         *ast  = -1;
         *fie  = -1;
         *jp   = i;
         d     = td;
      }
   }
   return d;
}


/**
 * @brief Gets the feature nearest to directly ahead of a position in the system.
 *
 *    @param sys System to get closest feature from a position.
 *    @param[out] pnt ID of closest planet or -1 if something else is closer (or none is close).
 *    @param[out] jp ID of closest jump point or -1 if something else is closer (or none is close).
 *    @param[out] ast ID of closest asteroid or -1 if something else is closer (or none is close).
 *    @param[out] fie ID of the asteroid anchor the asteroid belongs to.
 *    @param x X position to get closest from.
 *    @param y Y position to get closest from.
 *    @param ang Reference angle.
 *    @return The nearest angle to \p ang which is the direction from (\p x, \p y) to a feature.
 */
double system_getClosestAng( const StarSystem *sys, int *pnt, int *jp, int *ast, int *fie, double x, double y, double ang )
{
   int i, k;
   double a, ta;
   Planet *p;
   JumpPoint *j;
   AsteroidAnchor *f;
   Asteroid *as;

   /* Default output. */
   *pnt = -1;
   *jp  = -1;
   a    = ang + M_PI;

   /* Planets. */
   for (i=0; i<array_size(sys->planets); i++) {
      p  = sys->planets[i];
      if (p->real != ASSET_REAL)
         continue;
      ta = atan2( y - p->pos.y, x - p->pos.x);
      if ( ABS(angle_diff(ang, ta)) < ABS(angle_diff(ang, a))) {
         *pnt  = i;
         a     = ta;
      }
   }

   /* Asteroids. */
   for (i=0; i<array_size(sys->asteroids); i++) {
      f  = &sys->asteroids[i];
      for (k=0; k<f->nb; k++) {
         as = &f->asteroids[k];

         /* Skip invisible asteroids */
         if (as->appearing == ASTEROID_INVISIBLE)
            continue;

         ta = atan2( y - as->pos.y, x - as->pos.x);
         if ( ABS(angle_diff(ang, ta)) < ABS(angle_diff(ang, a))) {
            *pnt  = -1; /* We must clear planet target as asteroid is closer. */
            *ast  = k;
            *fie  = i;
            a     = ta;
         }
      }
   }

   /* Jump points. */
   for (i=0; i<array_size(sys->jumps); i++) {
      j  = &sys->jumps[i];
      ta = atan2( y - j->pos.y, x - j->pos.x);
      if ( ABS(angle_diff(ang, ta)) < ABS(angle_diff(ang, a))) {
         *ast  = -1;
         *fie  = -1;
         *pnt  = -1; /* We must clear the rest as jump point is closer. */
         *jp   = i;
         a     = ta;
      }
   }
   return a;
}


/**
 * @brief Sees if a system is reachable.
 *
 *    @return 1 if target system is reachable, 0 if it isn't.
 */
int space_sysReachable( StarSystem *sys )
{
   int i;
   JumpPoint *jp;

   if (sys_isKnown(sys))
      return 1; /* it is known */

   /* check to see if it is adjacent to known */
   for (i=0; i<array_size(sys->jumps); i++) {
      jp = sys->jumps[i].returnJump;
      if (jp && jp_isKnown( jp ))
         return 1;
   }

   return 0;
}


/**
 * @brief Sees if a system can be reached via jumping.
 *
 *    @return 1 if target system is reachable, 0 if it isn't.
 */
int space_sysReallyReachable( char* sysname )
{
   StarSystem** path;

   if (strcmp(sysname,cur_system->name)==0)
      return 1;
   path = map_getJumpPath( cur_system->name, sysname, 1, 1, NULL );
   if (path != NULL) {
      array_free(path);
      return 1;
   }
   return 0;
}

/**
 * @brief Sees if a system is reachable from another system.
 *
 *    @return 1 if target system is reachable, 0 if it isn't.
 */
int space_sysReachableFromSys( StarSystem *target, StarSystem *sys )
{
   JumpPoint *jp;

   /* check to see if sys contains a known jump point to target */
   jp = jump_getTarget( target, sys );
   if ( jp == NULL )
      return 0;
   else if ( jp_isKnown( jp ))
      return 1;
   return 0;
}

/**
 * @brief Gets an array (array.h) of all star systems.
 */
StarSystem* system_getAll (void)
{
   return systems_stack;
}


/**
 * @brief Checks to see if a system exists case insensitively.
 *
 *    @param sysname Name of the system to match (case insensitive).
 *    @return The actual name of the system of NULL if not found.
 */
const char *system_existsCase( const char* sysname )
{
   int i;
   for (i=0; i<array_size(systems_stack); i++)
      if (strcasecmp(sysname, systems_stack[i].name)==0)
         return systems_stack[i].name;
   return NULL;
}


/**
 * @brief Does a fuzzy case matching. Searches translated names but returns internal names.
 */
char **system_searchFuzzyCase( const char* sysname, int *n )
{
   int i, len;
   char **names;

   /* Overallocate to maximum. */
   names = malloc( sizeof(char*) * array_size(systems_stack) );

   /* Do fuzzy search. */
   len = 0;
   for (i=0; i<array_size(systems_stack); i++) {
      if (strcasestr( _(systems_stack[i].name), sysname ) != NULL) {
         names[len] = systems_stack[i].name;
         len++;
      }
   }

   /* Free if empty. */
   if (len == 0) {
      free(names);
      names = NULL;
   }

   *n = len;
   return names;
}




/**
 * @brief Get the system from its name.
 *
 *    @param sysname Name to match.
 *    @return System matching sysname.
 */
StarSystem* system_get( const char* sysname )
{
   int i;

   if ( sysname == NULL )
      return NULL;

   for (i=0; i<array_size(systems_stack); i++)
      if (strcmp(sysname, systems_stack[i].name)==0)
         return &systems_stack[i];

   WARN(_("System '%s' not found in stack"), sysname);
   return NULL;
}


/**
 * @brief Get the system by its index.
 *
 *    @param id Index to match.
 *    @return System matching index.
 */
StarSystem* system_getIndex( int id )
{
   return &systems_stack[ id ];
}


/**
 * @brief Gets the index of a star system.
 *
 *    @param sys System to get index of.
 *    @return The index of the system.
 */
int system_index( StarSystem *sys )
{
   return sys->id;
}


/**
 * @brief Get whether or not a planet has a system (i.e. is on the map).
 *
 *    @param planetname Planet name to match.
 *    @return 1 if the planet has a system, 0 otherwise.
 */
int planet_hasSystem( const char* planetname )
{
   int i;

   for (i=0; i<array_size(planetname_stack); i++)
      if (strcmp(planetname_stack[i],planetname)==0)
         return 1;

   return 0;
}


/**
 * @brief Get the name of a system from a planetname.
 *
 *    @param planetname Planet name to match.
 *    @return Name of the system planet belongs to, or NULL if it doesn't belong to any.
 */
char* planet_getSystem( const char* planetname )
{
   int i;

   for (i=0; i<array_size(planetname_stack); i++)
      if (strcmp(planetname_stack[i],planetname)==0)
         return systemname_stack[i];

   return NULL;
}


/**
 * @brief Gets a planet based on its name.
 *
 *    @param planetname Name to match.
 *    @return Planet matching planetname.
 */
Planet* planet_get( const char* planetname )
{
   int i;

   if (planetname==NULL) {
      WARN(_("Trying to find NULL planet..."));
      return NULL;
   }

   for (i=0; i<array_size(planet_stack); i++)
      if (strcmp(planet_stack[i].name,planetname)==0)
         return &planet_stack[i];

   WARN(_("Planet '%s' not found in the universe"), planetname);
   return NULL;
}


/**
 * @brief Gets planet by index.
 *
 *    @param ind Index of the planet to get.
 *    @return The planet gotten.
 */
Planet* planet_getIndex( int ind )
{
   /* Validity check. */
   if ((ind < 0) || (ind >= array_size(planet_stack))) {
      WARN(_("Planet index '%d' out of range (max %d)"), ind, array_size(planet_stack));
      return NULL;
   }

   return &planet_stack[ ind ];
}


/**
 * @brief Gets the ID of a planet.
 *
 *    @param p Planet to get ID of.
 *    @return The ID of the planet.
 */
int planet_index( const Planet *p )
{
   return p->id;
}


/**
 * @brief Gets an array (array.h) of all planets.
 */
Planet* planet_getAll (void)
{
   return planet_stack;
}


/**
 * @brief Sets a planet's known status, if it's real.
 */
void planet_setKnown( Planet *p )
{
   if (p->real == ASSET_REAL)
      planet_setFlag(p, PLANET_KNOWN);
}


/**
 * @brief Check to see if a planet exists.
 *
 *    @param planetname Name of the planet to see if it exists.
 *    @return 1 if planet exists.
 */
int planet_exists( const char* planetname )
{
   int i;
   for (i=0; i<array_size(planet_stack); i++)
      if (strcmp(planet_stack[i].name,planetname)==0)
         return 1;
   return 0;
}


/**
 * @brief Check to see if a planet exists (case insensitive).
 *
 *    @param planetname Name of the planet to see if it exists.
 *    @return The actual name of the planet or NULL if not found.
 */
const char* planet_existsCase( const char* planetname )
{
   int i;
   for (i=0; i<array_size(planet_stack); i++)
      if (strcasecmp(planet_stack[i].name,planetname)==0)
         return planet_stack[i].name;
   return NULL;
}


/**
 * @brief Does a fuzzy case matching. Searches translated names but returns internal names.
 */
char **planet_searchFuzzyCase( const char* planetname, int *n )
{
   int i, len;
   char **names;

   /* Overallocate to maximum. */
   names = malloc( sizeof(char*) * array_size(planet_stack) );

   /* Do fuzzy search. */
   len = 0;
   for (i=0; i<array_size(planet_stack); i++) {
      if (strcasestr( _(planet_stack[i].name), planetname ) != NULL) {
         names[len] = planet_stack[i].name;
         len++;
      }
   }

   /* Free if empty. */
   if (len == 0) {
      free(names);
      names = NULL;
   }

   *n = len;
   return names;
}

/**
 * @brief Gets a jump point based on its target and system.
 *
 *    @param jumpname Name to match.
 *    @param sys System jump is in.
 *    @return Jump point matich jumpname in sys or NULL if not found.
 */
JumpPoint* jump_get( const char* jumpname, const StarSystem* sys )
{
   int i;
   JumpPoint *jp;

   if (jumpname==NULL) {
      WARN(_("Trying to find NULL jump point..."));
      return NULL;
   }

   for (i=0; i<array_size(sys->jumps); i++) {
      jp = &sys->jumps[i];
      if (strcmp(jp->target->name,jumpname)==0)
         return jp;
   }

   WARN(_("Jump point '%s' not found in %s"), jumpname, sys->name);
   return NULL;
}


/**
 * @brief Less safe version of jump_get that works with pointers.
 *
 *    @param target Target system jump leads to.
 *    @param sys System to look in.
 *    @return Jump point in sys to target or NULL if not found.
 */
JumpPoint* jump_getTarget( StarSystem* target, const StarSystem* sys )
{
   int i;
   JumpPoint *jp;
   for (i=0; i<array_size(sys->jumps); i++) {
      jp = &sys->jumps[i];
      if (jp->target == target)
         return jp;
   }
   WARN(_("Jump point to '%s' not found in %s"), target->name, sys->name);
   return NULL;
}


/**
 * @brief Gets the jump point symbol.
 */
const char *jump_getSymbol( JumpPoint *jp )
{
   if (jp_isFlag(jp, JP_HIDDEN))
      return "* ";

   return "";
}


/**
 * @brief Controls fleet spawning.
 *
 *    @param dt Current delta tick.
 *    @param init Should be 1 to initialize the scheduler.
 */
static void system_scheduler( double dt, int init )
{
   int i, n;
   nlua_env env;
   SystemPresence *p;
   Pilot *pilot;

   /* Go through all the factions and reduce the timer. */
   for (i=0; i < array_size(cur_system->presence); i++) {
      p = &cur_system->presence[i];
      env = faction_getScheduler( p->faction );

      /* Must have a valid scheduler. */
      if (env==LUA_NOREF)
         continue;

      /* Spawning is disabled for this faction. */
      if (p->disabled)
         continue;

      /* Don't spawn if presence is 0 (can happen with unidiffs). */
      if (p->value <= 0)
         continue;

      /* Run the appropriate function. */
      if (init) {
         nlua_getenv( env, "create" ); /* f */
         if (lua_isnil(naevL,-1)) {
            WARN(_("Lua Spawn script for faction '%s' missing obligatory entry point 'create'."),
                  faction_name( p->faction ) );
            lua_pop(naevL,1);
            continue;
         }
         n = 0;
      }
      else {
         /* Decrement dt, only continue  */
         p->timer -= dt;
         if (p->timer >= 0.)
            continue;

         nlua_getenv( env, "spawn" ); /* f */
         if (lua_isnil(naevL,-1)) {
            WARN(_("Lua Spawn script for faction '%s' missing obligatory entry point 'spawn'."),
                  faction_name( p->faction ) );
            lua_pop(naevL,1);
            continue;
         }
         lua_pushnumber( naevL, p->curUsed ); /* f, presence */
         n = 1;
      }
      lua_pushnumber( naevL, p->value ); /* f, [arg,], max */

      /* Actually run the function. */
      if (nlua_pcall(env, n+1, 2)) { /* error has occurred */
         WARN(_("Lua Spawn script for faction '%s' : %s"),
               faction_name( p->faction ), lua_tostring(naevL,-1));
         lua_pop(naevL,1);
         continue;
      }

      /* Output is handled the same way. */
      if (!lua_isnumber(naevL,-2)) {
         WARN(_("Lua spawn script for faction '%s' failed to return timer value."),
               faction_name( p->faction ) );
         lua_pop(naevL,2);
         continue;
      }
      p->timer    += lua_tonumber(naevL,-2);
      /* Handle table if it exists. */
      if (lua_istable(naevL,-1)) {
         lua_pushnil(naevL); /* tk, k */
         while (lua_next(naevL,-2) != 0) { /* tk, k, v */
            /* Must be table. */
            if (!lua_istable(naevL,-1)) {
               WARN(_("Lua spawn script for faction '%s' returns invalid data (not a table)."),
                     faction_name( p->faction ) );
               lua_pop(naevL,2); /* tk, k */
               continue;
            }

            lua_getfield( naevL, -1, "pilot" ); /* tk, k, v, p */
            if (!lua_ispilot(naevL,-1)) {
               WARN(_("Lua spawn script for faction '%s' returns invalid data (not a pilot)."),
                     faction_name( p->faction ) );
               lua_pop(naevL,2); /* tk, k */
               continue;
            }
            pilot = pilot_get( lua_topilot(naevL,-1) );
            if (pilot == NULL) {
               lua_pop(naevL,2); /* tk, k */
               continue;
            }
            lua_pop(naevL,1); /* tk, k, v */
            lua_getfield( naevL, -1, "presence" ); /* tk, k, v, p */
            if (!lua_isnumber(naevL,-1)) {
               WARN(_("Lua spawn script for faction '%s' returns invalid data (not a number)."),
                     faction_name( p->faction ) );
               lua_pop(naevL,2); /* tk, k */
               continue;
            }
            pilot->presence = lua_tonumber(naevL,-1);
            if (pilot->faction != p->faction) {
               WARN( _("Lua spawn script for faction '%s' actually spawned a '%s' pilot."),
                     faction_name( p->faction ),
                     faction_name( pilot->faction ) );
               n = getPresenceIndex( cur_system, pilot->faction );
               p = &cur_system->presence[n];
            }
            p->curUsed     += pilot->presence;
            lua_pop(naevL,2); /* tk, k */
         }
      }
      lua_pop(naevL,2);
   }
}


/**
 * @brief Mark when a faction changes.
 */
void space_factionChange (void)
{
   space_fchg = 1;
}


/**
 * @brief Handles landing if necessary.
 */
void space_checkLand (void)
{
   if (space_landQueuePlanet != NULL) {
      land( space_landQueuePlanet, 0 );
      space_landQueuePlanet = NULL;
   }
}


/**
 * @brief Controls fleet spawning.
 *
 *    @param dt Current delta tick.
 */
void space_update( const double dt )
{
   int i, j;
   double x, y;
   Damage dmg;
   HookParam hparam[3];
   AsteroidAnchor *ast;
   Asteroid *a;
   Debris *d;
   Pilot *pplayer;
   Solid *psolid;
   int found_something;
   Pilot * const *pilot_stack;

   /* Needs a current system. */
   if (cur_system == NULL)
      return;

   /* If spawning is enabled, call the scheduler. */
   if (space_spawn)
      system_scheduler( dt, 0 );

   /*
    * Nebula.
    */
   nebu_update( dt );
   if (cur_system->nebu_volatility > 0.) {
      dmg.type = dtype_get("nebula");
      dmg.damage = cur_system->nebu_volatility * dt;
      dmg.penetration = 1.; /* Full penetration. */
      dmg.disable = 0.;

      /* Damage pilots in volatile systems. */
      pilot_stack = pilot_getAll();
      for (i=0; i<array_size(pilot_stack); i++) {
         if (!pilot_isFlag(pilot_stack[i], PILOT_LANDING))
            pilot_hit(pilot_stack[i], NULL, 0, &dmg, 0);
      }
   }

   /* Faction updates. */
   if (space_fchg) {
      for (i=0; i<array_size(cur_system->planets); i++)
         planet_updateLand( cur_system->planets[i] );

      /* Verify land authorization is still valid. */
      if (player_isFlag(PLAYER_LANDACK))
         player_checkLandAck();

      gui_updateFaction();
      space_fchg = 0;
   }

   if (!space_simulating) {
      found_something = 0;
      /* Planet updates */
      for (i=0; i<array_size(cur_system->planets); i++) {
         if (( !planet_isKnown( cur_system->planets[i] )) && ( pilot_inRangePlanet( player.p, i ))) {
            planet_setKnown( cur_system->planets[i] );
            player_message( _("You discovered #%c%s#0."),
                  planet_getColourChar( cur_system->planets[i] ),
                  _(cur_system->planets[i]->name) );
            hparam[0].type  = HOOK_PARAM_STRING;
            hparam[0].u.str = "asset";
            hparam[1].type  = HOOK_PARAM_ASSET;
            hparam[1].u.la  = cur_system->planets[i]->id;
            hparam[2].type  = HOOK_PARAM_SENTINEL;
            hooks_runParam( "discover", hparam );
            found_something = 1;
         }
      }

      /* Jump point updates */
      for (i=0; i<array_size(cur_system->jumps); i++) {
         if (( !jp_isKnown( &cur_system->jumps[i] )) && ( pilot_inRangeJump( player.p, i ))) {
            jp_setFlag( &cur_system->jumps[i], JP_KNOWN );
            player_message( _("You discovered a Jump Point.") );
            hparam[0].type  = HOOK_PARAM_STRING;
            hparam[0].u.str = "jump";
            hparam[1].type  = HOOK_PARAM_JUMP;
            hparam[1].u.lj.srcid = cur_system->id;
            hparam[1].u.lj.destid = cur_system->jumps[i].target->id;
            hparam[2].type  = HOOK_PARAM_SENTINEL;
            hooks_runParam( "discover", hparam );
            found_something = 1;
         }
      }

      if (found_something) {
         mission_destHilight();
         ovr_refresh();
      }
   }

   /* Update the gatherable objects. */
   gatherable_update(dt);

   /* Asteroids/Debris update */
   for (i=0; i<array_size(cur_system->asteroids); i++) {
      ast = &cur_system->asteroids[i];

      for (j=0; j<ast->nb; j++) {
         a = &ast->asteroids[j];

         /* Skip invisible asteroids */
         if (a->appearing == ASTEROID_INVISIBLE)
            continue;

         a->pos.x += a->vel.x * dt;
         a->pos.y += a->vel.y * dt;

         if (a->appearing == ASTEROID_VISIBLE) {
            /* Random explosions */
            a->timer += dt;
            if (a->timer >= ASTEROID_EXPLODE_INTERVAL) {
               a->timer = 0.;
               if ( (RNGF() < ASTEROID_EXPLODE_CHANCE)
                     || (space_isInField(&a->pos) < 0) ) {
                  asteroid_explode( a, ast,
                        (a->armour < asteroid_types[a->type].armour) );
               }
            }
         }
         else if (a->appearing == ASTEROID_GROWING) {
            /* Grow */
            a->timer += dt;
            if (a->timer >= 2.) {
               a->timer = 0.;
               a->appearing = ASTEROID_VISIBLE;
            }
         }
         else if (a->appearing == ASTEROID_SHRINKING) {
            /* Shrink */
            a->timer += dt;
            if (a->timer >= 2.) {
               /* Remove the asteroid target to any pilot. */
               pilot_untargetAsteroid( a->parent, a->id );
               /* reinit any disappeared asteroid */
               asteroid_init( a, ast );
            }
         }
         else if (a->appearing == ASTEROID_EXPLODING) {
            /* Exploding asteroid */
            a->timer += dt;
            if (a->timer >= .5) {
               /* Make it explode */
               asteroid_explode( a, ast, 1 );
            }
         }
      }

      x = 0;
      y = 0;
      pplayer = pilot_get( PLAYER_ID );
      if (pplayer != NULL) {
         psolid  = pplayer->solid;
         x = psolid->vel.x;
         y = psolid->vel.y;
      }

      for (j=0; j<ast->ndebris; j++) {
         d = &ast->debris[j];

         d->pos.x += (d->vel.x-x) * dt;
         d->pos.y += (d->vel.y-y) * dt;

         /* Check boundaries */
         if (d->pos.x > SCREEN_W + DEBRIS_BUFFER)
            d->pos.x -= SCREEN_W + 2*DEBRIS_BUFFER;
         else if (d->pos.y > SCREEN_H + DEBRIS_BUFFER)
            d->pos.y -= SCREEN_H + 2*DEBRIS_BUFFER;
         else if (d->pos.x < -DEBRIS_BUFFER)
            d->pos.x += SCREEN_W + 2*DEBRIS_BUFFER;
         else if (d->pos.y < -DEBRIS_BUFFER)
            d->pos.y += SCREEN_H + 2*DEBRIS_BUFFER;
      }

   }
}


/**
 * @brief returns wether we're just simulating.
 */
unsigned int space_isSimulation( void )
{
   return space_simulating;
}


/**
 * @brief Initializes the system.
 *
 *    @param sysname Name of the system to initialize.
 */
void space_init( const char* sysname )
{
   char* nt;
   int i, j, n, s;
   Planet *pnt;
   AsteroidAnchor *ast;
   Asteroid *a;
   Debris *d;
   Damage dmg;
   double dshield, darmor;

   /* Cleanup previous system. */
   space_clear();

   if ((sysname==NULL) && (cur_system==NULL))
      ERR(_("Cannot reinit system if there is no system previously loaded"));
   else if (sysname!=NULL) {
      for (i=0; i < array_size(systems_stack); i++)
         if (strcmp(sysname, systems_stack[i].name)==0)
            break;

      if (i>=array_size(systems_stack))
         ERR(_("System %s not found in stack"), sysname);
      cur_system = &systems_stack[i];

      nt = ntime_pretty(0, 2);
      player_message(_("#oEntering System %s on %s."), _(sysname), nt);
      if ((player.p != NULL) && (cur_system->nebu_volatility > 0.)) {
         dmg.type = dtype_get("nebula");
         dmg.damage = cur_system->nebu_volatility;
         dmg.penetration = 1.; /* Full penetration. */
         dmg.disable = 0.;

         dtype_calcDamage(&dshield, &darmor, NULL, NULL, 1., &dmg,
               &player.p->stats);
         player_message(
               _("#rWARNING: Volatile nebula (%G GW) detected in %s! Taking"
                  " damage:\n"
                  "%.1f GW of damage to shield\n"
                  "%.1f GW of damage to armor"),
               cur_system->nebu_volatility, _(sysname), dshield, darmor);
      }
      free(nt);

      /* Handle background */
      if (cur_system->nebu_density > 0.) {
         /* Background is Nebula */
         nebu_prep( cur_system->nebu_density, cur_system->nebu_volatility, cur_system->nebu_hue );

         /* Set up sound. */
         sound_env( SOUND_ENV_NEBULA, cur_system->nebu_density );
      }
      else {
         /* Background is starry */
         background_initStars( cur_system->stars );

         /* Set up sound. */
         sound_env( SOUND_ENV_NORMAL, 0. );
      }
   }

   /* Sort factions. */
   factions_sort();

   /* Clear hilights of the new system's jump points. */
   for (j=0; j<array_size(cur_system->jumps); j++) {
      cur_system->jumps[j].hilights = 0;
   }

   /* Set up planets. */
   for (i=0; i<array_size(cur_system->planets); i++) {
      pnt = cur_system->planets[i];
      pnt->bribed = 0;
      pnt->land_override = 0;
      planet_updateLand( pnt );
   }

   /* Set up asteroids. */
   for (i=0; i<array_size(cur_system->asteroids); i++) {
      ast = &cur_system->asteroids[i];
      ast->id = i;

      /* Add the asteroids to the anchor */
      ast->asteroids = realloc( ast->asteroids, (ast->nb) * sizeof(Asteroid) );
      for (j=0; j<ast->nb; j++) {
         a = &ast->asteroids[j];
         a->id = j;
         a->appearing = ASTEROID_INIT;
         asteroid_init(a, ast);
      }
      /* Add the debris to the anchor */
      ast->debris = realloc( ast->debris, (ast->ndebris) * sizeof(Debris) );
      for (j=0; j<ast->ndebris; j++) {
         d = &ast->debris[j];
         debris_init(d);
      }
   }

   /* Reset music to ambient. */
   if (player.p != NULL)
      music_choose("ambient");

   /* Reset player enemies. */
   player.enemies = 0;
   player.disabled_enemies = 0;

   pilots_newSystem();

   /* Reset any schedules and used presence. */
   for (i=0; i<array_size(cur_system->presence); i++) {
      cur_system->presence[i].curUsed  = 0;
      cur_system->presence[i].timer    = 0.;
      cur_system->presence[i].disabled = 0;
   }

   /* Load graphics. */
   space_gfxLoad( cur_system );

   /* Call the scheduler. */
   system_scheduler( 0., 1 );

   /* we now know this system */
   sys_setFlag(cur_system,SYSTEM_KNOWN);

   /* Simulate system. */
   space_simulating = 1;
   if (player.p != NULL)
      pilot_setFlag( player.p, PILOT_HIDE );
   player_messageToggle( 0 );
   s = sound_disabled;
   sound_disabled = 1;
   ntime_allowUpdate( 0 );
   n = SYSTEM_SIMULATE_TIME / dt_max;
   for (i=0; i<n; i++)
      update_routine(dt_max, 1);
   ntime_allowUpdate( 1 );
   sound_disabled = s;
   player_messageToggle( 1 );
   if (player.p != NULL)
      pilot_rmFlag( player.p, PILOT_HIDE );
   space_simulating = 0;

   /* Hilight stuff for missions. */
   mission_destHilight();

   /* Refresh overlay if necessary (player kept it open). */
   ovr_refresh();

   /* Update gui. */
   gui_setSystem();

   /* Start background. */
   background_load( cur_system->background );
}


/**
 * @brief Clears things that need to be cleared when leaving a system.
 */
static void space_clear(void)
{
   int i;

   /* Clear player stuff. */
   player_clear();

   /* Clear markers. */
   ovr_mrkClear();

   /* Destroy non-persistent pilots. */
   pilots_clean(1);

   /* Clear weapons. */
   weapon_clear();

   /* Clear explosions and other space effects. */
   spfx_clear();

   /* Destroy gatherables. */
   gatherable_free();

   /* Clear background. */
   background_clear();

   /* Clear dynamic factions. */
   factions_clearDynamic();

   /* Clear player locks and timers. */
   if (player.p != NULL) {
      pilot_lockClear(player.p);
      pilot_clearTimers(player.p);
   }

   /* Un-hilight planets. */
   for (i=0; i<array_size(planet_stack); i++) {
      planet_stack[i].hilights = 0;
   }

   /* Enable spawning. */
   space_spawn = 1;
}


/**
 * @brief Initializes an asteroid.
 *    @param ast Asteroid to initialize.
 *    @param field Asteroid field the asteroid belongs to.
 */
void asteroid_init( Asteroid *ast, AsteroidAnchor *field )
{
   int i;
   double mod, theta;
   double angle, radius;
   AsteroidType *at;
   int attempts = 0;

   ast->parent = field->id;

   /* randomly init the type of asteroid */
   i = RNG(0,field->ntype-1);
   ast->type = field->type[i];
   /* randomly init the gfx ID */
   at = &asteroid_types[ast->type];
   ast->gfxID = RNG(0, array_size(at->gfxs)-1);
   ast->armour = at->armour;

   do {
      angle = RNGF() * 2 * M_PI;
      radius = RNGF() * field->radius;
      ast->pos.x = radius * cos(angle) + field->pos.x;
      ast->pos.y = radius * sin(angle) + field->pos.y;

      /* If this is the first time and it's spawned outside the field,
       * we get rid of it so that density remains roughly consistent. */
      if ( (ast->appearing == ASTEROID_INIT) &&
            (space_isInField(&ast->pos) < 0) ) {
         ast->appearing = ASTEROID_INVISIBLE;
         return;
      }

      attempts++;
   } while ( (space_isInField(&ast->pos) < 0) && (attempts < 1000) );

   /* And a random velocity */
   theta = RNGF()*2.*M_PI;
   mod = RNGF() * 20;
   vect_pset( &ast->vel, mod, theta );

   /* Grow effect stuff */
   ast->appearing = ASTEROID_GROWING;
   ast->timer = 0.;
}


/**
 * @brief Initializes a debris.
 *    @param deb Debris to initialize.
 */
void debris_init( Debris *deb )
{
   double theta, mod;

   /* Position */
   deb->pos.x = (double)RNG(-DEBRIS_BUFFER, SCREEN_W + DEBRIS_BUFFER);
   deb->pos.y = (double)RNG(-DEBRIS_BUFFER, SCREEN_H + DEBRIS_BUFFER);

   /* And a random velocity */
   theta = RNGF()*2.*M_PI;
   mod = RNGF() * 20;
   vect_pset( &deb->vel, mod, theta );

   /* Randomly init the gfx ID */
   deb->gfxID = RNG(0,(int)nasterogfx-1);

   /* Random height vs player. */
   deb->height = .8 + RNGF()*.4;
}


/**
 * @brief Creates a new planet.
 */
Planet *planet_new (void)
{
   Planet *p, *old_stack;
   int realloced;

   /* Grow and initialize memory. */
   old_stack = planet_stack;
   p = &array_grow(&planet_stack);
   realloced = (old_stack!=planet_stack);
   memset(p, 0, sizeof(Planet));
   p->id = array_size(planet_stack) - 1;
   p->faction = 0;

   /* Reconstruct the jumps. */
   if (!systems_loading && realloced)
      systems_reconstructPlanets();

   return p;
}


/**
 * @brief Loads all the planets in the game.
 *
 *    @return 0 on success.
 */
static int planets_load ( void )
{
   size_t bufsize;
   char *buf, **planet_files, *file;
   xmlNodePtr node;
   xmlDocPtr doc;
   Planet *p;
   size_t i;
   Commodity **stdList;

   /* Load landing stuff. */
   landing_env = nlua_newEnv(0);
   nlua_loadStandard(landing_env);
   buf         = ndata_read( LANDING_DATA_PATH, &bufsize );
   if (nlua_dobufenv(landing_env, buf, bufsize, LANDING_DATA_PATH) != 0) {
      WARN( _("Failed to load landing file: %s\n"
            "%s\n"
            "Most likely Lua file has improper syntax, please check"),
            LANDING_DATA_PATH, lua_tostring(naevL,-1));
   }
   free(buf);

   /* Initialize stack if needed. */
   if (planet_stack == NULL)
      planet_stack = array_create_size(Planet, 256);

   /* Extract the list of standard commodities. */
   stdList = standard_commodities();

   /* Load XML stuff. */
   planet_files = PHYSFS_enumerateFiles( PLANET_DATA_PATH );
   for (i=0; planet_files[i]!=NULL; i++) {
      if (naev_pollQuit())
         break;

      if (!ndata_matchExt( planet_files[i], "xml" ))
         continue;

      asprintf( &file, "%s%s", PLANET_DATA_PATH, planet_files[i]);
      doc = xml_parsePhysFS( file );
      if (doc == NULL) {
         free(file);
         continue;
      }

      node = doc->xmlChildrenNode; /* first planet node */
      if (node == NULL) {
         WARN(_("Malformed %s file: does not contain elements"),file);
         free(file);
         xmlFreeDoc(doc);
         continue;
      }

      if (xml_isNode(node,XML_PLANET_TAG)) {
         p = planet_new();
         planet_parse( p, node, stdList );
      }

      /* Clean up. */
      free(file);
      xmlFreeDoc(doc);
   }

   /* Clean up. */
   PHYSFS_freeList( planet_files );
   array_free(stdList);

   return 0;
}


/**
 * @brief Gets the planet colour char.
 */
char planet_getColourChar(const Planet *p)
{
   if (!planet_hasService(p, PLANET_SERVICE_INHABITED))
      return 'I';

   if (!faction_isKnown(p->faction))
      return 'I';

   if (p->can_land || p->bribed) {
      if (faction_isPlayerFriend(p->faction))
         return 'F';
      return 'N';
   }

   if (faction_isPlayerEnemy(p->faction))
      return 'H';
   return 'R';
}


/**
 * @brief Gets the planet symbol.
 */
const char *planet_getSymbol(const Planet *p)
{
   if (!planet_hasService(p, PLANET_SERVICE_INHABITED)) {
      if (planet_hasService(p, PLANET_SERVICE_LAND))
         return "= ";
      return "";
   }

   if (!faction_isKnown(p->faction))
      return "? ";

   if (p->can_land || p->bribed) {
      if (faction_isPlayerFriend(p->faction))
         return "+ ";
      return "~ ";
   }

   if (faction_isPlayerEnemy(p->faction))
      return "!! ";
   return "* ";
}


/**
 * @brief Gets the planet colour.
 */
const glColour* planet_getColour(const Planet *p)
{
   if (!planet_hasService(p, PLANET_SERVICE_INHABITED))
      return &cFontInert;

   if (!faction_isKnown(p->faction))
      return &cFontInert;

   if (p->can_land || p->bribed) {
      if (faction_isPlayerFriend(p->faction))
         return &cFontFriend;
      return &cFontNeutral;
   }

   if (faction_isPlayerEnemy(p->faction))
      return &cFontHostile;
   return &cFontRestricted;
}


/**
 * @brief Updates the land possibilities of a planet.
 *
 *    @param p Planet to update land possibilities of.
 */
void planet_updateLand( Planet *p )
{
   char *str;

   /* Must be inhabited. */
   if (!planet_hasService( p, PLANET_SERVICE_INHABITED ) ||
         (player.p == NULL))
      return;

   /* Clean up old stuff. */
   free( p->land_msg );
   free( p->bribe_msg );
   free( p->bribe_ack_msg );
   p->can_land    = 0;
   p->land_msg    = NULL;
   p->bribe_msg   = NULL;
   p->bribe_ack_msg = NULL;
   p->bribe_price = 0;

   /* Set up function. */
   if (p->land_func == NULL)
      str = "land";
   else
      str = p->land_func;
   nlua_getenv( landing_env, str );
   lua_pushplanet( naevL, p->id );
   if (nlua_pcall(landing_env, 1, 5)) { /* error has occurred */
      WARN(_("Landing: '%s' : %s"), str, lua_tostring(naevL,-1));
      lua_pop(naevL,1);
      return;
   }

   /* Parse parameters. */
   p->can_land = lua_toboolean(naevL,-5);
   if (lua_isstring(naevL,-4))
      p->land_msg = strdup( lua_tostring(naevL,-4) );
   else {
      WARN( _("%s: %s (%s) -> return parameter 2 is not a string!"), LANDING_DATA_PATH, str, p->name );
      p->land_msg = strdup( _("Invalid land message") );
   }
   /* Parse bribing. */
   if (!p->can_land && lua_isnumber(naevL,-3)) {
      p->bribe_price = lua_tonumber(naevL,-3);
      /* We need the bribe message. */
      if (lua_isstring(naevL,-2))
         p->bribe_msg = strdup( lua_tostring(naevL,-2) );
      else {
         WARN( _("%s: %s (%s) -> return parameter 4 is not a string!"), LANDING_DATA_PATH, str, p->name );
         p->bribe_msg = strdup( _("Invalid bribe message") );
      }
      /* We also need the bribe ACK message. */
      if (lua_isstring(naevL,-1))
         p->bribe_ack_msg = strdup( lua_tostring(naevL,-1) );
      else {
         WARN( _("%s: %s (%s) -> return parameter 5 is not a string!"), LANDING_DATA_PATH, str, p->name );
         p->bribe_ack_msg = strdup( _("Invalid bribe ack message") );
      }
   }
   else if (lua_isstring(naevL,-3))
      p->bribe_msg = strdup( lua_tostring(naevL,-3) );
   else if (!lua_isnil(naevL,-3))
      WARN( _("%s: %s (%s) -> return parameter 3 is not a number or string or nil!"), LANDING_DATA_PATH, str, p->name );

   lua_pop(naevL,5);

   /* Unset bribe status if bribing is no longer possible. */
   if (p->bribed && p->bribe_ack_msg == NULL)
      p->bribed = 0;
}


/**
 * @brief Loads a planet's graphics (and radius).
 */
void planet_gfxLoad( Planet *planet )
{
   if (planet->real != ASSET_REAL)
      return;

   if (planet->gfx_space == NULL) {
      planet->gfx_space = gl_newImage( planet->gfx_spaceName, OPENGL_TEX_MIPMAPS );
      planet->radius = (planet->gfx_space->w + planet->gfx_space->h)/4.;
   }
}


/**
 * @brief Loads all the graphics for a star system.
 *
 *    @param sys System to load graphics for.
 */
void space_gfxLoad( StarSystem *sys )
{
   int i;
   for (i=0; i<array_size(sys->planets); i++)
      planet_gfxLoad( sys->planets[i] );
}


/**
 * @brief Unloads all the graphics for a star system.
 *
 *    @param sys System to unload graphics for.
 */
void space_gfxUnload( StarSystem *sys )
{
   int i;
   Planet *planet;
   for (i=0; i<array_size(sys->planets); i++) {
      planet = sys->planets[i];
      gl_freeTexture( planet->gfx_space );
      planet->gfx_space = NULL;
   }
}


/**
 * @brief Parses a planet from an xml node.
 *
 *    @param planet Planet to fill up.
 *    @param parent Node that contains planet data.
 *    @param[in] stdList The array of standard commodities.
 *    @return 0 on success.
 */
static int planet_parse( Planet *planet, const xmlNodePtr parent, Commodity **stdList )
{
   int i;
   char str[PATH_MAX], *tmp;
   xmlNodePtr node, cur, ccur;
   unsigned int flags;
   Commodity *com;
   Commodity **comms;

   /* Clear up memory for safe defaults. */
   flags          = 0;
   planet->real   = ASSET_REAL;
   planet->rdr_range_mod = 0.;
   comms          = array_create( Commodity* );

   /* Get the name. */
   xmlr_attr_strd( parent, "name", planet->name );

   node = parent->xmlChildrenNode;
   do {

      /* Only handle nodes. */
      xml_onlyNodes(node);

      if (xml_isNode(node,"virtual")) {
         planet->real   = ASSET_VIRTUAL;
         continue;
      }
      else if (xml_isNode(node,"GFX")) {
         cur = node->children;
         do {
            if (xml_isNode(cur,"space")) { /* load space gfx */
               snprintf( str, sizeof(str), PLANET_GFX_SPACE_PATH"%s", xml_get(cur));
               planet->gfx_spaceName = strdup(str);
               planet->gfx_spacePath = xml_getStrd(cur);
               planet->radius = -1.;
            }
            else if (xml_isNode(cur,"exterior")) { /* load land gfx */
               snprintf( str, sizeof(str), PLANET_GFX_EXTERIOR_PATH"%s", xml_get(cur));
               planet->gfx_exterior = strdup(str);
               planet->gfx_exteriorPath = xml_getStrd(cur);
            }
         } while (xml_nextNode(cur));
         continue;
      }
      else if (xml_isNode(node,"pos")) {
         cur          = node->children;
         do {
            if (xml_isNode(cur,"x")) {
               flags |= FLAG_XSET;
               planet->pos.x = xml_getFloat(cur);
            }
            else if (xml_isNode(cur,"y")) {
               flags |= FLAG_YSET;
               planet->pos.y = xml_getFloat(cur);
            }
         } while (xml_nextNode(cur));
         continue;
      }
      else if (xml_isNode(node, "presence")) {
         cur = node->children;
         do {
            xmlr_float(cur, "value", planet->presenceAmount);
            xmlr_int(cur, "range", planet->presenceRange);
            if (xml_isNode(cur,"faction")) {
               flags |= FLAG_FACTIONSET;
               planet->faction = faction_get( xml_get(cur) );
               continue;
            }
         } while (xml_nextNode(cur));
         continue;
      }
      else if (xml_isNode(node,"general")) {
         cur = node->children;
         do {
            /* Direct reads. */
            xmlr_strd(cur, "class", planet->class);
            xmlr_ulong(cur, "population", planet->population);
            xmlr_float(cur, "rdr_range_mod", planet->rdr_range_mod);

            if (xml_isNode(cur, "services")) {
               flags |= FLAG_SERVICESSET;
               ccur = cur->children;
               planet->services = 0;
               do {
                  xml_onlyNodes(ccur);

                  if (xml_isNode(ccur, "land")) {
                     planet->services |= PLANET_SERVICE_LAND;
                     tmp = xml_get(ccur);
                     if (tmp != NULL) {
                        planet->land_func = strdup(tmp);
#ifdef DEBUGGING
                        if (landing_env != LUA_NOREF) {
                           nlua_getenv( landing_env, tmp );
                           if (lua_isnil(naevL,-1))
                              WARN(_("Planet '%s' has landing function '%s' which is not found in '%s'."),
                                    planet->name, tmp, LANDING_DATA_PATH);
                           lua_pop(naevL,1);
                        }
#endif /* DEBUGGING */
                     }
                  }
                  else if (xml_isNode(ccur, "refuel"))
                     planet->services |= PLANET_SERVICE_REFUEL | PLANET_SERVICE_INHABITED;
                  else if (xml_isNode(ccur, "bar"))
                     planet->services |= PLANET_SERVICE_BAR | PLANET_SERVICE_INHABITED;
                  else if (xml_isNode(ccur, "missions"))
                     planet->services |= PLANET_SERVICE_MISSIONS | PLANET_SERVICE_INHABITED;
                  else if (xml_isNode(ccur, "commodity"))
                     planet->services |= PLANET_SERVICE_COMMODITY | PLANET_SERVICE_INHABITED;
                  else if (xml_isNode(ccur, "outfits"))
                     planet->services |= PLANET_SERVICE_OUTFITS | PLANET_SERVICE_INHABITED;
                  else if (xml_isNode(ccur, "shipyard"))
                     planet->services |= PLANET_SERVICE_SHIPYARD | PLANET_SERVICE_INHABITED;
                  else if (xml_isNode(ccur, "nomissionspawn"))
                     planet->flags |= PLANET_NOMISNSPAWN;
                  else if (xml_isNode(ccur, "uninhabited"))
                     planet->flags |= PLANET_UNINHABITED;
                  else if (xml_isNode(ccur, "blackmarket"))
                     planet->services |= PLANET_SERVICE_BLACKMARKET;
                  else
                     WARN(_("Planet '%s' has unknown services tag '%s'"), planet->name, ccur->name);

               } while (xml_nextNode(ccur));
            }

            else if (xml_isNode(cur, "commodities")) {
               ccur = cur->children;

               do {
                  if (xml_isNode(ccur,"commodity")) {
                     /* If the commodity is standard, don't re-add it. */
                     com = commodity_get( xml_get(ccur) );
                     if (com->standard == 1)
                        continue;

                     array_push_back( &comms, com );
                  }
               } while (xml_nextNode(ccur));
            }

            else if (xml_isNode(cur, "blackmarket")) {
               planet_addService(planet, PLANET_SERVICE_BLACKMARKET);
            }
         } while (xml_nextNode(cur));
         continue;
      }
      else if (xml_isNode(node, "tech")) {
         planet->tech = tech_groupCreateXML( node );
         continue;
      }

      DEBUG(_("Unknown node '%s' in planet '%s'"),node->name,planet->name);
   } while (xml_nextNode(node));

   /* Allow forcing to be uninhabited. */
   if (planet_isFlag(planet, PLANET_UNINHABITED))
      planet->services &= ~PLANET_SERVICE_INHABITED;

/*
 * verification
 */
#define MELEMENT(o,s)   if (o) WARN(_("Planet '%s' missing '%s' element"), planet->name, s)
   /* Issue warnings on missing items only it the asset is real. */
   if (planet->real == ASSET_REAL) {
      MELEMENT(planet->gfx_spaceName==NULL,"GFX space");
      MELEMENT( planet_hasService(planet,PLANET_SERVICE_LAND) &&
            planet->gfx_exterior==NULL,"GFX exterior");
      MELEMENT( planet_hasService(planet,PLANET_SERVICE_INHABITED) &&
            (planet->population==0), "population");
      MELEMENT((flags&FLAG_XSET)==0,"x");
      MELEMENT((flags&FLAG_YSET)==0,"y");
      MELEMENT(planet->class==NULL,"class");
      MELEMENT( planet_hasService(planet,PLANET_SERVICE_INHABITED) &&
            (flags&FLAG_FACTIONSET)==0,"faction");
      MELEMENT((flags&FLAG_SERVICESSET)==0,"services");
      MELEMENT( (planet_hasService(planet,PLANET_SERVICE_OUTFITS) ||
               planet_hasService(planet,PLANET_SERVICE_SHIPYARD)) &&
            (planet->tech==NULL), "tech" );
      /*MELEMENT( planet_hasService(planet,PLANET_SERVICE_COMMODITY) &&
            (array_size(planet->commodities)==0),"commodity" );*/
      /*MELEMENT( (flags&FLAG_FACTIONSET) && (planet->presenceAmount == 0.),
            "presence" );*/
   }
#undef MELEMENT

   /* Build commodities list */
   if (planet_hasService(planet, PLANET_SERVICE_COMMODITY)) {
      /* First, store all the standard commodities and prices. */
      if (array_size( stdList ) > 0) {
         planet->commodityPrice = array_create( CommodityPrice );
         planet->commodities = array_create( Commodity* );
         for (i=0; i<array_size(stdList); i++) {
            array_grow(&planet->commodities) = stdList[i];
            array_grow(&planet->commodityPrice).price = stdList[i]->price;
         }
      }

      /* Now add extra commodities */
      for (i=0; i<array_size(comms); i++) {
         com = comms[i];

         array_grow(&planet->commodities) = com;
         /* Set commodity price on this planet to the base price */
         array_grow(&planet->commodityPrice).price = com->price;
      }
      /* Shrink to minimum size. */
      array_shrink( &planet->commodities );
      array_shrink( &planet->commodityPrice );
   }
   /* Free temporary comms list. */
   array_free(comms);

   planet->rdr_range_mod = (planet->rdr_range_mod+100) / 100;

   return 0;
}


/**
 * @brief Adds a planet to a star system.
 *
 *    @param sys Star System to add planet to.
 *    @param planetname Name of the planet to add.
 *    @return 0 on success.
 */
int system_addPlanet( StarSystem *sys, const char *planetname )
{
   Planet *planet;

   if (sys == NULL)
      return -1;

   planet = planet_get(planetname);
   if (planet == NULL)
      return -1;
   array_push_back( &sys->planets, planet );
   array_push_back( &sys->planetsid, planet->id );

   /* add planet <-> star system to name stack */
   array_push_back( &planetname_stack, planet->name );
   array_push_back( &systemname_stack, sys->name );

   economy_addQueuedUpdate();

   /* Add the presence. */
   if (!systems_loading) {
      system_addPresence( sys, planet->faction, planet->presenceAmount, planet->presenceRange );
      system_setFaction(sys);
   }

   /* Reload graphics if necessary. */
   if (cur_system != NULL)
      space_gfxLoad( cur_system );

   return 0;
}


/**
 * @brief Removes a planet from a star system.
 *
 *    @param sys Star System to remove planet from.
 *    @param planetname Name of the planet to remove.
 *    @return 0 on success.
 */
int system_rmPlanet( StarSystem *sys, const char *planetname )
{
   int i, found;
   Planet *planet ;

   if (sys == NULL) {
      WARN(_("Unable to remove planet '%s' from NULL system."), planetname);
      return -1;
   }

   /* Try to find planet. */
   planet = planet_get( planetname );
   for (i=0; i<array_size(sys->planets); i++)
      if (sys->planets[i] == planet)
         break;

   /* Planet not found. */
   if (i>=array_size(sys->planets)) {
      WARN(_("Planet '%s' not found in system '%s' for removal."), planetname, sys->name);
      return -1;
   }

   /* Remove planet from system. */
   array_erase( &sys->planets, &sys->planets[i], &sys->planets[i+1] );
   array_erase( &sys->planetsid, &sys->planetsid[i], &sys->planetsid[i+1] );

   /* Remove the presence. */
   system_addPresence( sys, planet->faction, -(planet->presenceAmount), planet->presenceRange );

   /* Remove from the name stack thingy. */
   found = 0;
   for (i=0; i<array_size(planetname_stack); i++)
      if (strcmp(planetname, planetname_stack[i])==0) {
         array_erase( &planetname_stack, &planetname_stack[i], &planetname_stack[i+1] );
         array_erase( &systemname_stack, &systemname_stack[i], &systemname_stack[i+1] );
         found = 1;
         break;
      }
   if (found == 0)
      WARN(_("Unable to find planet '%s' and system '%s' in planet<->system stack."),
            planetname, sys->name );

   system_setFaction(sys);

   economy_addQueuedUpdate();

   return 0;
}


/**
 * @brief Adds a jump point to a star system.
 *
 * Note that systems_reconstructJumps, economy_addQueuedUpdate, and
 * economy_execQueued should always be run after this.
 *
 *    @param sys Star System to add jump point to.
 *    @param jumpname Name of the jump point to add.
 *    @param pos Position of the jump point.
 *    @param rdr_range_mod Radar range modifier of the jump point.
 *    @param flags Flags of the jump point.
 *    @return 0 on success.
 */
int system_addJump(StarSystem *sys, const char *jumpname, Vector2d pos,
      double rdr_range_mod, unsigned int flags)
{
   JumpPoint *j;
   StarSystem *target;

   /* Get target. */
   target = system_get(jumpname);
   if (target == NULL) {
      WARN(_("JumpPoint node for system '%s' has invalid target '%s'."),
            sys->name, jumpname);
      return -1;
   }

#ifdef DEBUGGING
   int i;
   for (i=0; i<array_size(sys->jumps); i++) {
      j = &sys->jumps[i];
      if (j->targetid != target->id)
         continue;

      WARN(_("Star System '%s' has duplicate jump point to '%s'."),
            sys->name, target->name );
      break;
   }
#endif /* DEBUGGING */

   /* Allocate more space. */
   j = &array_grow(&sys->jumps);
   memset(j, 0, sizeof(JumpPoint));

   /* Set attributes. */
   j->rdr_range_mod = rdr_range_mod;
   jp_setFlag(j, flags);
   if (!jp_isFlag(j, JP_AUTOPOS))
      vect_cset(&j->pos, VX(pos), VY(pos));

   /* Set some stuff. */
   j->target = target;
   j->targetid = j->target->id;
   j->radius = 200.;

   return 0;
}


/**
 * @brief Removes a jump point from a star system.
 *
 * Note that economy_execQueued should always be run after this.
 *
 *    @param sys Star System to remove jump point from.
 *    @param jumpname Name of the jump point to remove.
 *    @return 0 on success.
 */
int system_rmJump( StarSystem *sys, const char *jumpname )
{
   int i;
   JumpPoint *jump;

   if (sys == NULL) {
      WARN(_("Unable to remove jump point '%s' from NULL system."), jumpname);
      return -1;
   }

   /* Try to find planet. */
   jump = jump_get( jumpname, sys );
   for (i=0; i<array_size(sys->jumps); i++)
      if (&sys->jumps[i] == jump)
         break;

   /* Planet not found. */
   if (i>=array_size(sys->jumps)) {
      WARN(_("Jump point '%s' not found in system '%s' for removal."), jumpname, sys->name);
      return -1;
   }

   /* Remove jump from system. */
   array_erase( &sys->jumps, &sys->jumps[i], &sys->jumps[i+1] );

   /* Refresh presence */
   system_setFaction(sys);

   economy_addQueuedUpdate();

   return 0;
}


/**
 * @brief Initializes a new star system with null memory.
 */
static void system_init( StarSystem *sys )
{
   memset( sys, 0, sizeof(StarSystem) );
   sys->planets   = array_create( Planet* );
   sys->planetsid = array_create( int );
   sys->jumps     = array_create( JumpPoint );
   sys->asteroids = array_create( AsteroidAnchor );
   sys->astexclude= array_create( AsteroidExclusion );
   sys->faction = 0;
}


/**
 * @brief Creates a new star system.
 */
StarSystem *system_new (void)
{
   StarSystem *sys;
   int id;

   /* Protect current system in case of realloc. */
   id = -1;
   if (cur_system != NULL)
      id = system_index( cur_system );

   /* Grow array. */
   sys = &array_grow( &systems_stack );

   /* Reset cur_system. */
   if (id >= 0)
      cur_system = system_getIndex( id );

   /* Initialize system and id. */
   system_init( sys );
   sys->id = array_size(systems_stack)-1;

   /* Reconstruct the jumps, only truely necessary if the systems realloced. */
   if (!systems_loading)
      systems_reconstructJumps();

   return sys;
}

/**
 * @brief Reconstructs the jumps for a single system.
 */
void system_reconstructJumps (StarSystem *sys)
{
   double dx, dy;
   int j;
   JumpPoint *jp;
   double a;

   for (j=0; j<array_size(sys->jumps); j++) {
      jp             = &sys->jumps[j];
      jp->from       = sys;
      jp->target     = system_getIndex( jp->targetid );
      jp->returnJump = jump_getTarget( sys, jp->target );

      /* Get heading. */
      dx = jp->target->pos.x - sys->pos.x;
      dy = jp->target->pos.y - sys->pos.y;
      a = atan2( dy, dx );
      if (a < 0.)
         a += 2.*M_PI;

      /* Update position if needed.. */
      if (jp->flags & JP_AUTOPOS) {
         jp->pos.x   = sys->radius*cos(a);
         jp->pos.y   = sys->radius*sin(a);
      }

      /* Update jump specific data. */
      gl_getSpriteFromDir( &jp->sx, &jp->sy, jumppoint_gfx, a );
      jp->angle = 2.*M_PI-a;
      jp->cosa  = cos(jp->angle);
      jp->sina  = sin(jp->angle);
   }
}

/**
 * @brief Reconstructs the jumps.
 */
void systems_reconstructJumps (void)
{
   StarSystem *sys;
   int i;

   /* So we need to calculate the shortest jump. */
   for (i=0; i<array_size(systems_stack); i++) {
      sys = &systems_stack[i];
      system_reconstructJumps(sys);
   }
}


/**
 * @brief Updates the system planet pointers.
 */
void systems_reconstructPlanets (void)
{
   StarSystem *sys;
   int i, j;

   for (i=0; i<array_size(systems_stack); i++) {
      sys = &systems_stack[i];
      for (j=0; j<array_size(sys->planetsid); j++)
         sys->planets[j] = &planet_stack[ sys->planetsid[j] ];
   }
}


/**
 * @brief Creates a system from an XML node.
 *
 *    @param sys System to set up.
 *    @param parent XML node to get system from.
 *    @return System matching parent data.
 */
static StarSystem* system_parse( StarSystem *sys, const xmlNodePtr parent )
{
   xmlNodePtr cur, node;
   uint32_t flags;

   /* Clear memory for safe defaults. */
   flags          = 0;
   sys->presence  = array_create( SystemPresence );
   sys->ownerpresence = 0.;
   sys->nebu_hue  = NEBULA_DEFAULT_HUE;

   xmlr_attr_strd( parent, "name", sys->name );

   node  = parent->xmlChildrenNode;
   do { /* load all the data */

      /* Only handle nodes. */
      xml_onlyNodes(node);

      if (xml_isNode(node,"pos")) {
         cur = node->children;
         do {
            if (xml_isNode(cur,"x")) {
               flags |= FLAG_XSET;
               sys->pos.x = xml_getFloat(cur);
            }
            else if (xml_isNode(cur,"y")) {
               flags |= FLAG_YSET;
               sys->pos.y = xml_getFloat(cur);
            }
         } while (xml_nextNode(cur));
         continue;
      }
      else if (xml_isNode(node,"general")) {
         cur = node->children;
         do {
            xmlr_strd( cur, "background", sys->background );
            xmlr_strd( cur, "features", sys->features );
            xmlr_int( cur, "stars", sys->stars );
            xmlr_float( cur, "radius", sys->radius );
            if (xml_isNode(cur,"rdr_range_mod")) {
               sys->rdr_range_mod = xml_getFloat(cur);
            }
            else if (xml_isNode(cur,"nebula")) {
               xmlr_attr_float( cur, "volatility", sys->nebu_volatility );
               xmlr_attr_float_def( cur, "hue", sys->nebu_hue, NEBULA_DEFAULT_HUE );
               sys->nebu_density = xml_getFloat(cur);
            }
         } while (xml_nextNode(cur));
         continue;
      }
      /* Loads all the assets. */
      else if (xml_isNode(node,"assets")) {
         cur = node->children;
         do {
            if (naev_pollQuit())
               break;

            if (xml_isNode(cur,"asset"))
               system_addPlanet( sys, xml_get(cur) );
         } while (xml_nextNode(cur));
         continue;
      }

      /* Avoid warning. */
      if (xml_isNode(node,"jumps"))
         continue;
      if (xml_isNode(node,"asteroids"))
         continue;

      DEBUG(_("Unknown node '%s' in star system '%s'"),node->name,sys->name);
   } while (xml_nextNode(node));

   array_shrink( &sys->planets );
   array_shrink( &sys->planetsid );

   /* Convert hue from 0 to 359 value to 0 to 1 value. */
   sys->nebu_hue /= 360.;

   sys->rdr_range_mod = (sys->rdr_range_mod+100) / 100;

#define MELEMENT(o,s)      if (o) WARN(_("Star System '%s' missing '%s' element"), sys->name, s)
   if (sys->name == NULL) WARN(_("Star System '%s' missing 'name' tag"), sys->name);
   MELEMENT((flags&FLAG_XSET)==0,"x");
   MELEMENT((flags&FLAG_YSET)==0,"y");
   MELEMENT(sys->stars==0,"stars");
   MELEMENT(sys->radius==0.,"radius");
#undef MELEMENT

   return 0;
}


/**
 * @brief Compares two system presences.
 */
static int sys_cmpSysFaction( const void *a, const void *b )
{
   SystemPresence *spa, *spb;

   spa = (SystemPresence*) a;
   spb = (SystemPresence*) b;

   /* Compare value. */
   if (spa->value < spb->value)
      return +1;
   else if (spa->value > spb->value)
      return -1;

   /* Compare faction id. */
   if (spa->faction < spb->faction)
      return +1;
   else if (spa->faction > spb->faction)
      return -1;

   return 0;
}


/**
 * @brief Sets the system faction based on the planets it has.
 *
 *    @param sys System to set the faction of.
 */
void system_setFaction( StarSystem *sys )
{
   int i, j;
   Planet *pnt;

   /* Sort presences in descending order. */
   if (array_size(sys->presence) != 0)
      qsort( sys->presence, array_size(sys->presence), sizeof(SystemPresence), sys_cmpSysFaction );

   sys->faction = 0;
   for (i=0; i<array_size(sys->presence); i++) {
      for (j=0; j<array_size(sys->planets); j++) { /** @todo Handle multiple different factions. */
         pnt = sys->planets[j];
         if (pnt->real != ASSET_REAL)
            continue;

         if (pnt->faction != sys->presence[i].faction)
            continue;

         sys->faction = pnt->faction;
         return;
      }
   }
}


/**
 * @brief Parses a single jump point for a system.
 *
 *    @param node Parent node containing jump point information.
 *    @param sys System to which the jump point belongs.
 *    @return 0 on success.
 */
static int system_parseJumpPoint( const xmlNodePtr node, StarSystem *sys )
{
   JumpPoint *j;
   char *buf;
   xmlNodePtr cur;
   double x, y;
   StarSystem *target;
   int pos;

   /* Get target. */
   xmlr_attr_strd( node, "target", buf );
   if (buf == NULL) {
      WARN(_("JumpPoint node for system '%s' has no target attribute."), sys->name);
      return -1;
   }
   target = system_get(buf);
   if (target == NULL) {
      WARN(_("JumpPoint node for system '%s' has invalid target '%s'."), sys->name, buf );
      free(buf);
      return -1;
   }
   free(buf);

#ifdef DEBUGGING
   int i;
   for (i=0; i<array_size(sys->jumps); i++) {
      j = &sys->jumps[i];
      if (j->targetid != target->id)
         continue;

      WARN(_("Star System '%s' has duplicate jump point to '%s'."),
            sys->name, target->name );
      break;
   }
#endif /* DEBUGGING */

   /* Allocate more space. */
   j = &array_grow( &sys->jumps );
   memset( j, 0, sizeof(JumpPoint) );

   /* Set some stuff. */
   j->from = sys;
   j->target = target;
   j->targetid = j->target->id;
   j->radius = 200.;

   pos = 0;

   /* Parse data. */
   cur = node->xmlChildrenNode;
   do {
      xmlr_float( cur, "radius", j->radius );

      /* Handle position. */
      if (xml_isNode(cur,"pos")) {
         pos = 1;
         xmlr_attr_float( cur, "x", x );
         xmlr_attr_float( cur, "y", y );

         /* Set position. */
         vect_cset( &j->pos, x, y );
      }
      else if (xml_isNode(cur,"autopos"))
         jp_setFlag(j,JP_AUTOPOS);
      else if (xml_isNode(cur,"hidden"))
         jp_setFlag(j,JP_HIDDEN);
      else if (xml_isNode(cur,"exitonly"))
         jp_setFlag(j,JP_EXITONLY);
      else if (xml_isNode(cur,"express"))
         jp_setFlag(j,JP_EXPRESS);
      else if (xml_isNode(cur,"longrange"))
         jp_setFlag(j,JP_LONGRANGE);

      xmlr_float(cur,"rdr_range_mod",j->rdr_range_mod);
   } while (xml_nextNode(cur));

   if (!jp_isFlag(j,JP_AUTOPOS) && !pos)
      WARN(_("JumpPoint in system '%s' is missing pos element but does not have autopos flag."), sys->name);

   j->rdr_range_mod = (j->rdr_range_mod+100) / 100;

   return 0;
}


/**
 * @brief Loads the jumps into a system.
 *
 *    @param parent System parent node.
 */
static void system_parseJumps( const xmlNodePtr parent )
{
   int i;
   StarSystem *sys;
   char* name;
   xmlNodePtr cur, node;

   xmlr_attr_strd( parent, "name", name );
   sys = NULL;
   for (i=0; i<array_size(systems_stack); i++) {
      if (strcmp( systems_stack[i].name, name)==0) {
         sys = &systems_stack[i];
         break;
      }
   }
   if (sys == NULL) {
      WARN(_("System '%s' was not found in the stack for some reason"),name);
      return;
   }
   free(name); /* no more need for it */

   node  = parent->xmlChildrenNode;

   do { /* load all the data */
      if (xml_isNode(node,"jumps")) {
         cur = node->children;
         do {
            if (naev_pollQuit())
               break;

            if (xml_isNode(cur,"jump"))
               system_parseJumpPoint( cur, sys );
         } while (xml_nextNode(cur));
      }
   } while (xml_nextNode(node));

   array_shrink( &sys->jumps );
}


/**
 * @brief Parses a single asteroid field for a system.
 *
 *    @param node Parent node containing asteroid field information.
 *    @param sys System.
 *    @return 0 on success.
 */
static int system_parseAsteroidField( const xmlNodePtr node, StarSystem *sys )
{
   int i;
   AsteroidAnchor *a;
   xmlNodePtr cur;
   double x, y;
   char *name;
   int pos;

   /* Allocate more space. */
   a = &array_grow( &sys->asteroids );
   memset( a, 0, sizeof(AsteroidAnchor) );

   /* Initialize stuff. */
   pos         = 1;
   a->density  = .2;
   a->area     = 0.;
   a->ntype    = 0;
   a->type     = NULL;
   a->radius   = 0.;
   vect_cset( &a->pos, 0., 0. );

   /* Parse data. */
   cur = node->xmlChildrenNode;
   do {
      xmlr_float( cur,"density", a->density );

      /* Handle types of asteroids. */
      if (xml_isNode(cur,"type")) {
         a->ntype++;
         if (a->type==NULL)
            a->type = malloc( sizeof(int) );
         else
            a->type = realloc( a->type, (a->ntype)*sizeof(int) );

         name = xml_get(cur);
         /* Find the ID */
         for (i=0; i<array_size(asteroid_types); i++) {
            if ( (strcmp(asteroid_types[i].ID,name)==0) )
               a->type[a->ntype-1] = i;
         }
      }

      xmlr_float( cur, "radius", a->radius );

      /* Handle position. */
      if (xml_isNode(cur,"pos")) {
         pos = 1;
         xmlr_attr_float( cur, "x", x );
         xmlr_attr_float( cur, "y", y );

         /* Set position. */
         vect_cset( &a->pos, x, y );
      }

   } while (xml_nextNode(cur));

   if (!pos)
      WARN(_("Asteroid field in %s has no position."), sys->name);

   if (a->radius == 0.)
      WARN(_("Asteroid field in %s has no radius."), sys->name);

   /* By default, take the first in the list. */
   if (a->type == NULL) {
       a->type = malloc( sizeof(int) );
       a->ntype = 1;
       a->type[0] = 0;
   }

   /* Calculate area */
   a->area = M_PI * a->radius * a->radius;

   /* Compute number of asteroids */
   a->nb      = floor( ABS(a->area) / ASTEROID_REF_AREA * a->density );
   a->ndebris = floor(100*a->density);

   return 0;
}


/**
 * @brief Parses a single asteroid exclusion zone for a system.
 *
 *    @param node Parent node containing asteroid exclusion information.
 *    @param sys System.
 *    @return 0 on success.
 */
static int system_parseAsteroidExclusion( const xmlNodePtr node, StarSystem *sys )
{
   AsteroidExclusion *a;
   xmlNodePtr cur;
   double x, y;
   int pos;

   /* Allocate more space. */
   a = &array_grow( &sys->astexclude );
   memset( a, 0, sizeof(*a) );

   /* Initialize stuff. */
   pos         = 0;
   a->radius   = 0.;
   vect_cset( &a->pos, 0., 0. );

   /* Parse data. */
   cur = node->xmlChildrenNode;
   do {
      xmlr_float( cur, "radius", a->radius );

      /* Handle position. */
      if (xml_isNode(cur,"pos")) {
         pos = 1;
         xmlr_attr_float( cur, "x", x );
         xmlr_attr_float( cur, "y", y );

         /* Set position. */
         vect_cset( &a->pos, x, y );
      }

   } while (xml_nextNode(cur));

   if (!pos)
      WARN(_("Asteroid exclusion in %s has no position."), sys->name);

   if (a->radius == 0.)
      WARN(_("Asteroid exclusion in %s has no radius."), sys->name);

   return 0;
}


/**
 * @brief Loads the asteroid anchor into a system.
 *
 *    @param parent System parent node.
 *    @param sys System.
 */
static void system_parseAsteroids( const xmlNodePtr parent, StarSystem *sys )
{
   xmlNodePtr cur, node;

   node  = parent->xmlChildrenNode;

   do { /* load all the data */
      if (naev_pollQuit())
         break;

      if (xml_isNode(node,"asteroids")) {
         cur = node->children;
         do {
            if (xml_isNode(cur,"asteroid"))
               system_parseAsteroidField( cur, sys );
            else if (xml_isNode(cur,"exclusion"))
               system_parseAsteroidExclusion( cur, sys );
         } while (xml_nextNode(cur));
      }
   } while (xml_nextNode(node));

   array_shrink( &sys->asteroids );
   array_shrink( &sys->astexclude );
}


/**
 * @brief Loads the entire universe into ram - pretty big feat eh?
 *
 *    @return 0 on success.
 */
int space_load (void)
{
   size_t i;
   int j;
   int ret;
   StarSystem *sys;
   char **asteroid_files, file[PATH_MAX];

   /* Loading. */
   systems_loading = 1;

   /* Create some arrays. */
   planetname_stack = array_create( char* );
   systemname_stack = array_create( char* );

   /* Load jump point graphic - must be before systems_load(). */
   jumppoint_gfx = gl_newSprite(  PLANET_GFX_SPACE_PATH"jumppoint.webp", 4, 4, OPENGL_TEX_MIPMAPS );
   jumpbuoy_gfx = gl_newImage(  PLANET_GFX_SPACE_PATH"jumpbuoy.webp", 0 );

   /* Load planets. */
   ret = planets_load();
   if (ret < 0)
      return ret;

   /* Load asteroid types. */
   ret = asteroidTypes_load();
   if (ret < 0)
      return ret;

   /* Load systems. */
   ret = systems_load();
   if (ret < 0)
      return ret;

   /* Load asteroid graphics. */
   asteroid_files = PHYSFS_enumerateFiles(ASTEROID_DEBRIS_GFX_PATH);
   for (nasterogfx=0; asteroid_files[nasterogfx]!=NULL; nasterogfx++) {}
   asteroid_debris_gfx = malloc(sizeof(glTexture*) * nasterogfx);

   for (i=0; asteroid_files[i]!=NULL; i++) {
      snprintf(file, sizeof(file), "%s%s",
            ASTEROID_DEBRIS_GFX_PATH, asteroid_files[i]);
      asteroid_debris_gfx[i] = gl_newImage(file, OPENGL_TEX_MIPMAPS);
   }

   /* Done loading. */
   systems_loading = 0;

   /* Apply all the presences. */
   for (i=0; (int)i<array_size(systems_stack); i++)
      system_addAllPlanetsPresence(&systems_stack[i]);

   /* Determine dominant faction. */
   for (i=0; (int)i<array_size(systems_stack); i++)
      system_setFaction( &systems_stack[i] );

   /* Reconstruction. */
   systems_reconstructJumps();
   systems_reconstructPlanets();

   /* Fine tuning. */
   for (i=0; (int)i<array_size(systems_stack); i++) {
      if (naev_pollQuit())
         break;

      sys = &systems_stack[i];

      /* Save jump indexes. */
      for (j=0; j<array_size(sys->jumps); j++)
         sys->jumps[j].targetid = sys->jumps[j].target->id;
      sys->ownerpresence = system_getPresence( sys, sys->faction );
   }

   /* Calculate commodity prices (sinusoidal model). */
   economy_initialiseCommodityPrices();

   PHYSFS_freeList( asteroid_files );

   return 0;
}


/**
 * @brief Loads the asteroids types.
 *
 *    @return 0 on success.
 */
static int asteroidTypes_load (void)
{
   int namdef, qttdef;
   AsteroidType *at;
   char *str;
   xmlNodePtr node, cur, child;
   xmlDocPtr doc;

   /* Load the data. */
   doc = xml_parsePhysFS( ASTERO_DATA_PATH );
   if (doc == NULL)
      return -1;

   /* Get the root node. */
   node = doc->xmlChildrenNode;
   if (!xml_isNode(node,"Asteroid_types")) {
      WARN( _("Malformed '%s' file: missing root element 'Asteroid_types'"), ASTERO_DATA_PATH);
      return -1;
   }

   /* Get the first node. */
   node = node->xmlChildrenNode; /* first event node */
   if (node == NULL) {
      WARN( _("Malformed '%s' file: does not contain elements"), ASTERO_DATA_PATH);
      return -1;
   }

   asteroid_types = array_create( AsteroidType );
   do {
      if (naev_pollQuit())
         break;

      if (xml_isNode(node,"asteroid")) {
         /* Load it. */
         at = &array_grow( &asteroid_types );
         at->gfxs = array_create( glTexture* );
         at->material = array_create( Commodity* );
         at->quantity = array_create( int );
         at->armour = 0.;

         cur = node->children;
         do {
            if (xml_isNode(cur,"gfx"))
               array_push_back(&at->gfxs,
                     xml_parseTexture(cur, ASTEROID_GFX_PATH"%s", 1, 1, 
                        OPENGL_TEX_MAPTRANS | OPENGL_TEX_MIPMAPS));

            else if (xml_isNode(cur,"id"))
               at->ID = xml_getStrd(cur);

            else if (xml_isNode(cur,"armour"))
               at->armour = xml_getFloat(cur);

            else if (xml_isNode(cur,"commodity")) {
               /* Check that name and quantity are defined. */
               namdef = 0; qttdef = 0;

               child = cur->children;
               do {
                  if (xml_isNode(child,"name")) {
                     str = xml_get(child);
                     array_push_back( &at->material, commodity_get( str ) );
                     namdef = 1;
                  }
                  else if (xml_isNode(child,"quantity")) {
                     array_push_back( &at->quantity, xml_getInt(child) );
                     qttdef = 1;
                  }
               } while (xml_nextNode(child));

               if (namdef == 0 || qttdef == 0)
                  ERR(_("Asteroid type's commodity lacks name or quantity."));
            }
         } while (xml_nextNode(cur));

         if (array_size(at->gfxs)==0)
            WARN(_("Asteroid type has no gfx associated."));
      }
   } while (xml_nextNode(node));

   /* Shrink to minimum. */
   array_shrink( &asteroid_types );

   /* Clean up. */
   xmlFreeDoc(doc);

   return 0;
}


/**
 * @brief Loads the entire systems, needs to be called after planets_load.
 *
 * Does multiple passes to load:
 *
 *  - First loads the star systems.
 *  - Next sets the jump routes.
 *
 *    @return 0 on success.
 */
static int systems_load (void)
{
   char **system_files, *file;
   xmlNodePtr node;
   xmlDocPtr doc;
   StarSystem *sys;
   size_t i;

   /* Allocate if needed. */
   if (systems_stack == NULL)
      systems_stack = array_create( StarSystem );

   system_files = PHYSFS_enumerateFiles( SYSTEM_DATA_PATH );

   /*
    * First pass - loads all the star systems_stack.
    */
   for (i=0; system_files[i]!=NULL; i++) {
      if (!ndata_matchExt( system_files[i], "xml" ))
         continue;

      asprintf( &file, "%s%s", SYSTEM_DATA_PATH, system_files[i] );
      /* Load the file. */
      doc = xml_parsePhysFS( file );
      if (doc == NULL)
         continue;

      node = doc->xmlChildrenNode; /* first planet node */
      if (node == NULL) {
         WARN(_("Malformed %s file: does not contain elements"),file);
         xmlFreeDoc(doc);
         continue;
      }

      sys = system_new();
      system_parse( sys, node );
      system_parseAsteroids(node, sys); /* load the asteroids anchors */

      /* Clean up. */
      xmlFreeDoc(doc);
      free( file );
   }

   /*
    * Second pass - loads all the jump routes.
    */
   for (i=0; system_files[i]!=NULL; i++) {
      if (naev_pollQuit())
         break;

      asprintf( &file, "%s%s", SYSTEM_DATA_PATH, system_files[i] );
      /* Load the file. */
      doc = xml_parsePhysFS( file );
      free( file );
      file = NULL;
      if (doc == NULL)
         continue;

      node = doc->xmlChildrenNode; /* first planet node */
      if (node == NULL) {
         xmlFreeDoc(doc);
         continue;
      }

      system_parseJumps(node); /* will automatically load the jumps into the system */

      /* Clean up. */
      xmlFreeDoc(doc);
   }

   DEBUG( n_( "Loaded %d Star System", "Loaded %d Star Systems", array_size(systems_stack) ), array_size(systems_stack) );
   DEBUG( n_( "       with %d Planet", "       with %d Planets", array_size(planet_stack) ), array_size(planet_stack) );

   /* Clean up. */
   PHYSFS_freeList( system_files );

   return 0;
}


/**
 * @brief Renders the system.
 *
 *    @param dt Current delta tick.
 */
void space_render( const double dt )
{
   if (cur_system == NULL)
      return;

   if (cur_system->nebu_density > 0.)
      nebu_render(dt);
   else
      background_render(dt);
}


/**
 * @brief Renders the system overlay.
 *
 *    @param dt Current delta tick.
 */
void space_renderOverlay( const double dt )
{
   int i, j;
   double x, y;
   AsteroidAnchor *ast;
   Pilot *pplayer;
   Solid *psolid;

   if (cur_system == NULL)
      return;

   /* Render the debris. */
   pplayer = pilot_get( PLAYER_ID );
   if (pplayer != NULL) {
      psolid  = pplayer->solid;
      for (i=0; i < array_size(cur_system->asteroids); i++) {
         ast = &cur_system->asteroids[i];
         x = psolid->pos.x - SCREEN_W/2;
         y = psolid->pos.y - SCREEN_H/2;
         for (j=0; j < ast->ndebris; j++) {
           if (ast->debris[j].height > 1.)
              space_renderDebris( &ast->debris[j], x, y );
         }
      }
   }

   /* Render overlay if necessary. */
   background_renderOverlay( dt );

   if ((cur_system->nebu_density > 0.) &&
         !menu_isOpen( MENU_MAIN ))
      nebu_renderOverlay(dt);
}


/**
 * @brief Renders the current systemsplanets.
 */
void planets_render (void)
{
   int i, j;
   double x, y;
   AsteroidAnchor *ast;
   Pilot *pplayer;
   Solid *psolid;

   /* Must be a system. */
   if (cur_system==NULL)
      return;

   /* Render the jumps. */
   for (i=0; i < array_size(cur_system->jumps); i++)
      space_renderJumpPoint( &cur_system->jumps[i], i );

   /* Render the planets. */
   for (i=0; i < array_size(cur_system->planets); i++)
      if (cur_system->planets[i]->real == ASSET_REAL)
         space_renderPlanet( cur_system->planets[i] );

   /* Get the player in order to compute the offset for debris. */
   pplayer = pilot_get( PLAYER_ID );
   if (pplayer != NULL)
      psolid  = pplayer->solid;

   /* Render the asteroids & debris. */
   for (i=0; i < array_size(cur_system->asteroids); i++) {
      ast = &cur_system->asteroids[i];
      for (j=0; j < ast->nb; j++)
        space_renderAsteroid( &ast->asteroids[j] );

      if (pplayer != NULL) {
         x = psolid->pos.x - SCREEN_W/2;
         y = psolid->pos.y - SCREEN_H/2;
         for (j=0; j < ast->ndebris; j++) {
           if (ast->debris[j].height < 1.)
              space_renderDebris( &ast->debris[j], x, y );
         }
      }
   }

   /* Render gatherable stuff. */
   gatherable_render();

}


/**
 * @brief Renders a jump point.
 */
static void space_renderJumpPoint( const JumpPoint *jp, int i )
{
   const glColour *c;

   if (!jp_isUsable(jp))
      return;

   if ((player.p != NULL) && (i==player.p->nav_hyperspace) &&
         (pilot_isFlag(player.p, PILOT_HYPERSPACE) || space_canHyperspace(player.p)))
      c = &cWhite;
   else if (jp_isFlag(jp, JP_HIDDEN))
      c = &cHiddenJump;
   else
      c = &cJump;

   gl_blitSprite( jumppoint_gfx, jp->pos.x, jp->pos.y, jp->sx, jp->sy, c );

   /* Draw buoys next to "highway" jump points. */
   if (jp_isFlag(jp, JP_EXPRESS)) {
      gl_blitSprite( jumpbuoy_gfx, jp->pos.x + 200 * jp->sina, jp->pos.y + 200 * jp->cosa, 0, 0, NULL ); /* Left */
      gl_blitSprite( jumpbuoy_gfx, jp->pos.x + -200 * jp->sina, jp->pos.y + -200 * jp->cosa, 0, 0, NULL ); /* Right */
   }
}


/**
 * @brief Renders a planet.
 */
static void space_renderPlanet( const Planet *p )
{
   gl_blitSprite( p->gfx_space, p->pos.x, p->pos.y, 0, 0, NULL );
}


/**
 * @brief Renders an asteroid.
 */
static void space_renderAsteroid( const Asteroid *a )
{
   int i;
   double scale, nx, ny;
   AsteroidType *at;
   Commodity *com;
   char c[20];
   int fh;

   /* Skip invisible asteroids */
   if (a->appearing == ASTEROID_INVISIBLE)
      return;

   /* Check if needs scaling. */
   if (a->appearing == ASTEROID_GROWING)
      scale = CLAMP( 0., 1., a->timer / 2. );
   else if (a->appearing == ASTEROID_SHRINKING)
      scale = CLAMP( 0., 1., 1. - a->timer / 2. );
   else
      scale = 1.;

   at = &asteroid_types[a->type];

   gl_blitSpriteInterpolateScale( at->gfxs[a->gfxID], at->gfxs[a->gfxID], 1,
                                  a->pos.x, a->pos.y, scale, scale, 0, 0, NULL );

   /* Add the commodities if player has an asteroid scanner. */
   if ((player.p == NULL) || (!player.p->stats.misc_asteroid_scan))
      return;

   /* Add a buffer to font height to give space for the outline. */
   fh = gl_smallFont.h + 2;
   gl_gameToScreenCoords(&nx, &ny, a->pos.x, a->pos.y);
   for (i=0; i<array_size(at->material); i++) {
      com = at->material[i];
      gl_blitSprite(com->gfx_space, a->pos.x, a->pos.y - fh*i, 0, 0, NULL);
      snprintf(c, sizeof(c), "×%d", at->quantity[i]);
      gl_printRaw(&gl_smallFont, nx + 10, ny - fh/2 - fh*i,
            &cFontWhite, -1., c);
   }
}


/**
 * @brief Renders a debris.
 */
static void space_renderDebris( const Debris *d, double x, double y )
{
   double scale;
   Vector2d *testVect;

   scale = .5;

   testVect = malloc(sizeof(Vector2d));
   testVect->x = d->pos.x + x;
   testVect->y = d->pos.y + y;

   if ( space_isInField( testVect ) == 0 )
      gl_blitSpriteInterpolateScale(
         asteroid_debris_gfx[d->gfxID], asteroid_debris_gfx[d->gfxID], 1,
         testVect->x, testVect->y, scale, scale, 0, 0, &cInert);
   free(testVect);
}


/**
 * @brief Cleans up the system.
 */
void space_exit (void)
{
   int i, j;
   Planet *pnt;
   AsteroidAnchor *ast;
   StarSystem *sys;
   AsteroidType *at;

   /* Free standalone graphic textures */
   gl_freeTexture(jumppoint_gfx);
   jumppoint_gfx = NULL;
   gl_freeTexture(jumpbuoy_gfx);
   jumpbuoy_gfx = NULL;

   /* Free asteroid graphics. */
   for (i=0; i<(int)nasterogfx; i++)
      gl_freeTexture(asteroid_debris_gfx[i]);
   free(asteroid_debris_gfx);

   /* Free the names. */
   array_free(planetname_stack);
   array_free(systemname_stack);

   /* Free the planets. */
   for (i=0; i < array_size(planet_stack); i++) {
      pnt = &planet_stack[i];

      free(pnt->name);
      free(pnt->class);

      /* graphics */
      if (pnt->gfx_spaceName != NULL) {
         gl_freeTexture( pnt->gfx_space );
         free(pnt->gfx_spaceName);
         free(pnt->gfx_spacePath);
      }
      if (pnt->gfx_exterior != NULL) {
         free(pnt->gfx_exterior);
         free(pnt->gfx_exteriorPath);
      }

      /* Landing. */
      free(pnt->land_func);
      free(pnt->land_msg);
      free(pnt->bribe_msg);
      free(pnt->bribe_ack_msg);

      /* tech */
      if (pnt->tech != NULL)
         tech_groupDestroy( pnt->tech );

      /* commodities */
      array_free(pnt->commodities);
      array_free(pnt->commodityPrice);
   }
   array_free(planet_stack);

   /* Free the systems. */
   for (i=0; i < array_size(systems_stack); i++) {
      free(systems_stack[i].name);
      free(systems_stack[i].background);
      free(systems_stack[i].features);
      array_free(systems_stack[i].jumps);
      array_free(systems_stack[i].presence);
      array_free(systems_stack[i].planets);
      array_free(systems_stack[i].planetsid);

      /* Free the asteroids. */
      sys = &systems_stack[i];

      for (j=0; j < array_size(sys->asteroids); j++) {
         ast = &sys->asteroids[j];
         free(ast->asteroids);
         free(ast->debris);
         free(ast->type);
      }
      array_free(sys->asteroids);
      array_free(sys->astexclude);

   }
   array_free(systems_stack);
   systems_stack = NULL;

   /* Free the asteroid types. */
   for (i=0; i < array_size(asteroid_types); i++) {
      at = &asteroid_types[i];
      free(at->ID);
      array_free(at->material);
      array_free(at->quantity);
      for (j=0; j<array_size(at->gfxs); j++)
         gl_freeTexture(at->gfxs[j]);
      array_free(at->gfxs);
   }
   array_free(asteroid_types);
   asteroid_types = NULL;

   /* Free the gatherable stack. */
   gatherable_free();

   /* Free landing lua. */
   if (landing_env != LUA_NOREF)
      nlua_freeEnv( landing_env );
   landing_env = LUA_NOREF;
}


/**
 * @brief Clears all system knowledge.
 */
void space_clearKnown (void)
{
   int i, j;
   StarSystem *sys;
   for (i=0; i<array_size(systems_stack); i++) {
      sys = &systems_stack[i];
      sys_rmFlag(sys,SYSTEM_KNOWN);
      sys_rmFlag(sys,SYSTEM_HIDDEN);
      for (j=0; j<array_size(sys->jumps); j++)
         jp_rmFlag(&sys->jumps[j],JP_KNOWN);
   }
   for (j=0; j<array_size(planet_stack); j++)
      planet_rmFlag(&planet_stack[j],PLANET_KNOWN);
}


/**
 * @brief Clears all system markers.
 */
void space_clearMarkers (void)
{
   int i;

   for (i=0; i<array_size(systems_stack); i++) {
      sys_rmFlag(&systems_stack[i], SYSTEM_MARKED);
      systems_stack[i].markers_computer = 0;
      systems_stack[i].markers_plot = 0;
      systems_stack[i].markers_high = 0;
      systems_stack[i].markers_low = 0;
   }
}


/**
 * @brief Clears all the system computer markers.
 */
void space_clearComputerMarkers (void)
{
   int i;

   for (i=0; i<array_size(systems_stack); i++) {
      sys_rmFlag(&systems_stack[i], SYSTEM_CMARKED);
      systems_stack[i].markers_new = 0;
   }
}


/**
 * @brief Clears all the system computer marker hilights.
 */
void space_clearComputerMarkerHilights(void)
{
   int i;

   for (i=0; i<array_size(systems_stack); i++) {
      sys_rmFlag(&systems_stack[i], SYSTEM_CMARK_HILIGHT);
   }
}


/**
 * @brief Adds a marker to a system.
 *
 *    @param sys ID of the system to add marker to.
 *    @param type Type of the marker to add.
 *    @return 0 on success.
 */
int space_addMarker( int sys, SysMarker type )
{
   StarSystem *ssys;

   /* Get the system. */
   ssys = system_getIndex(sys);
   if (ssys == NULL)
      return -1;

   /* Get the marker. */
   switch (type) {
      case SYSMARKER_COMPUTER:
         ssys->markers_computer++;
         sys_setFlag(ssys, SYSTEM_MARKED);
         break;
      case SYSMARKER_LOW:
         ssys->markers_low++;
         sys_setFlag(ssys, SYSTEM_MARKED);
         break;
      case SYSMARKER_HIGH:
         ssys->markers_high++;
         sys_setFlag(ssys, SYSTEM_MARKED);
         break;
      case SYSMARKER_PLOT:
         ssys->markers_plot++;
         sys_setFlag(ssys, SYSTEM_MARKED);
         break;
      case SYSMARKER_NEW:
         ssys->markers_new++;
         sys_setFlag(ssys, SYSTEM_CMARKED);
         break;
      default:
         WARN(_("Unknown marker type."));
         return -1;
   }

   return 0;
}


/**
 * @brief Removes a marker from a system.
 *
 *    @param sys ID of the system to remove marker from.
 *    @param type Type of the marker to remove.
 *    @return 0 on success.
 */
int space_rmMarker( int sys, SysMarker type )
{
   StarSystem *ssys;

   /* Get the system. */
   ssys = system_getIndex(sys);
   if (ssys == NULL)
      return -1;

   /* Get the marker. */
   switch (type) {
      case SYSMARKER_COMPUTER:
         ssys->markers_computer--;
         ssys->markers_computer = MAX(0, ssys->markers_computer);
         break;
      case SYSMARKER_LOW:
         ssys->markers_low--;
         ssys->markers_low = MAX(0, ssys->markers_low);
         break;
      case SYSMARKER_HIGH:
         ssys->markers_high--;
         ssys->markers_high = MAX(0, ssys->markers_high);
         break;
      case SYSMARKER_PLOT:
         ssys->markers_plot--;
         ssys->markers_plot = MAX(0, ssys->markers_plot);
         break;
      case SYSMARKER_NEW:
         ssys->markers_new--;
         ssys->markers_new = MAX(0, ssys->markers_new);
         break;
      default:
         WARN(_("Unknown marker type."));
         return -1;
   }

   /* If all markers are gone, remove marked flag. */
   if ((ssys->markers_computer <= 0) && (ssys->markers_low <= 0)
         && (ssys->markers_high <= 0) && (ssys->markers_plot <= 0))
      sys_rmFlag(ssys, SYSTEM_MARKED);

   /* New markers are separate. */
   if (ssys->markers_new <= 0)
      sys_rmFlag(ssys, SYSTEM_CMARKED);

   return 0;
}


/**
 * @brief Saves what is needed to be saved for space.
 *
 *    @param writer XML writer to use.
 *    @return 0 on success.
 */
int space_sysSave( xmlTextWriterPtr writer )
{
  int i,j;
   StarSystem *sys;

   xmlw_startElem(writer,"space");

   for (i=0; i<array_size(systems_stack); i++) {

      if (!sys_isKnown(&systems_stack[i])) continue; /* not known */

      xmlw_startElem(writer,"known");

      xmlw_attr(writer,"sys","%s",systems_stack[i].name);

      sys = &systems_stack[i];

      for (j=0; j<array_size(sys->planets); j++) {
         if (!planet_isKnown(sys->planets[j])) continue; /* not known */
         xmlw_elem(writer, "planet", "%s", sys->planets[j]->name);
      }

      for (j=0; j<array_size(sys->jumps); j++) {
         if (!jp_isKnown(&sys->jumps[j])) continue; /* not known */
         xmlw_elem(writer,"jump","%s",(&sys->jumps[j])->target->name);
      }

      xmlw_endElem(writer);
   }

   xmlw_endElem(writer); /* "space" */

   return 0;
}


/**
 * @brief Loads player's space properties from an XML node.
 *
 *    @param parent Parent node for space.
 *    @return 0 on success.
 */
int space_sysLoad( xmlNodePtr parent )
{
   xmlNodePtr node, cur;
   StarSystem *sys;
   char *str;

   space_clearKnown();

   node = parent->xmlChildrenNode;
   do {
      if (xml_isNode(node,"space")) {
         cur = node->xmlChildrenNode;

         do {
            if (xml_isNode(cur,"known")) {
               xmlr_attr_strd(cur,"sys",str);
               if (str != NULL) { /* check for 5.0 saves */
                  sys = system_get(str);
                  free(str);
               }
               else /* load from 5.0 saves */
                  sys = system_get(xml_get(cur));
               if (sys != NULL) { /* Must exist */
                  sys_setFlag(sys,SYSTEM_KNOWN);
                  space_parseAssets(cur, sys);
               }
            }
         } while (xml_nextNode(cur));
      }
   } while (xml_nextNode(node));

   return 0;
}

/**
 * @brief Parses assets in a system.
 *
 *    @param parent Node of the system.
 *    @param sys System to populate.
 *    @return 0 on success.
 */
static int space_parseAssets( xmlNodePtr parent, StarSystem* sys )
{
   xmlNodePtr node;
   Planet *planet;
   JumpPoint *jp;

   node = parent->xmlChildrenNode;

   do {
      if (xml_isNode(node,"planet")) {
         planet = planet_get(xml_get(node));
         if (planet != NULL) /* Must exist */
            planet_setKnown(planet);
      }
      else if (xml_isNode(node,"jump")) {
         jp = jump_get(xml_get(node), sys);
         if (jp != NULL) /* Must exist */
            jp_setFlag(jp,JP_KNOWN);
      }
   } while (xml_nextNode(node));

   return 0;
}

/**
 * @brief Gets the index of the presence element for a faction.
 *          Creates one if it doesn't exist.
 *
 *    @param sys Pointer to the system to check.
 *    @param faction The index of the faction to search for.
 *    @return The index of the presence array for faction.
 */
static int getPresenceIndex(StarSystem *sys, factionId_t faction)
{
   int i;

   /* Check for NULL and display a warning. */
   if (sys == NULL) {
      WARN("sys == NULL");
      return 0;
   }

   /* Go through the array (if created), looking for the faction. */
   for (i = 0; i < array_size(sys->presence); i++)
      if (sys->presence[i].faction == faction)
         return i;

   /* Grow the array. */
   i = array_size(sys->presence);
   memset(&array_grow(&sys->presence), 0, sizeof(SystemPresence));
   sys->presence[i].faction = faction;

   return i;
}


/**
 * @brief Adds (or removes) some presence to a system.
 *
 *    @param sys Pointer to the system to add to or remove from.
 *    @param faction The index of the faction to alter presence for.
 *    @param amount The amount of presence to add (negative to subtract).
 *    @param range The range of spill of the presence.
 */
void system_addPresence(StarSystem *sys, factionId_t faction, double amount,
      int range)
{
   int i, x, curSpill;
   Queue q, qn;
   StarSystem *cur;

   /* Check for NULL and display a warning. */
   if (sys == NULL) {
      WARN("%s", _("Attempted to add presence to NULL system."));
      return;
   }

   /* Check that we have a valid faction. */
   if (!faction_isFaction(faction))
      return;

   /* Check that we're actually adding any. */
   if (amount == 0)
      return;

   /* Add the presence to the current system. */
   i = getPresenceIndex(sys, faction);
   sys->presence[i].value += amount;

   /* If there's no range, we're done here. */
   if (range < 1)
      return;

   /* Add the spill. */
   sys->spilled   = 1;
   curSpill       = 0;
   q              = q_create();
   qn             = q_create();

   /* Create the initial queue consisting of sys adjacencies. */
   for (i=0; i < array_size(sys->jumps); i++) {
      if (sys->jumps[i].target->spilled == 0 && !jp_isFlag( &sys->jumps[i], JP_HIDDEN ) && !jp_isFlag( &sys->jumps[i], JP_EXITONLY )) {
         q_enqueue( q, sys->jumps[i].target );
         sys->jumps[i].target->spilled = 1;
      }
   }

   /* If it's empty, something's wrong. */
   if (q_isEmpty(q)) {
      /* Means system isn't connected. */
      /*WARN(_("q is empty after getting adjacencies of %s."), sys->name);*/
      q_destroy(q);
      q_destroy(qn);
      goto sys_cleanup;
      return;
   }

   while (curSpill < range) {
      /* Pull one off the current range queue. */
      cur = q_dequeue(q);

      /* Ran out of candidates before running out of spill range! */
      if (cur == NULL)
         break;

      /* Enqueue all its adjacencies to the next range queue. */
      for (i=0; i<array_size(cur->jumps); i++) {
         if (cur->jumps[i].target->spilled == 0 && !jp_isFlag( &cur->jumps[i], JP_HIDDEN ) && !jp_isFlag( &cur->jumps[i], JP_EXITONLY )) {
            q_enqueue( qn, cur->jumps[i].target );
            cur->jumps[i].target->spilled = 1;
         }
      }

      /* Spill some presence. */
      x = getPresenceIndex(cur, faction);
      cur->presence[x].value += amount / (2 + curSpill);

      /* Check to see if we've finished this range and grab the next queue. */
      if (q_isEmpty(q)) {
         curSpill++;
         q_destroy(q);
         q  = qn;
         qn = q_create();
      }
   }

   /* Destroy the queues. */
   q_destroy(q);
   q_destroy(qn);

sys_cleanup:
   /* Clean up our mess. */
   for (i=0; i < array_size(systems_stack); i++)
      systems_stack[i].spilled = 0;
   return;
}


/**
 * @brief Get the presence of a faction in a system.
 *
 *    @param sys Pointer to the system to process.
 *    @param faction The faction to get the presence for.
 *    @return The amount of presence the faction has in the system.
 */
double system_getPresence(const StarSystem *sys, factionId_t faction)
{
   int i;

   /* Check for NULL and display a warning. */
   if (sys == NULL) {
      WARN("sys == NULL");
      return 0;
   }

   /* Go through the array, looking for the faction. */
   for (i = 0; i < array_size(sys->presence); i++) {
      if (sys->presence[i].faction == faction)
         return MAX(sys->presence[i].value, 0);
   }

   /* If it's not in there, it's zero. */
   return 0;
}


/**
 * @brief Go through all the assets and call system_addPresence().
 *
 *    @param sys Pointer to the system to process.
 */
void system_addAllPlanetsPresence( StarSystem *sys )
{
   int i;

   /* Check for NULL and display a warning. */
   if (sys == NULL) {
      WARN("sys == NULL");
      return;
   }

   for (i=0; i<array_size(sys->planets); i++)
      system_addPresence(sys, sys->planets[i]->faction, sys->planets[i]->presenceAmount, sys->planets[i]->presenceRange);
}


/**
 * @brief Reset the presence of all systems.
 */
void space_reconstructPresences( void )
{
   int i;

   /* Reset the presence in each system. */
   for (i=0; i<array_size(systems_stack); i++) {
      array_free(systems_stack[i].presence);
      systems_stack[i].presence  = array_create( SystemPresence );
      systems_stack[i].ownerpresence = 0.;
   }

   /* Re-add presence to each system. */
   for (i=0; i<array_size(systems_stack); i++)
      system_addAllPlanetsPresence(&systems_stack[i]);

   /* Determine dominant faction. */
   for (i=0; i<array_size(systems_stack); i++) {
      system_setFaction( &systems_stack[i] );
      systems_stack[i].ownerpresence = system_getPresence( &systems_stack[i], systems_stack[i].faction );
   }

   /* Have to redo the scheduler because everything changed. */
   /* TODO this actually ignores existing presence and will temporarily increase system presence more than normal... */
   if (cur_system != NULL)
      system_scheduler( 0., 1 );
}


/**
 * @brief See if the position is in an asteroid field.
 *
 *    @param p pointer to the position.
 *    @return -1 If false; index of the field otherwise.
 */
int space_isInField( const Vector2d *p )
{
   int i;
   AsteroidAnchor *a;
   AsteroidExclusion *e;

   /* Always return -1 if in an exclusion zone */
   for (i=0; i < array_size(cur_system->astexclude); i++) {
      e = &cur_system->astexclude[i];
      if (vect_dist( p, &e->pos ) <= e->radius)
         return -1;
   }

   /* Check if in asteroid field */
   for (i=0; i < array_size(cur_system->asteroids); i++) {
      a = &cur_system->asteroids[i];
      if (vect_dist( p, &a->pos ) <= a->radius)
         return i;
   }

   return -1;
}


/**
 * @brief Returns the asteroid type corresponding to an ID
 *
 *    @param ID ID of the type.
 *    @return AsteroidType object.
 */
AsteroidType *space_getType ( int ID )
{
   return &asteroid_types[ ID ];
}


/**
 * @brief Hits an asteroid.
 *
 *    @param a hit asteroid
 *    @param dmg Damage being done
 */
void asteroid_hit( Asteroid *a, const Damage *dmg )
{
   double darmour;
   /* TODO: Add knockback effect to asteroids. */
   dtype_calcDamage(NULL, &darmour, NULL, NULL, 1., dmg, NULL);

   a->armour -= darmour;
   if (a->armour <= 0)
   {
      a->appearing = ASTEROID_EXPLODING;
      a->timer = 0.;
   }
}


/**
 * @brief Makes an asteroid explode.
 *
 *    @param a asteroid to make explode
 *    @param field Asteroid field the asteroid belongs to.
 *    @param give_reward Whether a pilot blew the asteroid up and should be rewarded.
 */
static void asteroid_explode ( Asteroid *a, AsteroidAnchor *field, int give_reward )
{
   int i, j, nb;
   Damage dmg;
   AsteroidType *at;
   Commodity *com;
   Vector2d pos, vel;
   char buf[16];

   /* Manage the explosion */
   dmg.type = dtype_get("explosion_splash");
   dmg.penetration = 1.; /* Full penetration. */
   dmg.damage = 100.;
   dmg.disable = 0.;
   dtype_raw(dmg.type, &dmg.shield_pct, &dmg.armor_pct, &dmg.knockback_pct,
         &dmg.recoil_pct);
   expl_explode(a->pos.x, a->pos.y, a->vel.x, a->vel.y,
         50., &dmg, NULL, EXPL_MODE_SHIP);

   /* Play random explosion sound. */
   snprintf(buf, sizeof(buf), "explosion%d", RNG(0,2));
   sound_playPos( sound_get(buf), a->pos.x, a->pos.y, a->vel.x, a->vel.y );

   if ( give_reward ) {
      /* Release commodity. */
      at = &asteroid_types[a->type];

      for (i=0; i < array_size(at->material); i++) {
         nb = RNG(0,at->quantity[i]);
         com = at->material[i];
         for (j=0; j < nb; j++) {
            pos = a->pos;
            vel = a->vel;
            pos.x += (RNGF()*30.-15.);
            pos.y += (RNGF()*30.-15.);
            vel.x += (RNGF()*20.-10.);
            vel.y += (RNGF()*20.-10.);
            gatherable_init( com, pos, vel, -1., RNG(1,5) );
         }
      }
   }

   /* Remove the asteroid target to any pilot. */
   pilot_untargetAsteroid( a->parent, a->id );

   /* Make it respawn elsewhere */
   asteroid_init( a, field );
}


/**
 * @brief See if the system has a planet or station.
 *
 *    @param sys Pointer to the system to process.
 *    @return 0 If empty; otherwise 1.
 */
int system_hasPlanet( const StarSystem *sys )
{
   int i;

   /* Check for NULL and display a warning. */
   if (sys == NULL) {
      WARN("sys == NULL");
      return 0;
   }

   /* Go through all the assets and look for a real one. */
   for (i = 0; i < array_size(sys->planets); i++)
      if (sys->planets[i]->real == ASSET_REAL)
         return 1;

   return 0;
}


/**
 * @brief Removes active presence.
 */
void system_rmCurrentPresence(StarSystem *sys, factionId_t faction,
      double amount)
{
   int id;
   nlua_env env;
   SystemPresence *presence;

   /* Remove the presence. */
   id = getPresenceIndex( cur_system, faction );
   sys->presence[id].curUsed -= amount;

   /* Safety. */
   presence = &sys->presence[id];
   presence->curUsed = MAX( 0, sys->presence[id].curUsed );

   /* Run lower hook. */
   env = faction_getScheduler( faction );

   /* Run decrease function if applicable. */
   nlua_getenv( env, "decrease" ); /* f */
   if (lua_isnil(naevL,-1)) {
      lua_pop(naevL,1);
      return;
   }
   lua_pushnumber( naevL, presence->curUsed ); /* f, cur */
   lua_pushnumber( naevL, presence->value );   /* f, cur, max */
   lua_pushnumber( naevL, presence->timer );   /* f, cur, max, timer */

   /* Actually run the function. */
   if (nlua_pcall(env, 3, 1)) { /* error has occurred */
      WARN(_("Lua decrease script for faction '%s' : %s"),
            faction_name( faction ), lua_tostring(naevL,-1));
      lua_pop(naevL,1);
      return;
   }

   /* Output is handled the same way. */
   if (!lua_isnumber(naevL,-1)) {
      WARN(_("Lua spawn script for faction '%s' failed to return timer value."),
            faction_name( presence->faction ) );
      lua_pop(naevL,1);
      return;
   }
   presence->timer = lua_tonumber(naevL,-1);
   lua_pop(naevL,1);
}


void space_queueLand( Planet *pnt )
{
   space_landQueuePlanet = pnt;
}
