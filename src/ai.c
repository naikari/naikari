/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file ai.c
 *
 * @brief Controls the Pilot AI.
 *
 * @luamod ai
 *
 * AI Overview
 *
 * Concept: Goal (Task) Based AI with additional Optimization
 *
 *  AI uses the goal (task) based AI approach with tasks scripted in Lua,
 * additionally there is a task that is hard-coded and obligatory in any AI
 * script, the 'control' task, whose sole purpose is to assign tasks if there
 * is no current tasks and optimizes or changes tasks if there are.
 *
 *  For example: Pilot A is attacking Pilot B.  Say that Pilot C then comes in
 * the same system and is of the same faction as Pilot B, and therefore attacks
 * Pilot A.  Pilot A would keep on fighting Pilot B until the control task
 * kicks in.  Then he/she could run if it deems that Pilot C and Pilot B
 * together are too strong for him/her, or attack Pilot C because it's an
 * easier target to finish off then Pilot B.  Therefore there are endless
 * possibilities and it's up to the AI coder to set up.
 *
 *
 * Specification
 *
 *   -  AI will follow basic tasks defined from Lua AI script.
 *     - if Task is NULL, AI will run "control" task
 *     - Task is continued every frame
 *     - Tasks can have subtasks which will be closed when parent task is dead.
 *     -  "control" task is a special task that MUST exist in any given  Pilot AI
 *        (missiles and such will use "seek")
 *     - "control" task is not permanent, but transitory
 *     - "control" task sets another task
 *   - "control" task is also run at a set rate (depending on Lua global "control_rate")
 *     to choose optimal behaviour (task)
 *
 * Memory
 *
 *  The AI currently has per-pilot memory which is accessible as "mem".  This
 * memory is actually stored in the table pilotmem[cur_pilot->id].  This allows
 * the pilot to keep some memory always accessible between runs without having
 * to rely on the storage space a task has.
 *
 * Garbage Collector
 *
 *  The tasks are not deleted directly but are marked for deletion and are then
 * cleaned up in a garbage collector. This is to avoid accessing invalid task
 * memory.
 *
 * @note Nothing in this file can be considered reentrant.  Plan accordingly.
 *
 * @todo Clean up most of the code, it was written as one of the first
 *         subsystems and is pretty lacking in quite a few aspects.
 */


/** @cond */
#include <ctype.h>
#include <lauxlib.h>
#include <lualib.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "physfs.h"

#include "naev.h"
/** @endcond */

#include "ai.h"

#include "array.h"
#include "board.h"
#include "escort.h"
#include "faction.h"
#include "hook.h"
#include "log.h"
#include "ndata.h"
#include "nlua.h"
#include "nlua_faction.h"
#include "nlua_pilot.h"
#include "nlua_planet.h"
#include "nlua_rnd.h"
#include "nlua_vec2.h"
#include "nluadef.h"
#include "nstring.h"
#include "physics.h"
#include "pilot.h"
#include "player.h"
#include "rng.h"
#include "space.h"


/*
 * ai flags
 *
 * They can be used for stuff like movement or for pieces of code which might
 *  run AI stuff when the AI module is not reentrant.
 */
#define ai_setFlag(f)   (pilot_flags |= f ) /**< Sets pilot flag f */
#define ai_isFlag(f)    (pilot_flags & f ) /**< Checks pilot flag f */
/* flags */
#define AI_PRIMARY      (1<<0)   /**< Firing primary weapon */
#define AI_SECONDARY    (1<<1)   /**< Firing secondary weapon */
#define AI_DISTRESS     (1<<2)   /**< Sent distress signal. */


/*
 * file info
 */
#define AI_SUFFIX       ".lua" /**< AI file suffix. */
#define AI_MEM_DEF      "def" /**< Default pilot memory. */


/*
 * all the AI profiles
 */
static AI_Profile* profiles = NULL; /**< Array of AI_Profiles loaded. */
static nlua_env equip_env = LUA_NOREF; /**< Equipment enviornment. */


/*
 * prototypes
 */
/* Internal C routines */
static void ai_run( nlua_env env, int nargs );
static int ai_loadProfile( const char* filename );
static void ai_setMemory (void);
static void ai_create( Pilot* pilot );
static int ai_loadEquip (void);
/* Task management. */
static void ai_taskGC( Pilot* pilot );
static Task* ai_createTask( lua_State *L, int subtask );
static int ai_tasktarget( lua_State *L, Task *t );



/*
 * AI routines for Lua
 */
/* tasks */
static int aiL_pushtask( lua_State *L ); /* pushtask( string, number/pointer ) */
static int aiL_poptask( lua_State *L ); /* poptask() */
static int aiL_taskname( lua_State *L ); /* string taskname() */
static int aiL_taskdata( lua_State *L ); /* pointer subtaskdata() */
static int aiL_pushsubtask( lua_State *L ); /* pushsubtask( string, number/pointer, number ) */
static int aiL_popsubtask( lua_State *L ); /* popsubtask() */
static int aiL_subtaskname( lua_State *L ); /* string subtaskname() */
static int aiL_subtaskdata( lua_State *L ); /* pointer subtaskdata() */

/* consult values */
static int aiL_pilot( lua_State *L ); /* number pilot() */
static int aiL_getrndpilot( lua_State *L ); /* number getrndpilot() */
static int aiL_getnearestpilot( lua_State *L ); /* number getnearestpilot() */
static int aiL_getdistance( lua_State *L ); /* number getdist(Vector2d) */
static int aiL_getflybydistance( lua_State *L ); /* number getflybydist(Vector2d) */
static int aiL_minbrakedist( lua_State *L ); /* number minbrakedist( [number] ) */
static int aiL_isbribed( lua_State *L ); /* bool isbribed( number ) */
static int aiL_getstanding( lua_State *L ); /* number getstanding( number ) */
static int aiL_getGatherable( lua_State *L ); /* integer getgatherable( radius ) */
static int aiL_instantJump( lua_State *L ); /* bool instantJump() */

/* boolean expressions */
static int aiL_ismaxvel( lua_State *L ); /* boolean ismaxvel() */
static int aiL_isstopped( lua_State *L ); /* boolean isstopped() */
static int aiL_isenemy( lua_State *L ); /* boolean isenemy( number ) */
static int aiL_isally( lua_State *L ); /* boolean isally( number ) */
static int aiL_haslockon( lua_State *L ); /* boolean haslockon() */
static int aiL_hasprojectile( lua_State *L ); /* boolean hasprojectile() */

/* movement */
static int aiL_accel( lua_State *L ); /* accel(number); number <= 1. */
static int aiL_turn( lua_State *L ); /* turn(number); abs(number) <= 1. */
static int aiL_rotate(lua_State *L);
static int aiL_face( lua_State *L ); /* face( number/pointer, bool) */
static int aiL_careful_face( lua_State *L ); /* face( number/pointer, bool) */
static int aiL_aim( lua_State *L ); /* aim(number) */
static int aiL_iface( lua_State *L ); /* iface(number/pointer) */
static int aiL_dir( lua_State *L ); /* dir(number/pointer) */
static int aiL_idir( lua_State *L ); /* idir(number/pointer) */
static int aiL_drift_facing( lua_State *L ); /* drift_facing(number/pointer) */
static int aiL_brake( lua_State *L ); /* brake() */
static int aiL_getnearestplanet( lua_State *L ); /* Vec2 getnearestplanet() */
static int aiL_getplanetfrompos( lua_State *L ); /* Vec2 getplanetfrompos() */
static int aiL_getrndplanet( lua_State *L ); /* Vec2 getrndplanet() */
static int aiL_getlandplanet( lua_State *L ); /* Vec2 getlandplanet() */
static int aiL_canLand(lua_State *L);
static int aiL_land( lua_State *L ); /* bool land() */
static int aiL_stop( lua_State *L ); /* stop() */
static int aiL_relvel( lua_State *L ); /* relvel( number ) */
static int aiL_follow_accurate( lua_State *L ); /* follow_accurate() */
static int aiL_face_accurate( lua_State *L ); /* face_accurate() */

/* Hyperspace. */
static int aiL_sethyptarget( lua_State *L );
static int aiL_nearhyptarget( lua_State *L ); /* pointer rndhyptarget() */
static int aiL_rndhyptarget( lua_State *L ); /* pointer rndhyptarget() */
static int aiL_hyperspace( lua_State *L ); /* [number] hyperspace() */
static int aiL_localjump(lua_State *L);

/* escorts */
static int aiL_dock( lua_State *L ); /* dock( number ) */

/* combat */
static int aiL_combat( lua_State *L ); /* combat( number ) */
static int aiL_settarget( lua_State *L ); /* settarget( number ) */
static int aiL_weapSet( lua_State *L ); /* weapset( number ) */
static int aiL_shoot( lua_State *L ); /* shoot( number ); number = 1,2,3 */
static int aiL_hascannons( lua_State *L ); /* bool hascannons() */
static int aiL_hasturrets( lua_State *L ); /* bool hasturrets() */
static int aiL_hasafterburner( lua_State *L ); /* bool hasafterburner() */
static int aiL_getenemy( lua_State *L ); /* number getenemy() */
static int aiL_getenemy_size( lua_State *L ); /* number getenemy_size() */
static int aiL_getenemy_heuristic( lua_State *L ); /* number getenemy_heuristic() */
static int aiL_hostile( lua_State *L ); /* hostile( number ) */
static int aiL_getweaprange( lua_State *L ); /* number getweaprange() */
static int aiL_getweapspeed( lua_State *L ); /* number getweapspeed() */
static int aiL_getweapammo( lua_State *L );
static int aiL_canboard( lua_State *L ); /* boolean canboard( number ) */
static int aiL_relsize( lua_State *L ); /* boolean relsize( number ) */
static int aiL_reldps( lua_State *L ); /* boolean reldps( number ) */
static int aiL_relhp( lua_State *L ); /* boolean relhp( number ) */

/* timers */
static int aiL_settimer( lua_State *L ); /* settimer( number, number ) */
static int aiL_timeup( lua_State *L ); /* boolean timeup( number ) */

/* messages */
static int aiL_distress( lua_State *L ); /* distress( string [, bool] ) */
static int aiL_getBoss( lua_State *L ); /* number getBoss() */

/* loot */
static int aiL_credits( lua_State *L ); /* credits( number ) */

/* misc */
static int aiL_board( lua_State *L ); /* boolean board() */
static int aiL_refuel( lua_State *L ); /* boolean, boolean refuel() */
static int aiL_messages( lua_State *L );
static int aiL_setasterotarget( lua_State *L ); /* setasterotarget( number, number ) */
static int aiL_gatherablePos( lua_State *L ); /* gatherablepos( number ) */
static int aiL_shoot_indicator( lua_State *L ); /* get shoot indicator */
static int aiL_set_shoot_indicator( lua_State *L ); /* set shoot indicator */


static const luaL_Reg aiL_methods[] = {
   /* tasks */
   { "pushtask", aiL_pushtask },
   { "poptask", aiL_poptask },
   { "taskname", aiL_taskname },
   { "taskdata", aiL_taskdata },
   { "pushsubtask", aiL_pushsubtask },
   { "popsubtask", aiL_popsubtask },
   { "subtaskname", aiL_subtaskname },
   { "subtaskdata", aiL_subtaskdata },
   /* is */
   { "ismaxvel", aiL_ismaxvel },
   { "isstopped", aiL_isstopped },
   { "isenemy", aiL_isenemy },
   { "isally", aiL_isally },
   { "haslockon", aiL_haslockon },
   { "hasprojectile", aiL_hasprojectile },
   /* get */
   { "pilot", aiL_pilot },
   { "rndpilot", aiL_getrndpilot },
   { "nearestpilot", aiL_getnearestpilot },
   { "dist", aiL_getdistance },
   { "flyby_dist", aiL_getflybydistance },
   { "minbrakedist", aiL_minbrakedist },
   { "isbribed", aiL_isbribed },
   { "getstanding", aiL_getstanding },
   { "getgatherable", aiL_getGatherable },
   { "instantJump", aiL_instantJump },
   /* movement */
   {"nearestplanet", aiL_getnearestplanet},
   {"planetfrompos", aiL_getplanetfrompos},
   {"rndplanet", aiL_getrndplanet},
   {"landplanet", aiL_getlandplanet},
   {"canLand", aiL_canLand},
   {"land", aiL_land},
   {"accel", aiL_accel},
   {"turn", aiL_turn},
   {"rotate", aiL_rotate},
   {"face", aiL_face},
   {"careful_face", aiL_careful_face},
   {"iface", aiL_iface},
   {"dir", aiL_dir},
   {"idir", aiL_idir},
   {"drift_facing", aiL_drift_facing},
   {"brake", aiL_brake},
   {"stop", aiL_stop},
   {"relvel", aiL_relvel},
   {"follow_accurate", aiL_follow_accurate},
   {"face_accurate", aiL_face_accurate},
   /* Hyperspace. */
   {"sethyptarget", aiL_sethyptarget},
   {"nearhyptarget", aiL_nearhyptarget},
   {"rndhyptarget", aiL_rndhyptarget},
   {"hyperspace", aiL_hyperspace},
   {"localjump", aiL_localjump},
   {"dock", aiL_dock},
   /* combat */
   { "aim", aiL_aim },
   { "combat", aiL_combat },
   { "settarget", aiL_settarget },
   { "weapset", aiL_weapSet },
   { "hascannons", aiL_hascannons },
   { "hasturrets", aiL_hasturrets },
   { "hasafterburner", aiL_hasafterburner },
   { "shoot", aiL_shoot },
   { "getenemy", aiL_getenemy },
   { "getenemy_size", aiL_getenemy_size },
   { "getenemy_heuristic", aiL_getenemy_heuristic },
   { "hostile", aiL_hostile },
   { "getweaprange", aiL_getweaprange },
   { "getweapspeed", aiL_getweapspeed },
   { "getweapammo", aiL_getweapammo },
   { "canboard", aiL_canboard },
   { "relsize", aiL_relsize },
   { "reldps", aiL_reldps },
   { "relhp", aiL_relhp },
   /* timers */
   { "settimer", aiL_settimer },
   { "timeup", aiL_timeup },
   /* messages */
   { "distress", aiL_distress },
   { "getBoss", aiL_getBoss },
   /* loot */
   { "setcredits", aiL_credits },
   /* misc */
   { "board", aiL_board },
   { "refuel", aiL_refuel },
   { "messages", aiL_messages },
   { "setasterotarget", aiL_setasterotarget },
   { "gatherablepos", aiL_gatherablePos },
   { "shoot_indicator", aiL_shoot_indicator },
   { "set_shoot_indicator", aiL_set_shoot_indicator },
   {0,0} /* end */
}; /**< Lua AI Function table. */



/*
 * current pilot "thinking" and assorted variables
 */
Pilot *cur_pilot           = NULL; /**< Current pilot.  All functions use this. */
static int pilot_flags     = 0; /**< Handle stuff like weapon firing. */
static char aiL_distressmsg[PATH_MAX]; /**< Buffer to store distress message. */

/*
 * ai status, used so that create functions can't be used elsewhere
 */
#define AI_STATUS_NORMAL      1 /**< Normal AI function behaviour. */
#define AI_STATUS_CREATE      2 /**< AI is running create function. */
static int aiL_status = AI_STATUS_NORMAL; /**< Current AI run status. */


/**
 * @brief Runs the garbage collector on the pilot's tasks.
 *
 *    @param pilot Pilot to clean up.
 */
static void ai_taskGC( Pilot* pilot )
{
   Task *t, *prev, *pointer;

   prev  = NULL;
   t     = pilot->task;
   while (t != NULL) {
      if (t->done) {
         pointer = t;
         /* Unattach pointer. */
         t       = t->next;
         if (prev == NULL)
            pilot->task = t;
         else
            prev->next  = t;
         /* Free pointer. */
         pointer->next = NULL;
         ai_freetask( pointer );
      }
      else {
         prev    = t;
         t       = t->next;
      }
   }
}


/**
 * @brief Gets the current running task.
 */
Task* ai_curTask( Pilot* pilot )
{
   Task *t;
   /* Get last task. */
   for (t=pilot->task; t!=NULL; t=t->next)
      if (!t->done)
         return t;
   return NULL;
}


/**
 * @brief Sets the cur_pilot's ai.
 */
static void ai_setMemory (void)
{
   nlua_env env;
   env = cur_pilot->ai->env;

   nlua_getenv(env, AI_MEM); /* pm */
   lua_rawgeti(naevL, -1, cur_pilot->id); /* pm, t */
   nlua_setenv(env, "mem"); /* pm */
   lua_pop(naevL, 1); /* */
}


/**
 * @brief Sets the pilot for further AI calls.
 *
 *    @param p Pilot to set.
 */
void ai_setPilot( Pilot *p )
{
   cur_pilot = p;
   ai_setMemory();
}


/**
 * @brief Attempts to run a function.
 *
 *    @param[in] env Lua env to run function in.
 *    @param[in] nargs Number of arguments to run.
 */
static void ai_run( nlua_env env, int nargs )
{
   if (nlua_pcall(env, nargs, 0)) { /* error has occurred */
      WARN( _("Pilot '%s' ai error: %s"), cur_pilot->name, lua_tostring(naevL,-1));
      lua_pop(naevL,1);
   }
}


/**
 * @brief Initializes the pilot in the ai.
 *
 * Mainly used to create the pilot's memory table.
 *
 *    @param p Pilot to initialize in AI.
 *    @param ai AI to initialize pilot.
 *    @return 0 on success.
 */
int ai_pinit( Pilot *p, const char *ai )
{
   AI_Profile *prof;
   char buf[PATH_MAX];

   strncpy(buf, ai, sizeof(buf)-1);
   buf[sizeof(buf)-1] = '\0';

   /* Set up the profile. */
   prof = ai_getProfile(buf);
   if (prof == NULL) {
      WARN( _("AI Profile '%s' not found, using dummy fallback."), buf);
      snprintf(buf, sizeof(buf), "dummy" );
      prof = ai_getProfile(buf);
   }
   p->ai = prof;

   /* Adds a new pilot memory in the memory table. */
   nlua_getenv(p->ai->env, AI_MEM);  /* pm */
   lua_newtable(naevL);              /* pm, nt */
   lua_pushvalue(naevL, -1);         /* pm, nt, nt */
   lua_rawseti(naevL, -3, p->id);    /* pm, nt */

   /* Copy defaults over from the global memory table. */
   lua_pushstring(naevL, AI_MEM_DEF);/* pm, nt, s */
   lua_gettable(naevL, -3);          /* pm, nt, dt */
#if DEBUGGING
   if (lua_isnil(naevL,-1))
      WARN( _("AI profile '%s' has no default memory for pilot '%s'."),
            buf, p->name );
#endif
   lua_pushnil(naevL);               /* pm, nt, dt, nil */
   while (lua_next(naevL,-2) != 0) { /* pm, nt, dt, k, v */
      lua_pushvalue(naevL,-2);       /* pm, nt, dt, k, v, k */
      lua_pushvalue(naevL,-2);       /* pm, nt, dt, k, v, k, v */
      lua_remove(naevL, -3);         /* pm, nt, dt, k, k, v */
      lua_settable(naevL,-5);        /* pm, nt, dt, k */
   }                             /* pm, nt, dt */
   lua_pop(naevL,3);                 /* */

   /* Create the pilot. */
   ai_create(p);
   pilot_setFlag(p, PILOT_CREATED_AI);

   return 0;
}


/**
 * @brief Clears the pilot's tasks.
 *
 *    @param p Pilot to clear tasks of.
 */
void ai_cleartasks( Pilot* p )
{
   /* Clean up tasks. */
   if (p->task)
      ai_freetask( p->task );
   p->task = NULL;
}


/**
 * @brief Destroys the ai part of the pilot
 *
 *    @param[in] p Pilot to destroy its AI part.
 */
void ai_destroy( Pilot* p )
{
   nlua_env env;
   env = p->ai->env;

   /* Get rid of pilot's memory. */
   if (!pilot_isPlayer(p)) { /* Player is an exception as more than one ship shares pilot id. */
      nlua_getenv(env, AI_MEM);  /* t */
      lua_pushnil(naevL);        /* t, nil */
      lua_rawseti(naevL,-2, p->id);/* t */
      lua_pop(naevL, 1);         /* */
   }

   /* Clear the tasks. */
   ai_cleartasks( p );
}


/**
 * @brief Initializes the AI stuff which is basically Lua.
 *
 *    @return 0 on no errors.
 */
int ai_load (void)
{
   char** files;
   size_t i;
   char path[PATH_MAX];
   int flen, suflen;

   /* get the file list */
   files = PHYSFS_enumerateFiles( AI_PATH );

   /* Create array. */
   profiles = array_create( AI_Profile );

   /* load the profiles */
   suflen = strlen(AI_SUFFIX);
   for (i=0; files[i]!=NULL; i++) {
      if (naev_pollQuit())
         break;

      flen = strlen(files[i]);
      if ((flen > suflen) &&
            strncmp(&files[i][flen-suflen], AI_SUFFIX, suflen)==0) {

         snprintf( path, sizeof(path), AI_PATH"%s", files[i] );
         if (ai_loadProfile(path)) /* Load the profile */
            WARN( _("Error loading AI profile '%s'"), path);
      }
   }

   DEBUG( n_("Loaded %d AI Profile", "Loaded %d AI Profiles", array_size(profiles) ), array_size(profiles) );

   /* More clean up. */
   PHYSFS_freeList( files );

   /* Load equipment thingy. */
   return ai_loadEquip();
}


/**
 * @brief Loads the equipment selector script.
 */
static int ai_loadEquip (void)
{
   char *buf;
   size_t bufsize;
   const char *filename = AI_EQUIP_PATH;

   /* Make sure doesn't already exist. */
   if (equip_env != LUA_NOREF)
      nlua_freeEnv(equip_env);

   /* Create new state. */
   equip_env = nlua_newEnv(1);
   nlua_loadStandard(equip_env);

   /* Load the file. */
   buf = ndata_read( filename, &bufsize );
   if (nlua_dobufenv(equip_env, buf, bufsize, filename) != 0) {
      WARN( _("Error loading file: %s\n"
          "%s\n"
          "Most likely Lua file has improper syntax, please check"),
            filename, lua_tostring(naevL, -1));
      return -1;
   }
   free(buf);

   return 0;
}


/**
 * @brief Initializes an AI_Profile and adds it to the stack.
 *
 *    @param[in] filename File to create the profile from.
 *    @return 0 on no error.
 */
static int ai_loadProfile( const char* filename )
{
   char* buf = NULL;
   size_t bufsize = 0;
   nlua_env env;
   AI_Profile *prof;
   size_t len;
   const char *str;

   /* Grow array. */
   prof = &array_grow(&profiles);

   /* Set name. */
   len = strlen(filename)-strlen(AI_PATH)-strlen(AI_SUFFIX);
   prof->name = malloc(len+1);
   strncpy( prof->name, &filename[strlen(AI_PATH)], len );
   prof->name[len] = '\0';

   /* Create Lua. */
   env = nlua_newEnv(1);
   nlua_loadStandard(env);
   prof->env = env;

   /* Register C functions in Lua */
   nlua_register(env, "ai", aiL_methods, 0);

   /* Add the pilot memory table. */
   lua_newtable(naevL);              /* pm */
   lua_pushvalue(naevL, -1);         /* pm, pm */
   nlua_setenv(env, AI_MEM);         /* pm */

   /* Set "mem" to be default template. */
   lua_newtable(naevL);              /* pm, nt */
   lua_pushvalue(naevL,-1);          /* pm, nt, nt */
   lua_setfield(naevL,-3,AI_MEM_DEF); /* pm, nt */
   nlua_setenv(env, "mem");          /* pm */
   lua_pop(naevL, 1);                /*  */

   /* Now load the file since all the functions have been previously loaded */
   buf = ndata_read( filename, &bufsize );
   if (nlua_dobufenv(env, buf, bufsize, filename) != 0) {
      WARN( _("Error loading AI file: %s\n"
          "%s\n"
          "Most likely Lua file has improper syntax, please check"),
            filename, lua_tostring(naevL,-1));
      array_erase( &profiles, prof, &prof[1] );
      free(prof->name);
      nlua_freeEnv( env );
      free(buf);
      return -1;
   }
   free(buf);

   /* Find and set up the necessary references. */
   str = _("AI Profile '%s' is missing '%s' function!");
   prof->ref_control = nlua_refenvtype( env, "control", LUA_TFUNCTION );
   if (prof->ref_control == LUA_NOREF)
      WARN( str, filename, "control" );
   prof->ref_control_manual = nlua_refenvtype( env, "control_manual", LUA_TFUNCTION );
   if (prof->ref_control == LUA_NOREF)
      WARN( str, filename, "control_manual" );
   prof->ref_refuel = nlua_refenvtype( env, "refuel", LUA_TFUNCTION );
   if (prof->ref_control == LUA_NOREF)
      WARN( str, filename, "refuel" );

   return 0;
}


/**
 * @brief Gets the AI_Profile by name.
 *
 *    @param[in] name Name of the profile to get.
 *    @return The profile or NULL on error.
 */
AI_Profile* ai_getProfile( char* name )
{
   int i;

   for (i=0; i<array_size(profiles); i++)
      if (strcmp(name,profiles[i].name)==0)
         return &profiles[i];

   WARN( _("AI Profile '%s' not found in AI stack"), name);
   return NULL;
}


/**
 * @brief Cleans up global AI.
 */
void ai_exit (void)
{
   int i;

   /* Free AI profiles. */
   for (i=0; i<array_size(profiles); i++) {
      free(profiles[i].name);
      nlua_freeEnv(profiles[i].env);
   }
   array_free( profiles );

   /* Free equipment Lua. */
   if (equip_env != LUA_NOREF)
      nlua_freeEnv(equip_env);
   equip_env = LUA_NOREF;
}


/**
 * @brief Heart of the AI, brains of the pilot.
 *
 *    @param pilot Pilot that needs to think.
 *    @param dt Current delta tick.
 */
void ai_think( Pilot* pilot, const double dt )
{
   nlua_env env;
   (void) dt;
   int data;

   Task *t;

   /* Must have AI. */
   if (pilot->ai == NULL)
      return;

   ai_setPilot(pilot);
   env = cur_pilot->ai->env; /* set the AI profile to the current pilot's */

   /* Clean up some variables */
   pilot_flags = 0;

   /* Reset thrust and turn. */
   pilot_setThrust(cur_pilot, 0.);
   pilot_setTurn(cur_pilot, 0.);

   /* So the way this works is that, for other than the player, we reset all
    * the weapon sets every frame, so that the AI has to redo them over and
    * over. Now, this is a horrible hack so shit works and needs a proper fix.
    * TODO fix. */
   /* pilot_setTarget( cur_pilot, cur_pilot->id ); */
   if (cur_pilot->id != PLAYER_ID)
      pilot_weapSetAIClear( cur_pilot );

   /* Get current task. */
   t = ai_curTask( cur_pilot );

   /* control function if pilot is idle or tick is up */
   if ((cur_pilot->tcontrol < 0.) || (t == NULL)) {
      if (pilot_isFlag(pilot,PILOT_PLAYER)
            || pilot_isFlag(cur_pilot, PILOT_MANUAL_CONTROL)) {
         lua_rawgeti( naevL, LUA_REGISTRYINDEX, cur_pilot->ai->ref_control_manual );
         ai_run(env, 0);
      } else {
         lua_rawgeti( naevL, LUA_REGISTRYINDEX, cur_pilot->ai->ref_control );
         ai_run(env, 0); /* run control */
      }

      nlua_getenv(env, "control_rate");
      cur_pilot->tcontrol = lua_tonumber(naevL,-1);
      lua_pop(naevL,1);

      /* Task may have changed due to control tick. */
      t = ai_curTask( cur_pilot );
   }

   if (pilot_isFlag(pilot,PILOT_PLAYER) &&
       !pilot_isFlag(cur_pilot, PILOT_MANUAL_CONTROL))
      return;

   /* pilot has a currently running task */
   if (t != NULL) {
      /* Run subtask if available, otherwise run main task. */
      if (t->subtask != NULL) {
         lua_rawgeti( naevL, LUA_REGISTRYINDEX, t->subtask->func );
         /* Use subtask data or task data if subtask is not set. */
         data = t->subtask->dat;
         if (data == LUA_NOREF)
            data = t->dat;
      }
      else {
         lua_rawgeti( naevL, LUA_REGISTRYINDEX, t->func );
         data = t->dat;
      }
      /* Function should be on the stack. */
      if (data != LUA_NOREF) {
         lua_rawgeti( naevL, LUA_REGISTRYINDEX, data );
         ai_run(env, 1);
      } else
         ai_run(env, 0);
   }

   /* Manual control must check if idle hook has to be run. */
   if (pilot_isFlag(cur_pilot, PILOT_MANUAL_CONTROL)
         && (ai_curTask(cur_pilot) == NULL))
      pilot_runHook(cur_pilot, PILOT_HOOK_IDLE);

   /* fire weapons if needed */
   if (ai_isFlag(AI_PRIMARY))
      pilot_shoot(cur_pilot, 0); /* primary */
   if (ai_isFlag(AI_SECONDARY))
      pilot_shoot(cur_pilot, 1 ); /* secondary */

   /* other behaviours. */
   if (ai_isFlag(AI_DISTRESS))
      pilot_distress(cur_pilot, NULL, aiL_distressmsg);

   /* Clean up if necessary. */
   ai_taskGC( cur_pilot );
}


/**
 * @brief Triggers the attacked() function in the pilot's AI.
 *
 *    @param attacked Pilot that is attacked.
 *    @param[in] attacker ID of the attacker.
 *    @param[in] dmg Damage done by the attacker.
 */
void ai_attacked(Pilot* attacked, const pilotId_t attacker, double dmg)
{
   HookParam hparam[2];
   HookParam ghparam[4];

   /* Run pilot attacked hook. */
   ghparam[0].type = HOOK_PARAM_PILOT;
   ghparam[0].u.lp = attacked->id;
   if (pilot_get(attacker) != NULL) {
      hparam[0].type = HOOK_PARAM_PILOT;
      hparam[0].u.lp = attacker;
      ghparam[1].type = HOOK_PARAM_PILOT;
      ghparam[1].u.lp = attacker;
   }
   else {
      hparam[0].type = HOOK_PARAM_NIL;
      ghparam[1].type = HOOK_PARAM_NIL;
   }
   hparam[1].type = HOOK_PARAM_NUMBER;
   hparam[1].u.num = dmg;
   ghparam[2].type = HOOK_PARAM_NUMBER;
   ghparam[2].u.num = dmg;
   ghparam[3].type = HOOK_PARAM_SENTINEL;

   pilot_runHookParam(attacked, PILOT_HOOK_ATTACKED, hparam, 2);
   hooks_runParam("attacked", ghparam);

   /* Behaves differently if manually overridden. */
   if (pilot_isFlag( attacked, PILOT_MANUAL_CONTROL ))
      return;

   /* Must have an AI profile and not be player. */
   if (attacked->ai == NULL)
      return;

   ai_setPilot( attacked ); /* Sets cur_pilot. */

   nlua_getenv(cur_pilot->ai->env, "attacked");

   lua_pushpilot(naevL, attacker);
   if (nlua_pcall(cur_pilot->ai->env, 1, 0)) {
      WARN( _("Pilot '%s' ai -> 'attacked': %s"), cur_pilot->name, lua_tostring(naevL, -1));
      lua_pop(naevL, 1);
   }
}


/**
 * @brief Has a pilot attempt to refuel the other.
 *
 *    @param refueler Pilot doing the refueling.
 *    @param target Pilot to refuel.
 */
void ai_refuel(Pilot* refueler, pilotId_t target)
{
   Task *t;

   if (cur_pilot->ai->ref_refuel==LUA_NOREF) {
      WARN(_("Pilot '%s' is trying to refuel when no 'refuel' function is defined!"), cur_pilot->name);
      return;
   }

   /* Create the task. */
   t           = calloc( 1, sizeof(Task) );
   t->name     = strdup("refuel");
   lua_rawgeti(naevL, LUA_REGISTRYINDEX, cur_pilot->ai->ref_refuel);
   t->func     = luaL_ref(naevL, LUA_REGISTRYINDEX);
   lua_pushpilot(naevL, target);
   t->dat      = luaL_ref(naevL, LUA_REGISTRYINDEX);

   /* Prepend the task. */
   t->next     = refueler->task;
   refueler->task = t;

   return;
}


/**
 * @brief Sends a distress signal to a pilot.
 *
 *    @param p Pilot receiving the distress signal.
 *    @param distressed Pilot sending the distress signal.
 *    @param attacker Pilot attacking \p distressed.
 */
void ai_getDistress( Pilot *p, const Pilot *distressed, const Pilot *attacker )
{
   /* Ignore distress signals when under manual control. */
   if (pilot_isFlag( p, PILOT_MANUAL_CONTROL ))
      return;

   /* Must have AI. */
   if (cur_pilot->ai == NULL)
      return;

   /* Set up the environment. */
   ai_setPilot(p);

   /* See if function exists. */
   nlua_getenv(cur_pilot->ai->env, "distress");
   if (lua_isnil(naevL,-1)) {
      lua_pop(naevL,1);
      return;
   }

   /* Run the function. */
   lua_pushpilot(naevL, distressed->id);
   if (attacker != NULL)
      lua_pushpilot(naevL, attacker->id);
   else /* Default to the victim's current target. */
      lua_pushpilot(naevL, distressed->target);

   if (nlua_pcall(cur_pilot->ai->env, 2, 0)) {
      WARN( _("Pilot '%s' ai -> 'distress': %s"), cur_pilot->name, lua_tostring(naevL,-1));
      lua_pop(naevL,1);
   }
}


/**
 * @brief Runs the create() function in the pilot.
 *
 * Should create all the gear and such the pilot has.
 *
 *    @param pilot Pilot to "create".
 */
static void ai_create( Pilot* pilot )
{
   nlua_env env;
   char *func;

   env = equip_env;
   func = "equip_generic";

   /* Set creation mode. */
   if (!pilot_isFlag(pilot, PILOT_CREATED_AI))
      aiL_status = AI_STATUS_CREATE;

   /* Create equipment first - only if creating for the first time. */
   if (!pilot_isFlag(pilot,PILOT_NO_OUTFITS)
         && !pilot_isFlag(pilot,PILOT_NO_EQUIP)
         && (aiL_status==AI_STATUS_CREATE)
         && !pilot_isFlag(pilot, PILOT_EMPTY)
         && (pilot->id != PLAYER_ID)) {
      if  (faction_getEquipper( pilot->faction ) != LUA_NOREF) {
         env = faction_getEquipper( pilot->faction );
         func = "equip";
      }
      nlua_getenv(env, func);
      nlua_pushenv(env);
      lua_setfenv(naevL, -2);
      lua_pushpilot(naevL, pilot->id);
      if (nlua_pcall(env, 1, 0)) { /* Error has occurred. */
         WARN( _("Pilot '%s' equip -> '%s': %s"), pilot->name, func, lua_tostring(naevL, -1));
         lua_pop(naevL, 1);
      }
   }

   /* Since the pilot changes outfits and cores, we must heal him up. */
   pilot_healLanded( pilot );

   /* Must have AI. */
   if (pilot->ai == NULL)
      return;

   /* Prepare AI (this sets cur_pilot among others). */
   ai_setPilot( pilot );

   /* Prepare stack. */
   nlua_getenv(cur_pilot->ai->env, "create");

   /* Run function. */
   if (nlua_pcall(cur_pilot->ai->env, 0, 0)) { /* error has occurred */
      WARN( _("Pilot '%s' ai -> '%s': %s"), cur_pilot->name, "create", lua_tostring(naevL,-1));
      lua_pop(naevL,1);
   }

   /* Recover normal mode. */
   if (!pilot_isFlag(pilot, PILOT_CREATED_AI))
      aiL_status = AI_STATUS_NORMAL;
}


/**
 * @brief Creates a new AI task.
 */
Task *ai_newtask( Pilot *p, const char *func, int subtask, int pos )
{
   Task *t, *curtask, *pointer;
   nlua_env env = p->ai->env;

   if (p->ai == NULL) {
      NLUA_ERROR(naevL,
            _("Trying to create task for pilot '%s' which has no AI."),
            p->name);
      return NULL;
   }

   /* Check if the function is good. */
   nlua_getenv( env, func );
   luaL_checktype( naevL, -1, LUA_TFUNCTION );

   /* Create the new task. */
   t = calloc(1, sizeof(Task));
   t->name = strdup(func);
   t->func = luaL_ref(naevL, LUA_REGISTRYINDEX);
   t->dat = LUA_NOREF;

   /* Handle subtask and general task. */
   if (!subtask) {
      if ((pos == 1) && (p->task != NULL)) { /* put at the end */
         for (pointer = p->task; pointer->next != NULL; pointer = pointer->next);
         pointer->next = t;
      }
      else {
         t->next = p->task;
         p->task = t;
      }
   }
   else {
      /* Must have valid task. */
      curtask = ai_curTask(p);
      if (curtask == NULL) {
         ai_freetask(t);
         NLUA_ERROR(naevL,
               _("Trying to add subtask '%s' to non-existent task."), func);
         return NULL;
      }

      /* Add the subtask. */
      if ((pos == 1) && (curtask->subtask != NULL)) { /* put at the end */
         for (pointer = curtask->subtask; pointer->next != NULL; pointer = pointer->next);
         pointer->next = t;
      }
      else {
         t->next           = curtask->subtask;
         curtask->subtask  = t;
      }
   }

   return t;
}


/**
 * @brief Frees an AI task.
 *
 *    @param t Task to free.
 */
void ai_freetask( Task* t )
{
   if (t->func != LUA_NOREF)
      luaL_unref(naevL, LUA_REGISTRYINDEX, t->func);

   if (t->dat != LUA_NOREF)
      luaL_unref(naevL, LUA_REGISTRYINDEX, t->dat);

   /* Recursive subtask freeing. */
   if (t->subtask != NULL) {
      ai_freetask(t->subtask);
      t->subtask = NULL;
   }

   /* Free next task in the chain. */
   if (t->next != NULL) {
      ai_freetask(t->next); /* yay recursive freeing */
      t->next = NULL;
   }

   free(t->name);
   free(t);
}


/**
 * @brief Creates a new task based on stack information.
 */
static Task* ai_createTask( lua_State *L, int subtask )
{
   const char *func;
   Task *t;

   /* Parse basic parameters. */
   func = luaL_checkstring(L, 1);

   /* Creates a new AI task. */
   t = ai_newtask(cur_pilot, func, subtask, 0);
   if (t == NULL) {
      NLUA_ERROR(L, _("Failed to create new task '%s' for pilot '%s'."),
            (func != NULL ? func : "NULL"), cur_pilot->name);
      return NULL;
   }

   /* Set the data. */
   if (lua_gettop(L) > 1) {
      lua_pushvalue(L,2);
      t->dat = luaL_ref(L, LUA_REGISTRYINDEX);
   }

   return t;
}


/**
 * @brief Pushes a task target.
 */
static int ai_tasktarget( lua_State *L, Task *t )
{
   if (t->dat == LUA_NOREF)
      return 0;
   lua_rawgeti(L, LUA_REGISTRYINDEX, t->dat);
   return 1;
}


/**
 * @defgroup AI Lua AI Bindings
 *
 * @brief Handles how the AI interacts with the universe.
 *
 * Usage is:
 * @code
 * ai.function( params )
 * @endcode
 *
 * @{
 */
/**
 * @brief Pushes a task onto the pilot's task list.
 *    @luatparam string func Name of function to call for task.
 *    @luaparam[opt] data Data to pass to the function.  Supports any lua type.
 * @luafunc pushtask
 *    @return Number of Lua parameters.
 */
static int aiL_pushtask( lua_State *L )
{
   ai_createTask( L, 0 );
   return 0;
}
/**
 * @brief Pops the current running task.
 * @luafunc poptask
 *    @return Number of Lua parameters.
 */
static int aiL_poptask( lua_State *L )
{
   Task* t = ai_curTask( cur_pilot );

   /* Tasks must exist. */
   if (t == NULL) {
      NLUA_ERROR(L, _("Trying to pop task when there are no tasks on the stack."));
      return 0;
   }

   t->done = 1;
   return 0;
}

/**
 * @brief Gets the current task's name.
 *    @luatreturn string The current task name or nil if there are no tasks.
 * @luafunc taskname
 *    @return Number of Lua parameters.
 */
static int aiL_taskname( lua_State *L )
{
   Task *t = ai_curTask( cur_pilot );
   if (t)
      lua_pushstring(L, t->name);
   else
      lua_pushnil(L);
   return 1;
}

/**
 * @brief Gets the pilot's task data.
 *    @luareturn The pilot's task data or nil if there is no task data.
 *    @luasee pushtask
 * @luafunc taskdata
 *    @return Number of Lua parameters.
 */
static int aiL_taskdata( lua_State *L )
{
   Task *t = ai_curTask( cur_pilot );

   /* Must have a task. */
   if (t == NULL)
      return 0;

   return ai_tasktarget( L, t );
}

/**
 * @brief Pushes a subtask onto the pilot's task's subtask list.
 *    @luatparam string func Name of function to call for task.
 *    @luaparam[opt] data Data to pass to the function.  Supports any lua type.
 * @luafunc pushsubtask
 *    @return Number of Lua parameters.
 */
static int aiL_pushsubtask( lua_State *L )
{
   ai_createTask(L, 1);
   return 0;
}

/**
 * @brief Pops the current running task.
 * @luafunc popsubtask
 *    @return Number of Lua parameters.
 */
static int aiL_popsubtask( lua_State *L )
{
   Task *t, *st;
   t = ai_curTask( cur_pilot );

   /* Tasks must exist. */
   if (t == NULL) {
      NLUA_ERROR(L, _("Trying to pop task when there are no tasks on the stack."));
      return 0;
   }
   if (t->subtask == NULL) {
      NLUA_ERROR(L, _("Trying to pop subtask when there are no subtasks for the task '%s'."), t->name);
      return 0;
   }

   /* Exterminate, annihilate destroy. */
   st          = t->subtask;
   t->subtask  = st->next;
   st->next    = NULL;
   ai_freetask(st);
   return 0;
}

/**
 * @brief Gets the current subtask's name.
 *    @luatreturn string The current subtask name or nil if there are no subtasks.
 * @luafunc subtaskname
 *    @return Number of Lua parameters.
 */
static int aiL_subtaskname( lua_State *L )
{
   Task *t = ai_curTask( cur_pilot );
   if ((t != NULL) && (t->subtask != NULL))
      lua_pushstring(L, t->subtask->name);
   else
      lua_pushnil(L);
   return 1;
}

/**
 * @brief Gets the pilot's subtask target.
 *    @luareturn The pilot's target ship identifier or nil if no target.
 *    @luasee pushsubtask
 * @luafunc subtaskdata
 *    @return Number of Lua parameters.
 */
static int aiL_subtaskdata( lua_State *L )
{
   Task *t = ai_curTask( cur_pilot );
   /* Must have a subtask. */
   if ((t == NULL) || (t->subtask == NULL))
      return 0;

   return ai_tasktarget( L, t->subtask );
}


/**
 * @brief Gets the AI's pilot.
 *    @luatreturn Pilot The AI's pilot.
 * @luafunc pilot
 *    @return Number of Lua parameters.
 */
static int aiL_pilot( lua_State *L )
{
   lua_pushpilot(L, cur_pilot->id);
   return 1;
}


/**
 * @brief Gets a random pilot in the system.
 *    @luatreturn Pilot|nil
 * @luafunc rndpilot
 *    @return Number of Lua parameters.
 */
static int aiL_getrndpilot( lua_State *L )
{
   Pilot * const *pilot_stack;
   int p;

   pilot_stack = pilot_getAll();
   p = RNG(0, array_size(pilot_stack)-1);
   /* Make sure it can't be the same pilot. */
   if (pilot_stack[p]->id == cur_pilot->id) {
      p++;
      if (p >= array_size(pilot_stack))
         p = 0;
   }
   /* Last check. */
   if (pilot_stack[p]->id == cur_pilot->id)
      return 0;
   /* Actually found a pilot. */
   lua_pushpilot(L, pilot_stack[p]->id);
   return 1;
}

/**
 * @brief gets the nearest pilot to the current pilot
 *
 *    @luatreturn Pilot|nil
 *    @luafunc nearestpilot
 */
static int aiL_getnearestpilot( lua_State *L )
{
   /*dist will be initialized to a number*/
   /*this will only seek out pilots closer than dist*/
   Pilot * const *pilot_stack = pilot_getAll();
   int dist=1000;
   int i;
   int candidate_id = -1;

   /*cycle through all the pilots and find the closest one that is not the pilot */

   for (i = 0; i<array_size(pilot_stack); i++)
   {
       if (pilot_stack[i]->id != cur_pilot->id && vect_dist(&pilot_stack[i]->solid->pos, &cur_pilot->solid->pos) < dist)
       {
            dist = vect_dist(&pilot_stack[i]->solid->pos, &cur_pilot->solid->pos);
            candidate_id = i;
       }
   }

   /* Last check. */
   if (candidate_id == -1)
      return 0;

   /* Actually found a pilot. */
   lua_pushpilot(L, pilot_stack[candidate_id]->id);
   return 1;
}

/**
 * @brief Gets the distance from the pointer.
 *
 *    @luatparam Vec2|Pilot pointer
 *    @luatreturn number The distance from the pointer.
 *    @luafunc dist
 */
static int aiL_getdistance( lua_State *L )
{
   Vector2d *v;
   Pilot *p;

   /* vector as a parameter */
   if (lua_isvector(L,1))
      v = lua_tovector(L,1);

   /* pilot as parameter */
   else if (lua_ispilot(L,1)) {
      p = luaL_validpilot(L,1);
      v = &p->solid->pos;
   }

   /* wrong parameter */
   else
      NLUA_INVALID_PARAMETER(L);

   lua_pushnumber(L, vect_dist(v, &cur_pilot->solid->pos));
   return 1;
}

/**
 * @brief Gets the distance from the pointer perpendicular to the current pilot's flight vector.
 *
 *    @luatparam Vec2|Pilot pointer
 *    @luatreturn number offset_distance
 *    @luafunc flyby_dist
 */
static int aiL_getflybydistance( lua_State *L )
{
   Vector2d *v;
   Vector2d perp_motion_unit, offset_vect;
   Pilot *p;
   int offset_distance;

   /* vector as a parameter */
   if (lua_isvector(L,1))
      v = lua_tovector(L,1);
   /* pilot id as parameter */
   else if (lua_ispilot(L,1)) {
      p = luaL_validpilot(L,1);
      v = &p->solid->pos;

      /*vect_cset(&v, VX(pilot->solid->pos) - VX(cur_pilot->solid->pos), VY(pilot->solid->pos) - VY(cur_pilot->solid->pos) );*/
   }
   else
      NLUA_INVALID_PARAMETER(L);

   vect_cset(&offset_vect, VX(*v) - VX(cur_pilot->solid->pos), VY(*v) - VY(cur_pilot->solid->pos) );
   vect_pset(&perp_motion_unit, 1, VANGLE(cur_pilot->solid->vel)+M_PI_2);
   offset_distance = vect_dot(&perp_motion_unit, &offset_vect);

   lua_pushnumber(L, offset_distance);
   return 1;
}

/**
 * @brief Gets the minimum braking distance.
 *
 * braking vel ==> 0 = v - a*dt
 * add turn around time (to initial vel) ==> 180.*360./cur_pilot->turn
 * add it to general euler equation  x = v * t + 0.5 * a * t^2
 * and voila!
 *
 * I hate this function and it'll probably need to get changed in the future
 *
 *
 *    @luatreturn number Minimum braking distance.
 *    @luafunc minbrakedist
 */
static int aiL_minbrakedist( lua_State *L )
{
   double accel;
   double time;
   double dist;
   double vel;
   Vector2d vv;
   Pilot *p;

   /* Calculate acceleration. */
   accel = cur_pilot->thrust / cur_pilot->solid->mass;

   /* More complicated calculation based on relative velocity. */
   if (lua_gettop(L) > 0) {
      p = luaL_validpilot(L,1);

      /* Set up the vectors. */
      vect_cset( &vv, p->solid->vel.x - cur_pilot->solid->vel.x,
            p->solid->vel.y - cur_pilot->solid->vel.y );

      /* Run the same calculations. */
      time = VMOD(vv) / accel;

      /* Get relative velocity. */
      vel = MIN(cur_pilot->speed - VMOD(p->solid->vel), VMOD(vv));
      if (vel < 0.)
         vel = 0.;
   }

   /* Simple calculation based on distance. */
   else {
      /* Get current time to reach target. */
      time = VMOD(cur_pilot->solid->vel) / accel;

      /* Get velocity, or non-thrusting speed if that is lower (since
       * the ship will slow down to that speed when turning around). */
      vel = MIN(cur_pilot->speed, VMOD(cur_pilot->solid->vel));
   }
   /* Get distance to brake. */
   dist = MAX(0., vel*(time+1.1*M_PI/cur_pilot->turn) - 0.5*accel*pow2(time));

   lua_pushnumber(L, dist); /* return */
   return 1; /* returns one thing */
}


/**
 * @brief Checks to see if target has bribed pilot.
 *
 *    @luatparam Pilot target
 *    @luatreturn boolean Whether the target has bribed pilot.
 *    @luafunc isbribed
 */
static int aiL_isbribed( lua_State *L )
{
   Pilot *p;
   p = luaL_validpilot(L,1);
   lua_pushboolean(
         L, ((p->faction == FACTION_PLAYER) || (p->parent == PLAYER_ID))
            && pilot_isFlag(cur_pilot, PILOT_BRIBED));
   return 1;
}


/**
 * @brief Checks to see if pilot can instant jump.
 *
 *    @luatreturn boolean Whether the pilot can instant jump.
 *    @luafunc instantJump
 */
static int aiL_instantJump( lua_State *L )
{
   lua_pushboolean(L, cur_pilot->stats.misc_instant_jump);
   return 1;
}


/**
 * @brief Gets the standing of the target pilot with the current pilot.
 *
 *    @luatparam Pilot target Pilot to get faction standing of.
 *    @luatreturn number|nil The faction standing of the target [-100,100] or nil if invalid.
 * @luafunc getstanding
 */
static int aiL_getstanding( lua_State *L )
{
   Pilot *p;

   /* Get parameters. */
   p = luaL_validpilot(L,1);

   /* Get faction standing. */
   if (p->faction == FACTION_PLAYER)
      lua_pushnumber(L, faction_getPlayer(cur_pilot->faction));
   else {
      if (areAllies( cur_pilot->faction, p->faction ))
         lua_pushnumber(L, 100);
      else if (areEnemies( cur_pilot->faction, p->faction ))
         lua_pushnumber(L,-100);
      else
         lua_pushnumber(L, 0);
   }

   return 1;
}


/**
 * @brief Checks to see if pilot is at maximum velocity.
 *
 *    @luatreturn boolean Whether the pilot is at maximum velocity.
 *    @luafunc ismaxvel
 */
static int aiL_ismaxvel( lua_State *L )
{
   //lua_pushboolean(L,(VMOD(cur_pilot->solid->vel) > (cur_pilot->speed-MIN_VEL_ERR)));
   lua_pushboolean(L,(VMOD(cur_pilot->solid->vel) >
                   (solid_maxspeed(cur_pilot->solid, cur_pilot->speed, cur_pilot->thrust)-MIN_VEL_ERR)));
   return 1;
}


/**
 * @brief Checks to see if pilot is stopped.
 *
 *    @luatreturn boolean Whether the pilot is stopped.
 *    @luafunc isstopped
 */
static int aiL_isstopped( lua_State *L )
{
   lua_pushboolean(L,(VMOD(cur_pilot->solid->vel) < MIN_VEL_ERR));
   return 1;
}


/**
 * @brief Checks to see if target is an enemy.
 *
 *    @luatparam Pilot target
 *    @luatreturn boolean Whether the target is an enemy.
 *    @luafunc isenemy
 */
static int aiL_isenemy( lua_State *L )
{
   Pilot *p;

   /* Get the pilot. */
   p = luaL_validpilot(L,1);

   /* Player needs special handling in case of hostility. */
   if ((p->faction == FACTION_PLAYER) || (p->parent == PLAYER_ID)) {
      lua_pushboolean(L, pilot_isHostile(cur_pilot));
      return 1;
   }

   /* Check if is ally. */
   lua_pushboolean(L,areEnemies(cur_pilot->faction, p->faction));
   return 1;
}

/**
 * @brief Checks to see if target is an ally.
 *
 *    @luatparam Pilot target
 *    @luatreturn boolean Whether the target is an ally.
 *    @luafunc isally
 */
static int aiL_isally( lua_State *L )
{
   Pilot *p;

   /* Get the pilot. */
   p = luaL_validpilot(L,1);

   /* Player needs special handling in case of friendliness. */
   if ((p->faction == FACTION_PLAYER) || (p->parent == PLAYER_ID)) {
      lua_pushboolean(L, pilot_isFriendly(cur_pilot));
      return 1;
   }

   /* Check if is ally. */
   lua_pushboolean(L,areAllies(cur_pilot->faction, p->faction));
   return 1;
}


/**
 * @brief Checks to see if pilot has a missile lockon.
 *
 *    @luatreturn boolean Whether the pilot has a missile lockon.
 *    @luafunc haslockon
 */

static int aiL_haslockon( lua_State *L )
{
   lua_pushboolean(L, cur_pilot->lockons > 0);
   return 1;
}


/**
 * @brief Checks to see if pilot has a projectile after him.
 *
 *    @luatreturn boolean Whether the pilot has a projectile after him.
 *    @luafunc hasprojectile
 */

static int aiL_hasprojectile( lua_State *L )
{
   lua_pushboolean(L, cur_pilot->projectiles > 0);
   return 1;
}


/**
 * @brief Starts accelerating the pilot.
 *
 *    @luatparam[opt=1.] number acceleration Fraction of pilot's maximum acceleration from 0 to 1.
 *    @luafunc accel
 */
static int aiL_accel( lua_State *L )
{
   double thrust;

   thrust = luaL_optnumber(L, 1, 1.);
   pilot_setThrust(cur_pilot, thrust);

   return 0;
}


/**
 * @brief Starts turning the pilot.
 *
 *    @luatparam number vel Directional velocity from -1 to 1.
 *    @luafunc turn
 */
static int aiL_turn( lua_State *L )
{
   double turn = CLAMP(0., 1., luaL_checknumber(L,1));
   pilot_setTurn(cur_pilot, turn);
   return 0;
}


/**
 * @brief Rotates to a certain direction.
 *
 * @usage ai.rotate(45) -- Rotate to a 45° facing.
 *
 *    @luatparam number angle Angle to rotate to in degrees.
 *    @luatreturn number Angle offset in degrees.
 * @luafunc rotate
 */
static int aiL_rotate(lua_State *L)
{
   double dir;
   double diff;

   dir = luaL_checknumber(L, 1);
   diff = pilot_face(cur_pilot, dir*M_PI/180.);

   lua_pushnumber(L, ABS(diff*180./M_PI));
   return 1;
}


/**
 * @brief Faces the target.
 *
 * @usage ai.face( a_pilot ) -- Face a pilot
 * @usage ai.face( a_pilot, true ) -- Face away from a pilot
 * @usage ai.face( a_pilot, nil, true ) -- Compensate velocity facing a pilot
 *
 *    @luatparam Pilot|Vec2 target Target to face.
 *    @luatparam[opt=false] boolean invert Invert away from target.
 *    @luatparam[opt=false] boolean compensate Compensate for velocity?
 *    @luatreturn number Angle offset in degrees.
 * @luafunc face
 */
static int aiL_face( lua_State *L )
{
   Vector2d *tv; /* get the position to face */
   Pilot* p;
   int inv;
   double k_vel;
   double d;
   double diff;
   double vx, vy, dx, dy;
   int vel;

   /* Get first parameter, aka what to face. */
   if (lua_ispilot(L,1)) {
      p = luaL_validpilot(L,1);
      /* Target vector. */
      tv = &p->solid->pos;
   }
   else if (lua_isvector(L,1))
      tv = lua_tovector(L,1);
   else
      NLUA_INVALID_PARAMETER(L);

   /* Default gain. */
   k_vel  = 100.; /* overkill gain! */

   inv = lua_toboolean(L, 2);
   vel = lua_toboolean(L, 3);

   /* Tangential component of velocity vector
    *
    * v: velocity vector
    * d: direction vector
    *
    *                  d       d                d
    * v_t = v - ( v . --- ) * --- = v - ( v . ----- ) * d
    *                 |d|     |d|             |d|^2
    */
   /* Velocity vector. */
   vx = cur_pilot->solid->vel.x;
   vy = cur_pilot->solid->vel.y;
   /* Direction vector. */
   dx = tv->x - cur_pilot->solid->pos.x;
   dy = tv->y - cur_pilot->solid->pos.y;

   /* If pilot's position is the same as target's position, attempting
    * to calculate a direction with velocity compensation can cause a
    * division by zero, so handle that case specially. */
   if ((dx != 0.) || (dy != 0.)) {
      if (vel) {
         /* Calculate dot product. */
         d = (vx*dx + vy*dy) / (dx*dx + dy*dy);
         /* Calculate tangential velocity. */
         vx = vx - d * dx;
         vy = vy - d * dy;

         /* Add velocity compensation. */
         dx += -k_vel * vx;
         dy += -k_vel * vy;
      }

      /* Compensate error and rotate. */
      diff = pilot_face(cur_pilot, atan2(dy, dx) + (inv ? M_PI : 0));
   }
   else {
      /* If pilot position is the same as target position, don't change
       * face angle. */
      diff = 0.;
      if (vel) {
         /* Unless compensating for velocity, in which case rotate to
          * the opposite direction of velocity. */
         diff = pilot_face(cur_pilot, atan2(-vx, -vy) + (inv ? M_PI : 0));
      }
   }

   /* Return angle in degrees away from target. */
   lua_pushnumber(L, ABS(diff*180./M_PI));
   return 1;
}


/**
 * @brief Gives the direction to follow in order to reach the target while
 *  minimizating risk.
 *
 * This method is based on a simplified version of trajectory generation in
 * mobile robotics using the potential method.
 *
 * The principle is to consider the mobile object (ship) as a mechanical object.
 * Obstacles (enemies) and the target exert
 * attractive or repulsive force on this object.
 *
 * Only visible ships are taken into account.
 *
 *    @luatparam Pilot|Vec2|number target Target to go to.
 * @luafunc careful_face
 */
static int aiL_careful_face( lua_State *L )
{
   Vector2d *tv, F, F1;
   Pilot* p;
   Pilot *p_i;
   double k_goal, k_enemy, k_mult,
          d, diff, dist, factor;
   int i;
   Pilot * const *pilot_stack;

   /* Init some variables */
   pilot_stack = pilot_getAll();
   p = cur_pilot;

   /* Get first parameter, aka what to face. */
   if (lua_ispilot(L,1)) {
      p = luaL_validpilot(L,1);
      /* Target vector. */
      tv = &p->solid->pos;
   }
   else if (lua_isnumber(L,1)) {
      d = (double)lua_tonumber(L,1);
      if (d < 0.)
         tv = &cur_pilot->solid->pos;
      else
         NLUA_INVALID_PARAMETER(L);
   }
   else if (lua_isvector(L,1))
      tv = lua_tovector(L,1);
   else
      NLUA_INVALID_PARAMETER(L);

   /* Default gains. */
   k_goal = 1.;
   k_enemy = 6000000.;

   /* Init the force */
   vect_cset( &F, 0., 0.) ;
   vect_cset( &F1, tv->x - cur_pilot->solid->pos.x, tv->y - cur_pilot->solid->pos.y) ;
   dist = VMOD(F1) + 0.1; /* Avoid / 0*/
   vect_cset( &F1, F1.x * k_goal / dist, F1.y * k_goal / dist) ;

   /* Cycle through all the pilots in order to compute the force */
   for (i=0; i<array_size(pilot_stack); i++) {
      p_i = pilot_stack[i];

      /* Valid pilot isn't self, is in range, isn't the target and isn't disabled */
      if (pilot_isDisabled(p_i) ) continue;
      if (p_i->id == cur_pilot->id) continue;
      if (p_i->id == p->id) continue;
      if (pilot_inRangePilot(cur_pilot, p_i, NULL) != 1) continue;

      /* If the enemy is too close, ignore it*/
      dist = vect_dist(&p_i->solid->pos, &cur_pilot->solid->pos);
      if (dist < 750) continue;

      k_mult = pilot_relhp( p_i, cur_pilot ) * pilot_reldps( p_i, cur_pilot );

      /* Check if friendly or not */
      if (areEnemies(cur_pilot->faction, p_i->faction)) {
         factor = k_enemy * k_mult / (dist*dist*dist);
         vect_cset( &F, F.x + factor * (cur_pilot->solid->pos.x - p_i->solid->pos.x),
                F.y + factor * (cur_pilot->solid->pos.y - p_i->solid->pos.y) );
      }
   }

   vect_cset( &F, F.x + F1.x, F.y + F1.y );

   /* Rotate. */
   diff = pilot_face(cur_pilot, VANGLE(F));

   /* Return angle in degrees away from target. */
   lua_pushnumber(L, ABS(diff*180./M_PI));
   return 1;
}


/**
 * @brief Aims at a pilot, trying to hit it rather than move to it.
 *
 * This method uses a polar UV decomposition to get a more accurate time-of-flight
 *
 *    @luatparam Pilot target The pilot to aim at
 *    @luatreturn number The offset from the target aiming position (in degrees).
 * @luafunc aim
 */
static int aiL_aim( lua_State *L )
{
   Pilot *p;
   double diff;
   double angle;

   /* Only acceptable parameter is pilot */
   p = luaL_validpilot(L,1);

   angle = pilot_aimAngle( cur_pilot, p );

   /* Calculate what we need to turn */
   diff = pilot_face(cur_pilot, angle);

   /* Return distance to target (in grad) */
   lua_pushnumber(L, ABS(diff*180./M_PI));
   return 1;
}


/**
 * @brief Maintains an intercept pursuit course.
 *
 *    @luatparam Pilot|Vec2 target Position or pilot to intercept.
 *    @luatreturn number The offset from the proper intercept course (in degrees).
 * @luafunc iface
 */
static int aiL_iface( lua_State *L )
{
   NLUA_MIN_ARGS(1);
   Vector2d *vec, drift, reference_vector; /* get the position to face */
   Pilot* p;
   double diff, heading_offset_azimuth, drift_radial, drift_azimuthal;
   int azimuthal_sign;
   double speedmap;

   /* Get first parameter, aka what to face. */
   p  = NULL;
   vec = NULL;
   if (lua_ispilot(L,1))
      p = luaL_validpilot(L,1);
   else if (lua_isvector(L,1))
      vec = lua_tovector(L,1);
   else NLUA_INVALID_PARAMETER(L);

   if (vec==NULL) {
      if (p == NULL)
         return 0; /* Return silently when attempting to face an invalid pilot. */
      /* Establish the current pilot velocity and position vectors */
      vect_cset( &drift, VX(p->solid->vel) - VX(cur_pilot->solid->vel), VY(p->solid->vel) - VY(cur_pilot->solid->vel));
      /* Establish the in-line coordinate reference */
      vect_cset( &reference_vector, VX(p->solid->pos) - VX(cur_pilot->solid->pos), VY(p->solid->pos) - VY(cur_pilot->solid->pos));
   }
   else {
      /* Establish the current pilot velocity and position vectors */
      vect_cset( &drift, -VX(cur_pilot->solid->vel), -VY(cur_pilot->solid->vel));
      /* Establish the in-line coordinate reference */
      vect_cset( &reference_vector, VX(*vec) - VX(cur_pilot->solid->pos), VY(*vec) - VY(cur_pilot->solid->pos));
   }

   /* Break down the the velocity vectors of both craft into UV coordinates */
   vect_uv(&drift_radial, &drift_azimuthal, &drift, &reference_vector);
   heading_offset_azimuth = angle_diff(cur_pilot->solid->dir, VANGLE(reference_vector));

   /* Now figure out what to do...
    * Are we pointing anywhere inside the correct UV quadrant?
    * if we're outside the correct UV quadrant, we need to get into it ASAP
    * Otherwise match velocities and approach */
   if (FABS(heading_offset_azimuth) < M_PI_2) {
      /* This indicates we're in the correct plane*/
      /* 1 - 1/(|x|+1) does a pretty nice job of mapping the reals to the interval (0...1). That forms the core of this angle calculation */
      /* There is nothing special about the scaling parameter of 200; it can be tuned to get any behavior desired. A lower
         number will give a more dramatic 'lead' */
      speedmap = -1*copysign(1 - 1 / (FABS(drift_azimuthal/200) + 1), drift_azimuthal) * M_PI_2;
      diff = angle_diff(heading_offset_azimuth, speedmap);
      azimuthal_sign = -1;

      /* This indicates we're drifting to the right of the target
       * And we need to turn CCW */
      if (diff > 0)
         pilot_setTurn(cur_pilot, azimuthal_sign);
      /* This indicates we're drifting to the left of the target
       * And we need to turn CW */
      else if (diff < 0)
         pilot_setTurn(cur_pilot, -1*azimuthal_sign);
      else
         pilot_setTurn(cur_pilot, 0);
   }
   /* turn most efficiently to face the target. If we intercept the correct quadrant in the UV plane first, then the code above will kick in */
   /* some special case logic is added to optimize turn time. Reducing this to only the else cases would speed up the operation
      but cause the pilot to turn in the less-than-optimal direction sometimes when between 135 and 225 degrees off from the target */
   else {
      /* signal that we're not in a productive direction for thrusting */
      diff = M_PI;
      azimuthal_sign = 1;


      if (heading_offset_azimuth >0)
         pilot_setTurn(cur_pilot, azimuthal_sign);
      else
         pilot_setTurn(cur_pilot, -1*azimuthal_sign);
   }

   /* Return angle in degrees away from target. */
   lua_pushnumber(L, ABS(diff*180./M_PI));
   return 1;
}

/**
 * @brief calculates the direction that the target is relative to the current pilot facing.
 *
 *    @luatparam Pilot|Vec2 target Position or pilot to compare facing to
 *    @luatreturn number The facing offset to the target (in degrees).
 * @luafunc dir
 *
 */
static int aiL_dir( lua_State *L )
{
   NLUA_MIN_ARGS(1);
   Vector2d *vec, sv, tv; /* get the position to face */
   Pilot* p;
   double diff;
   int n;

   /* Get first parameter, aka what to face. */
   n  = -2;
   vec = NULL;
   if (lua_ispilot(L,1)) {
      p = luaL_validpilot(L,1);
      vect_cset( &tv, VX(p->solid->pos), VY(p->solid->pos) );
   }
   else if (lua_isvector(L,1))
      vec = lua_tovector(L,1);
   else NLUA_INVALID_PARAMETER(L);

   vect_cset( &sv, VX(cur_pilot->solid->pos), VY(cur_pilot->solid->pos) );

   if (vec==NULL) /* target is dynamic */
      diff = angle_diff(cur_pilot->solid->dir,
            (n==-1) ? VANGLE(sv) :
            vect_angle(&sv, &tv));
   else /* target is static */
      diff = angle_diff( cur_pilot->solid->dir,
            (n==-1) ? VANGLE(cur_pilot->solid->pos) :
            vect_angle(&cur_pilot->solid->pos, vec));


   /* Return angle in degrees away from target. */
   lua_pushnumber(L, diff*180./M_PI);
   return 1;
}

/**
 * @brief calculates angle between pilot facing and intercept-course to target.
 *
 *    @luatparam Pilot|Vec2 target Position or pilot to compare facing to
 *    @luatreturn number The facing offset to intercept-course to the target (in degrees).
 * @luafunc idir
 */
static int aiL_idir( lua_State *L )
{
   NLUA_MIN_ARGS(1);
   Vector2d *vec, drift, reference_vector; /* get the position to face */
   Pilot* p;
   double diff, heading_offset_azimuth, drift_radial, drift_azimuthal;
   double speedmap;
   /*char announcebuffer[255] = " ", announcebuffer2[128];*/

   /* Get first parameter, aka what to face. */
   p  = NULL;
   vec = NULL;
   if (lua_ispilot(L,1))
      p = luaL_validpilot(L,1);
   else if (lua_isvector(L,1))
      vec = lua_tovector(L,1);
   else NLUA_INVALID_PARAMETER(L);

   if (vec==NULL) {
      if (p == NULL)
         return 0; /* Return silently when attempting to face an invalid pilot. */
      /* Establish the current pilot velocity and position vectors */
      vect_cset( &drift, VX(p->solid->vel) - VX(cur_pilot->solid->vel), VY(p->solid->vel) - VY(cur_pilot->solid->vel));
      /* Establish the in-line coordinate reference */
      vect_cset( &reference_vector, VX(p->solid->pos) - VX(cur_pilot->solid->pos), VY(p->solid->pos) - VY(cur_pilot->solid->pos));
   }
   else {
      /* Establish the current pilot velocity and position vectors */
      vect_cset( &drift, -VX(cur_pilot->solid->vel), -VY(cur_pilot->solid->vel));
      /* Establish the in-line coordinate reference */
      vect_cset( &reference_vector, VX(*vec) - VX(cur_pilot->solid->pos), VY(*vec) - VY(cur_pilot->solid->pos));
   }

   /* Break down the the velocity vectors of both craft into UV coordinates */
   vect_uv(&drift_radial, &drift_azimuthal, &drift, &reference_vector);
   heading_offset_azimuth = angle_diff(cur_pilot->solid->dir, VANGLE(reference_vector));

   /* now figure out what to do*/
   /* are we pointing anywhere inside the correct UV quadrant? */
   /* if we're outside the correct UV quadrant, we need to get into it ASAP */
   /* Otherwise match velocities and approach*/
   if (FABS(heading_offset_azimuth) < M_PI_2) {
      /* This indicates we're in the correct plane
       * 1 - 1/(|x|+1) does a pretty nice job of mapping the reals to the interval (0...1). That forms the core of this angle calculation
       * there is nothing special about the scaling parameter of 200; it can be tuned to get any behavior desired. A lower
       * number will give a more dramatic 'lead' */
      speedmap = -1*copysign(1 - 1 / (FABS(drift_azimuthal/200) + 1), drift_azimuthal) * M_PI_2;
      diff = angle_diff(heading_offset_azimuth, speedmap);

   }
   /* Turn most efficiently to face the target. If we intercept the correct quadrant in the UV plane first, then the code above will kick in
      some special case logic is added to optimize turn time. Reducing this to only the else cases would speed up the operation
      but cause the pilot to turn in the less-than-optimal direction sometimes when between 135 and 225 degrees off from the target */
   else {
      /* signal that we're not in a productive direction for thrusting */
      diff        = M_PI;
   }

   /* Return angle in degrees away from target. */
   lua_pushnumber(L, diff*180./M_PI);
   return 1;
}

/**
 * @brief Calculate the offset between the pilot's current direction of travel and the pilot's current facing.
 *
 *    @luatreturn number Offset
 *    @luafunc drift_facing
 */
static int aiL_drift_facing( lua_State *L )
{
    double drift;
    drift = angle_diff(VANGLE(cur_pilot->solid->vel), cur_pilot->solid->dir);
    lua_pushnumber(L, drift*180./M_PI);
    return 1;
}

/**
 * @brief Brakes the pilot.
 *
 *    @luatreturn boolean Whether braking is finished.
 *    @luafunc brake
 */

static int aiL_brake( lua_State *L )
{
   int ret;

   ret = pilot_brake(cur_pilot);

   lua_pushboolean(L, ret);
   return 1;
}


/**
 * @brief Get the nearest friendly planet to the pilot.
 *
 *    @luatreturn Planet|nil
 *    @luafunc nearestplanet
 */
static int aiL_getnearestplanet( lua_State *L )
{
   double dist, d;
   int i, j;
   LuaPlanet planet;

   /* cycle through planets */
   for (dist=HUGE_VAL, j=-1, i=0; i<array_size(cur_system->planets); i++) {
      if (!planet_hasService(cur_system->planets[i],PLANET_SERVICE_INHABITED))
         continue;
      d = vect_dist( &cur_system->planets[i]->pos, &cur_pilot->solid->pos );
      if ((!areEnemies(cur_pilot->faction,cur_system->planets[i]->faction)) &&
            (d < dist)) { /* closer friendly planet */
         j = i;
         dist = d;
      }
   }

   /* no friendly planet found */
   if (j == -1) return 0;

   cur_pilot->nav_planet = j;
   planet = cur_system->planets[j]->id;
   lua_pushplanet(L, planet);

   return 1;
}


/**
 * @brief Get the nearest friendly planet to a given position.
 *
 *    @luatparam vec2 pos Position close to the planet.
 *    @luatreturn Planet|nil
 *    @luafunc planetfrompos
 */
static int aiL_getplanetfrompos( lua_State *L )
{
   Vector2d *pos;
   double dist, d;
   int i, j;
   LuaPlanet planet;

   pos = luaL_checkvector(L,1);

   /* cycle through planets */
   for (dist=HUGE_VAL, j=-1, i=0; i<array_size(cur_system->planets); i++) {
      if (!planet_hasService(cur_system->planets[i], PLANET_SERVICE_INHABITED))
         continue;
      if (!planet_hasService(cur_system->planets[i], PLANET_SERVICE_LAND))
         continue;
      d = vect_dist( &cur_system->planets[i]->pos, pos );
      if ((!areEnemies(cur_pilot->faction,cur_system->planets[i]->faction)) &&
            (d < dist)) { /* closer friendly planet */
         j = i;
         dist = d;
      }
   }

   /* no friendly planet found */
   if (j == -1) return 0;

   cur_pilot->nav_planet = j;
   planet = cur_system->planets[j]->id;
   lua_pushplanet(L, planet);

   return 1;
}


/**
 * @brief Get a random planet.
 *
 *    @luatreturn Planet|nil
 *    @luafunc rndplanet
 */
static int aiL_getrndplanet( lua_State *L )
{
   LuaPlanet planet;
   int p;

   if (array_size(cur_system->planets) == 0) return 0; /* no planets */

   /* get a random planet */
   p = RNG(0, array_size(cur_system->planets)-1);

   /* Copy the data into a vector */
   planet = cur_system->planets[p]->id;
   lua_pushplanet(L, planet);

   return 1;
}

/**
 * @brief Get a random friendly planet.
 *
 *    @luatparam boolean only_friend Only check for ally planets.
 *    @luatreturn Planet|nil
 * @luafunc landplanet
 */
static int aiL_getlandplanet( lua_State *L )
{
   int *ind;
   int i;
   LuaPlanet planet;
   Planet *p;
   int only_friend;

   /* If pilot can't land ignore. */
   if (pilot_isFlag(cur_pilot, PILOT_NOLAND))
      return 0;

   /* Check if we should get only friendlies. */
   only_friend = lua_toboolean(L, 1);

   /* Allocate memory. */
   ind = array_create_size( int, array_size(cur_system->planets) );

   /* Copy friendly planet.s */
   for (i=0; i<array_size(cur_system->planets); i++) {
      if (!planet_hasService(cur_system->planets[i], PLANET_SERVICE_INHABITED))
         continue;
      if (!planet_hasService(cur_system->planets[i], PLANET_SERVICE_LAND))
         continue;

      /* Check conditions. */
      if (only_friend && !areAllies( cur_pilot->faction, cur_system->planets[i]->faction ))
         continue;
      else if (!only_friend && areEnemies(cur_pilot->faction,cur_system->planets[i]->faction))
         continue;

      /* Add it. */
      array_push_back( &ind, i );
   }

   /* no planet to land on found */
   if (array_size(ind)==0) {
      array_free(ind);
      return 0;
   }

   /* we can actually get a random planet now */
   i = RNG(0,array_size(ind)-1);
   p = cur_system->planets[ind[i]];
   planet = p->id;
   lua_pushplanet(L, planet);
   cur_pilot->nav_planet = ind[i];
   array_free(ind);

   return 1;
}


/**
 * @brief Helper function for aiL_canLand() and aiL_land().
 *
 *    @return Whether or not the current pilot can possibly land.
 */
static int ai_canLand(void)
{
   Planet *planet;

   /* Check that the pilot has a target selected. */
   if (cur_pilot->nav_planet < 0)
      return 0;

   /* Get planet. */
   planet = cur_system->planets[cur_pilot->nav_planet];

   /* Check landability. */
   if (!planet_hasService(planet, PLANET_SERVICE_LAND))
      return 0;

   /* Check landing functionality. */
   if (pilot_isFlag(cur_pilot, PILOT_NOLAND))
      return 0;

   return 1;
}


/**
 * @brief Checks whether or not ai.land() can be used.
 *
 * This function returns whether or not landing on the current planet
 * target is possible. Use this to avoid errors with ai.land().
 *
 *    @luatreturn boolean 
 * @luasee land
 * @luafunc canLand
 */
static int aiL_canLand(lua_State *L)
{
   lua_pushboolean(L, ai_canLand());
   return 1;
}


/**
 * @brief Lands on a planet.
 *
 * Throws an error if landing on the currently selected planet is
 * impossible.
 *
 *    @luatreturn boolean Whether landing was successful. (This will be
 *       false if position or speed is incorrect.)
 * @luasee canLand
 * @luafunc land
 */
static int aiL_land( lua_State *L )
{
   Planet *planet;
   HookParam hparam;

   if (!ai_canLand()) {
      NLUA_ERROR(L, _("Pilot '%s' cannot land."), cur_pilot->name);
      return 0;
   }

   /* Get planet. */
   planet = cur_system->planets[cur_pilot->nav_planet];
   if (planet == NULL) {
      NLUA_ERROR(L, _("Pilot '%s' has invalid planet targeted."),
            cur_pilot->name);
      return 0;
   }

   /* Check distance. */
   if (vect_dist2(&cur_pilot->solid->pos,&planet->pos) > pow2(planet->radius)) {
      lua_pushboolean(L, 0);
      return 1;
   }

   /* Check velocity. */
   if ((pow2(VX(cur_pilot->solid->vel)) + pow2(VY(cur_pilot->solid->vel))) >
         (double)pow2(MAX_HYPERSPACE_VEL)) {
      lua_pushboolean(L, 0);
      return 1;
   }

   cur_pilot->landing_delay = PILOT_LANDING_DELAY * cur_pilot->ship->dt_default;
   cur_pilot->ptimer = cur_pilot->landing_delay;
   pilot_setFlag(cur_pilot, PILOT_LANDING);

   hparam.type = HOOK_PARAM_ASSET;
   hparam.u.la = planet->id;

   pilot_runHookParam(cur_pilot, PILOT_HOOK_LAND, &hparam, 1);

   lua_pushboolean(L, 1);
   return 1;
}


/**
 * @brief Tries to perform an escape jump.
 *
 *    @luatreturn boolean Whether the escape jump was successful.
 *    @luafunc localjump
 */
static int aiL_localjump(lua_State *L)
{
   lua_pushnumber(L, pilot_localJump(cur_pilot));
   return 1;
}


/**
 * @brief Tries to enter hyperspace.
 *
 *    @luatreturn number|nil nil on success, -1 if too far away, -2 if
 *       hyperdrive is offline, -3 if too little fuel.
 *    @luafunc hyperspace
 */
static int aiL_hyperspace( lua_State *L )
{
   int ret;

   ret = space_hyperspace(cur_pilot);
   if (ret == 0) {
      pilot_shootStop( cur_pilot, 0 );
      pilot_shootStop( cur_pilot, 1 );
      lua_pushnil(L);
      return 1;
   }

   lua_pushnumber(L, ret);
   return 1;
}


/**
 * @brief Sets hyperspace target.
 *
 *    @luatparam Jump target Hyperspace target
 *    @luareturn Vec2 Where to go to jump
 *    @luafunc sethyptarget
 */
static int aiL_sethyptarget( lua_State *L )
{
   JumpPoint *jp;
   LuaJump *lj;
   Vector2d vec;
   double a, rad;

   lj = luaL_checkjump( L, 1 );
   jp = luaL_validjump( L, 1 );

   if ( lj->srcid != cur_system->id )
      NLUA_ERROR(L, _("Jump point must be in current system."));

   /* Copy vector. */
   vec = jp->pos;

   /* Introduce some error. */
   a     = RNGF() * M_PI * 2.;
   rad   = RNGF() * 0.5 * jp->radius;
   vect_cadd( &vec, rad*cos(a), rad*sin(a) );

   /* Set up target. */
   cur_pilot->nav_hyperspace = jp - cur_system->jumps;

   /* Return vector. */
   lua_pushvector( L, vec );

   return 1;
}


/**
 * @brief Gets the nearest hyperspace target.
 *
 *    @luatreturn JumpPoint|nil
 *    @luafunc nearhyptarget
 */
static int aiL_nearhyptarget( lua_State *L )
{
   JumpPoint *jp, *jiter;
   double mindist, dist;
   int i;
   LuaJump lj;

   /* Find nearest jump .*/
   mindist = INFINITY;
   jp      = NULL;
   for (i=0; i < array_size(cur_system->jumps); i++) {
      jiter = &cur_system->jumps[i];
      /* We want only standard jump points to be used. */
      if (jp_isFlag(jiter, JP_HIDDEN) || jp_isFlag(jiter, JP_EXITONLY))
         continue;
      /* Get nearest distance. */
      dist  = vect_dist2( &cur_pilot->solid->pos, &jiter->pos );
      if (dist < mindist) {
         jp       = jiter;
         mindist  = dist;
      }
   }
   /* None available. */
   if (jp == NULL)
      return 0;

   lj.destid = jp->targetid;
   lj.srcid = cur_system->id;

   /* Return Jump. */
   lua_pushjump( L, lj );
   return 1;
}


/**
 * @brief Gets a random hyperspace target.
 *
 *    @luatreturn JumpPoint|nil
 *    @luafunc rndhyptarget
 */
static int aiL_rndhyptarget( lua_State *L )
{
   JumpPoint **jumps, *jiter;
   int i, r;
   int *id;
   LuaJump lj;

   /* No jumps in the system. */
   if (array_size(cur_system->jumps) == 0)
      return 0;

   /* Find usable jump points. */
   jumps = array_create_size( JumpPoint*, array_size(cur_system->jumps) );
   id    = array_create_size( int, array_size(cur_system->jumps) );
   for (i=0; i < array_size(cur_system->jumps); i++) {
      jiter = &cur_system->jumps[i];
      /* We want only standard jump points to be used. */
      if (jp_isFlag(jiter, JP_HIDDEN) || jp_isFlag(jiter, JP_EXITONLY))
         continue;
      array_push_back( &id, i );
      array_push_back( &jumps, jiter );
   }

   /* Choose random jump point. */
   r = RNG( 0, MAX( array_size(jumps)-1, 0) );

   lj.destid = jumps[r]->targetid;
   lj.srcid = cur_system->id;

   /* Clean up. */
   array_free(jumps);
   array_free(id);

   /* Return Jump. */
   lua_pushjump( L, lj );
   return 1;
}

/**
 * @brief Gets the relative velocity of a pilot.
 *
 *    @luatreturn number Relative velocity.
 * @luafunc relvel
 */
static int aiL_relvel( lua_State *L )
{
   double dot, mod;
   Pilot *p;
   Vector2d vv, pv;
   int absolute;

   p = luaL_validpilot(L,1);

   if (lua_gettop(L) > 1)
      absolute = lua_toboolean(L,2);
   else
      absolute = 0;

   /* Get the projection of target on current velocity. */
   if (absolute == 0)
      vect_cset( &vv, p->solid->vel.x - cur_pilot->solid->vel.x,
            p->solid->vel.y - cur_pilot->solid->vel.y );
   else
      vect_cset( &vv, p->solid->vel.x, p->solid->vel.y);

   vect_cset( &pv, p->solid->pos.x - cur_pilot->solid->pos.x,
         p->solid->pos.y - cur_pilot->solid->pos.y );
   dot = vect_dot( &pv, &vv );
   mod = MAX(VMOD(pv), 1.); /* Avoid /0. */

   lua_pushnumber(L, dot / mod );
   return 1;
}

/**
 * @brief Computes the point to face in order to
 *        follow an other pilot using a PD controller.
 *
 *    @luatparam Pilot target The pilot to follow
 *    @luatparam number radius The requested distance between p and target
 *    @luatparam number angle The requested angle between p and target
 *    @luatparam number Kp The first controller parameter
 *    @luatparam number Kd The second controller parameter
 *    @luatparam[opt] string method Method to compute goal angle
 *    @luareturn The point to go to as a vector2.
 * @luafunc follow_accurate
 */
static int aiL_follow_accurate( lua_State *L )
{
   Vector2d point, cons, goal, pv;
   double radius, angle, Kp, Kd, angle2;
   Pilot *p, *target;
   const char *method;

   p = cur_pilot;
   target = luaL_validpilot(L,1);
   radius = luaL_checklong(L,2);
   angle = luaL_checklong(L,3);
   Kp = luaL_checklong(L,4);
   Kd = luaL_checklong(L,5);

   if (lua_isnoneornil(L, 6))
      method = "velocity";
   else
      method = luaL_checkstring(L,6);

   if (strcmp( method, "absolute" ) == 0)
      angle2 = angle * M_PI/180;
   else if (strcmp( method, "keepangle" ) == 0) {
      vect_cset( &pv, p->solid->pos.x - target->solid->pos.x,
            p->solid->pos.y - target->solid->pos.y );
      angle2 = VANGLE(pv);
      }
   else /* method == "velocity" */
      angle2 = angle * M_PI/180 + VANGLE( target->solid->vel );

   vect_cset( &point, VX(target->solid->pos) + radius * cos(angle2),
         VY(target->solid->pos) + radius * sin(angle2) );

   /*  Compute the direction using a pd controller */
   vect_cset( &cons, (point.x - p->solid->pos.x) * Kp +
         (target->solid->vel.x - p->solid->vel.x) *Kd,
         (point.y - p->solid->pos.y) * Kp +
         (target->solid->vel.y - p->solid->vel.y) *Kd );

   vect_cset( &goal, cons.x + p->solid->pos.x, cons.y + p->solid->pos.y);

   /* Push info */
   lua_pushvector( L, goal );

   return 1;

}


/**
 * @brief Computes the point to face in order to follow a moving object.
 *
 *    @luatparam vec2 pos The objective vector
 *    @luatparam vec2 vel The objective velocity
 *    @luatparam number radius The requested distance between p and target
 *    @luatparam number angle The requested angle between p and target
 *    @luatparam number Kp The first controller parameter
 *    @luatparam number Kd The second controller parameter
 *    @luareturn The point to go to as a vector2.
 * @luafunc face_accurate
 */
static int aiL_face_accurate( lua_State *L )
{
   Vector2d point, cons, goal, *pos, *vel;
   double radius, angle, Kp, Kd, angle2;
   Pilot *p;

   p = cur_pilot;
   pos = lua_tovector(L,1);
   vel = lua_tovector(L,2);
   radius = luaL_checklong(L,3);
   angle = luaL_checklong(L,4);
   Kp = luaL_checklong(L,5);
   Kd = luaL_checklong(L,6);

   angle2 = angle * M_PI/180;

   vect_cset( &point, pos->x + radius * cos(angle2),
         pos->y + radius * sin(angle2) );

   /*  Compute the direction using a pd controller */
   vect_cset( &cons, (point.x - p->solid->pos.x) * Kp +
         (vel->x - p->solid->vel.x) *Kd,
         (point.y - p->solid->pos.y) * Kp +
         (vel->y - p->solid->vel.y) *Kd );

   vect_cset( &goal, cons.x + p->solid->pos.x, cons.y + p->solid->pos.y);

   /* Push info */
   lua_pushvector( L, goal );

   return 1;

}


/**
 * @brief Completely stops the pilot if it is below minimum vel error (no insta-stops).
 *
 *    @luafunc stop
 */
static int aiL_stop( lua_State *L )
{
   (void) L; /* avoid gcc warning */

   if (VMOD(cur_pilot->solid->vel) < MIN_VEL_ERR)
      vect_pset( &cur_pilot->solid->vel, 0., 0. );

   return 0;
}

/**
 * @brief Docks the ship.
 *
 *    @luatparam Pilot target Pilot to dock with.
 *    @luafunc dock
 */
static int aiL_dock( lua_State *L )
{
   Pilot *p;

   /* Target is another ship. */
   p = luaL_validpilot(L,1);
   pilot_dock(cur_pilot, p);

   return 0;
}


/**
 * @brief Sets the combat flag.
 *
 *    @luatparam[opt=true] boolean val Value to set flag to.
 *    @luafunc combat
 */
static int aiL_combat( lua_State *L )
{
   int i;

   if (lua_gettop(L) > 0) {
      i = lua_toboolean(L,1);
      if (i==1) pilot_setFlag(cur_pilot, PILOT_COMBAT);
      else if (i==0) pilot_rmFlag(cur_pilot, PILOT_COMBAT);
   }
   else pilot_setFlag(cur_pilot, PILOT_COMBAT);

   return 0;
}


/**
 * @brief Sets the pilot's target.
 *
 *    @luaparam target Pilot to target.
 *    @luafunc settarget
 */
static int aiL_settarget( lua_State *L )
{
   Pilot *p;
   p = luaL_validpilot(L,1);
   pilot_setTarget( cur_pilot, p->id );
   return 0;
}


/**
 * @brief Sets the pilot's asteroid target.
 *
 *    @luaparam int field Id of the field to target.
 *    @luaparam int ast Id of the asteroid to target.
 *    @luafunc setasterotarget
 */
static int aiL_setasterotarget( lua_State *L )
{
   int field, ast;

   field = lua_tointeger(L,1);
   ast   = lua_tointeger(L,2);

   cur_pilot->nav_anchor = field;
   cur_pilot->nav_asteroid = ast;

   /* Untarget pilot. */
   cur_pilot->target = cur_pilot->id;

   return 0;
}


/**
 * @brief Gets the closest gatherable within a radius.
 *
 *    @luaparam float rad Radius to search in.
 *    @luareturn int i Id of the gatherable or nil if none found.
 *    @luafunc getgatherable
 */
static int aiL_getGatherable( lua_State *L )
{
   int i;
   double rad;

   if ((lua_gettop(L) < 1) || lua_isnil(L,1))
      rad = INFINITY;
   else
      rad = lua_tonumber(L,1);

   i = gatherable_getClosest( cur_pilot->solid->pos, rad );

   if (i != -1)
      lua_pushnumber(L,i);
   else
      lua_pushnil(L);

   return 1;
}


/**
 * @brief Gets the pos and vel of a given gatherable.
 *
 *    @luaparam int id Id of the gatherable.
 *    @luareturn vec2 pos position of the gatherable.
 *    @luareturn vec2 vel velocity of the gatherable.
 *    @luafunc gatherablepos
 */
static int aiL_gatherablePos( lua_State *L )
{
   int i, did;
   Vector2d pos, vel;

   i = lua_tointeger(L,1);

   did = gatherable_getPos( &pos, &vel, i );

   if (did == 0) /* No gatherable matching this ID. */
      return 0;

   lua_pushvector(L, pos);
   lua_pushvector(L, vel);

   return 2;
}


/**
 * @brief Triggers a weapon set.
 *
 * This will set the active weapon set, fire the weapon set if that
 * weapon set is instant mode, or activate the outfits in the weapon set
 * if the weapon set is for activatable outfits.
 *
 * In addition to the exact weapon set ID, certain special named weapon
 * sets (defined in C) are available. These are:<br/>
 *
 * <ul>
 *    <li>"all": The default weapon set which contains all weapons and
 *       is used for the player by default.</li>
 *    <li>"all_nonseek": Weapon set containing only all non-seekers,
 *       with forward-facing weapons set as primary and turreted weapons
 *       set as secondary.</li>
 *    <li>"forward_nonseek": Weapon set containing only forward-facing
 *       non-seekers, set as primary.</li>
 *    <li>"turret_nonseek": Weapon set containing only turreted
 *       non-seekers, set as primary.</li>
 *    <li>"all_seek": Instant mode weapon set containing only all
 *       seekers (both forward-facing and turreted).</li>
 *    <li>"turret_seek": Instant mode weapon set containing only
 *       turreted seekers.</li>
 *    <li>"fighter_bay": Instant mode weapon set containing only fighter
 *       bays.</li>
 * </ul>
 * <br/>
 *
 *    @luatparam number|string id ID of the weapon set to switch to or
 *       fire. Can also be a string identifying a special weapon set
 *       (see above).
 *    @luatparam[opt=true] boolean type true to activate, false to deactivate.
 * @luafunc weapset
 */
static int aiL_weapSet( lua_State *L )
{
   Pilot* p;
   int id, type, on, l, i;
   const char *name;
   PilotWeaponSet *ws;

   p = cur_pilot;

   if (lua_isnumber(L,1))
      id = lua_tointeger(L,1);
   else if (lua_isstring(L,1)) {
      name = lua_tostring(L,1);
      id = pilot_weapSetFromString(name);
      if (id == -1) {
         NLUA_ERROR(L, _("'%s' is not a valid weapon set name."), name);
         return 0;
      }
   }
   else {
      NLUA_INVALID_PARAMETER(L);
      return 0;
   }

   if (lua_gettop(L) > 1)
      type = lua_toboolean(L,2);
   else
      type = 1;

   ws = &p->weapon_sets[id];

   if (ws->type == WEAPSET_TYPE_ACTIVE) {
      /* Check if outfit is on */
      on = 1;
      l  = array_size(ws->slots);
      for (i=0; i<l; i++) {
         if (ws->slots[i].slot->state == PILOT_OUTFIT_OFF) {
            on = 0;
            break;
         }
      }

      /* Active weapon sets only care about keypresses. */
      /* activate */
      if (type && !on)
         pilot_weapSetPress(p, id, +1 );
      /* deactivate */
      if (!type && on)
         pilot_weapSetPress(p, id, +1 );
   }
   else {
      /* weapset type is weapon or change */
      if (type)
         pilot_weapSetPress( cur_pilot, id, +1 );
      else
         pilot_weapSetPress( cur_pilot, id, -1 );
   }
   return 0;
}


/**
 * @brief Does the pilot have cannons?
 *
 *    @luatreturn boolean True if the pilot has cannons.
 * @luafunc hascannons
 */
static int aiL_hascannons( lua_State *L )
{
   lua_pushboolean( L, cur_pilot->ncannons > 0 );
   return 1;
}


/**
 * @brief Does the pilot have turrets?
 *
 *    @luatreturn boolean True if the pilot has turrets.
 * @luafunc hasturrets
 */
static int aiL_hasturrets( lua_State *L )
{
   lua_pushboolean( L, cur_pilot->nturrets > 0 );
   return 1;
}


/**
 * @brief Does the pilot have afterburners?
 *
 *    @luatreturn boolean True if the pilot has afterburners.
 * @luafunc hasafterburners
 */
static int aiL_hasafterburner( lua_State *L )
{
   lua_pushboolean( L, cur_pilot->nafterburners > 0 );
   return 1;
}


/**
 * @brief Makes the pilot shoot
 *
 *    @luatparam[opt=false] boolean secondary Fire secondary weapons instead of primary.
 *    @luafunc shoot
 */
static int aiL_shoot( lua_State *L )
{
   /* Cooldown is similar to a ship being disabled, but the AI continues to
    * think during cooldown, and thus must not be allowed to fire weapons. */
   if (pilot_isFlag(cur_pilot, PILOT_COOLDOWN))
      return 0;

   if (lua_toboolean(L,1))
      ai_setFlag(AI_SECONDARY);
   else
      ai_setFlag(AI_PRIMARY);
   return 0;
}


/**
 * @brief Gets the nearest enemy.
 *
 *    @luatreturn Pilot|nil
 *    @luafunc getenemy
 */
static int aiL_getenemy( lua_State *L )
{
   pilotId_t id;

   id = pilot_getNearestEnemy(cur_pilot);

   if (id==0) /* No enemy found */
      return 0;

   lua_pushpilot(L, id);

   return 1;
}

/**
 * @brief Gets the nearest enemy within specified size bounds.
 *
 *  @luatparam number lb Lower size bound
 *  @luatparam number ub upper size bound
 *  @luatreturn Pilot
 *  @luafunc getenemy_size
 */
static int aiL_getenemy_size( lua_State *L )
{
   pilotId_t id;
   unsigned int LB, UB;

   NLUA_MIN_ARGS(2);

   LB = luaL_checklong(L,1);
   UB = luaL_checklong(L,2);

   if (LB > UB) {
      NLUA_ERROR(L, _("Invalid Bounds"));
      return 0;
   }

   id = pilot_getNearestEnemy_size( cur_pilot, LB, UB );

   if (id==0) /* No enemy found */
      return 0;

   lua_pushpilot(L, id);
   return 1;
}


/**
 * @brief Gets the nearest enemy within specified heuristic.
 *
 *  @luatparam number mass goal mass map (0-1)
 *  @luatparam number dps goal DPS map (0-1)
 *  @luatparam number hp goal HP map (0-1)
 *  @luatparam number range weighting for range (typically > 1)
 *  @luatreturn Pilot the best fitting target
 *  @luafunc getenemy_heuristic
 */
static int aiL_getenemy_heuristic( lua_State *L )
{

   pilotId_t id;
   double mass_factor, health_factor, damage_factor, range_factor;

   mass_factor    = luaL_checklong(L,1);
   health_factor  = luaL_checklong(L,2);
   damage_factor  = luaL_checklong(L,3);
   range_factor   = luaL_checklong(L,4);

   id = pilot_getNearestEnemy_heuristic( cur_pilot,
         mass_factor, health_factor, damage_factor, 1./range_factor );

   if (id==0) /* No enemy found */
      return 0;

   lua_pushpilot(L, id);
   return 1;
}


/**
 * @brief Sets the enemy hostile (basically notifies of an impending attack).
 *
 *    @luatparam Pilot target Pilot to set hostile.
 *    @luafunc hostile
 */
static int aiL_hostile( lua_State *L )
{
   Pilot *p;

   p = luaL_validpilot(L,1);

   if ((p->faction == FACTION_PLAYER) || (p->parent == PLAYER_ID))
      pilot_setHostile(cur_pilot);

   return 0;
}


/**
 * @brief Gets the range of a weapon.
 *
 *    @luatparam[opt] number|string id ID of the weapon set to get the range
 *       of. Can also be a string identifying a special weapon set.
 *       See ai.weapset for more information.
 *    @luatparam[opt=-1] number level Level of weapon set to get the range
 *       of (0 for primary, 1 for secondary, -1 for all).
 *    @luatreturn number The range of the weapon set.
 * @luafunc getweaprange
 */
static int aiL_getweaprange( lua_State *L )
{
   int id;
   int level;
   const char *name;

   if ((lua_gettop(L) > 0) && (!lua_isnil(L, 1))) {
      if (lua_isnumber(L, 1))
         id = lua_tointeger(L, 1);
      else if (lua_isstring(L, 1)) {
         name = lua_tostring(L, 1);
         id = pilot_weapSetFromString(name);
         if (id == -1) {
            NLUA_ERROR(L, _("'%s' is not a valid weapon set name."), name);
            return 0;
         }
      }
      else {
         NLUA_INVALID_PARAMETER(L);
         return 0;
      }
   }
   else
      id = cur_pilot->active_set;

   level = luaL_optinteger(L, 2, -1);
   lua_pushnumber(L, pilot_weapSetRange(cur_pilot, id, level));
   return 1;
}


/**
 * @brief Gets the speed of a weapon.
 *
 *    @luatparam[opt] number|string id ID of the weapon set to get the speed
 *       of. Can also be a string identifying a special weapon set.
 *       See ai.weapset for more information.
 *    @luatparam[opt=-1] number level Level of weapon set to get the speed
 *       of (0 for primary, 1 for secondary, -1 for all).
 *    @luatreturn number The speed of the weapon set.
 * @luafunc getweapspeed
 */
static int aiL_getweapspeed( lua_State *L )
{
   int id;
   int level;
   const char *name;

   if ((lua_gettop(L) > 0) && (!lua_isnil(L, 1))) {
      if (lua_isnumber(L, 1))
         id = lua_tointeger(L, 1);
      else if (lua_isstring(L, 1)) {
         name = lua_tostring(L, 1);
         id = pilot_weapSetFromString(name);
         if (id == -1) {
            NLUA_ERROR(L, _("'%s' is not a valid weapon set name."), name);
            return 0;
         }
      }
      else {
         NLUA_INVALID_PARAMETER(L);
         return 0;
      }
   }
   else
      id = cur_pilot->active_set;

   level = luaL_optinteger(L, 2, -1);
   lua_pushnumber(L, pilot_weapSetSpeed(cur_pilot, id, level));

   return 1;
}


/**
 * @brief Gets the ammo of a weapon.
 *
 *    @luatparam[opt] number|string id ID of the weapon set to get the ammo
 *       of. Can also be a string identifying a special weapon set.
 *       See ai.weapset for more information.
 *    @luatparam[opt=-1] number level Level of weapon set to get the ammo
 *       of (0 for primary, 1 for secondary, -1 for all).
 *    @luatreturn number The ammo of the weapon set.
 * @luafunc getweapammo
 */
static int aiL_getweapammo( lua_State *L )
{
   int id;
   int level;
   const char *name;

   if ((lua_gettop(L) > 0) && (!lua_isnil(L, 1))) {
      if (lua_isnumber(L, 1))
         id = lua_tointeger(L, 1);
      else if (lua_isstring(L, 1)) {
         name = lua_tostring(L, 1);
         id = pilot_weapSetFromString(name);
         if (id == -1) {
            NLUA_ERROR(L, _("'%s' is not a valid weapon set name."), name);
            return 0;
         }
      }
      else {
         NLUA_INVALID_PARAMETER(L);
         return 0;
      }
   }
   else
      id = cur_pilot->active_set;

   level = luaL_optinteger(L, 2, -1);
   lua_pushnumber(L, pilot_weapSetAmmo(cur_pilot, id, level));

   return 1;
}


/**
 * @brief Checks to see if pilot can board the target.
 *
 *    @luatparam Pilot target Target to see if pilot can board.
 *    @luatreturn boolean true if pilot can board, false if it can't.
 * @luafunc canboard
 */
static int aiL_canboard( lua_State *L )
{
   Pilot *p;

   /* Get parameters. */
   p = luaL_validpilot(L, 1);

   /* Must be disabled. */
   if (!pilot_isDisabled(p)) {
      lua_pushboolean(L, 0);
      return 1;
   }

   /* Check if can be boarded. */
   lua_pushboolean(L, !pilot_isFlag(p, PILOT_BOARDED));
   return 1;
}

/**
 * @brief Gets the relative size (ship mass) between the current pilot and the specified target.
 *
 *    @luatparam Pilot target The pilot whose mass we will compare.
 *    @luatreturn number A number from 0 to 1 mapping the relative masses.
 * @luafunc relsize
 */
static int aiL_relsize( lua_State *L )
{
   Pilot *p;

   /* Get the pilot. */
   p = luaL_validpilot(L,1);

   lua_pushnumber(L, pilot_relsize(cur_pilot, p));

   return 1;
}


/**
 * @brief Gets the relative damage output (total DPS) between the current pilot and the specified target.
 *
 *    @luatparam Pilot target The pilot whose DPS we will compare.
 *    @luatreturn number A number from 0 to 1 mapping the relative DPSes.
 * @luafunc reldps
 */
static int aiL_reldps( lua_State *L )
{
   Pilot *p;

   /* Get the pilot. */
   p = luaL_validpilot(L,1);

   lua_pushnumber(L, pilot_reldps(cur_pilot, p));

   return 1;
}


/**
 * @brief Gets the relative health (total shields and armour) between the current pilot and the specified target
 *
 *    @luatparam Pilot target The pilot whose health we will compare.
 *    @luatreturn number A number from 0 to 1 mapping the relative healths.
 *    @luafunc relhp
 */
static int aiL_relhp( lua_State *L )
{
   Pilot *p;

   /* Get the pilot. */
   p = luaL_validpilot(L,1);

   lua_pushnumber(L, pilot_relhp(cur_pilot, p));

   return 1;
}



/**
 * @brief Attempts to board the pilot's target.
 *
 *    @luatreturn boolean true if was able to board the target.
 *    @luafunc board
 */
static int aiL_board( lua_State *L )
{
   lua_pushboolean(L, pilot_board( cur_pilot ));
   return 1;
}


/**
 * @brief Attempts to refuel the pilot's target.
 *
 *    @luatreturn boolean true if pilot has begun refueling, false if it hasn't.
 *    @luafunc refuel
 */
static int aiL_refuel( lua_State *L )
{
   lua_pushboolean(L,pilot_refuelStart(cur_pilot));
   return 1;
}


/**
 * @brief Sets a timer.
 *
 *    @luatparam number timer Timer number.
 *    @luatparam[opt=0] number time Number of seconds to set timer to.
 *    @luafunc settimer
 */
static int aiL_settimer( lua_State *L )
{
   int n;

   /* Get parameters. */
   n = luaL_checkint(L,1);

   /* Set timer. */
   cur_pilot->timer[n] = (lua_isnumber(L,2)) ? lua_tonumber(L,2) : 0.;

   return 0;
}


/**
 * @brief Checks a timer.
 *
 *    @luatparam number timer Timer number.
 *    @luatreturn boolean Whether time is up.
 *    @luafunc timeup
 */

static int aiL_timeup( lua_State *L )
{
   int n;

   /* Get parameters. */
   n = luaL_checkint(L,1);

   lua_pushboolean(L, cur_pilot->timer[n] < 0.);
   return 1;
}


/**
 * @brief Set the seeker shoot indicator.
 *
 *    @luatparam boolean value to set the shoot indicator to.
 *    @luafunc set_shoot_indicator
 */
static int aiL_set_shoot_indicator( lua_State *L )
{
   cur_pilot->shoot_indicator = lua_toboolean(L,1);
   return 0;
}


/**
 * @brief Access the seeker shoot indicator (that is put to true each time a seeker is shot).
 *
 *    @luatreturn boolean true if the shoot_indicator is true.
 *    @luafunc set_shoot_indicator
 */
static int aiL_shoot_indicator( lua_State *L )
{
   lua_pushboolean(L, cur_pilot->shoot_indicator);
   return 1;
}


/**
 * @brief Sends a distress signal.
 *
 *    @luatparam[opt] string msg Message to send.
 *    @luafunc distress
 */
static int aiL_distress( lua_State *L )
{
   if (lua_isstring(L,1))
      snprintf( aiL_distressmsg, sizeof(aiL_distressmsg), "%s", lua_tostring(L,1) );
   else if (lua_isnil(L,1))
      aiL_distressmsg[0] = '\0';
   else
      NLUA_INVALID_PARAMETER(L);

   /* Set flag because code isn't reentrant. */
   ai_setFlag(AI_DISTRESS);

   return 0;
}


/**
 * @brief Picks a pilot that will command the current pilot.
 *
 *    @luatreturn Pilot|nil
 *    @luafunc getBoss
 */
static int aiL_getBoss( lua_State *L )
{
   pilotId_t id;

   id = pilot_getBoss( cur_pilot );

   if (id==0) /* No boss found */
      return 0;

   lua_pushpilot(L, id);

   return 1;
}

/**
 * @brief Sets the pilots credits. Only call in create().
 *
 *    @luatparam number num Number of credits.
 *    @luafunc setcredits
 */
static int aiL_credits( lua_State *L )
{
   if (aiL_status != AI_STATUS_CREATE) {
      /*NLUA_ERROR(L, "This function must be called in \"create\" only.");*/
      return 0;
   }

   cur_pilot->credits = luaL_checklong(L,1);

   return 0;
}


/**
 * @brief Returns and clears the pilots message queue.
 *
 *    @luafunc messages
 *    @luatreturn {{},...} Messages.
 */
static int aiL_messages( lua_State *L )
{
   lua_rawgeti(L, LUA_REGISTRYINDEX, cur_pilot->messages);
   lua_newtable(naevL);
   lua_rawseti(L, LUA_REGISTRYINDEX, cur_pilot->messages);
   return 1;
}

/**
 * @}
 */
