/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef HOOK_H
#  define HOOK_H


#include "mission.h"
#include "nlua_faction.h"
#include "nlua_jump.h"
#include "nlua_pilot.h"
#include "nlua_planet.h"


#define HOOK_MAX_PARAM  4 /**< Maximum hook params, to avoid dynamic allocation. */


/**
 * @brief The hook parameter types.
 */
typedef enum HookParamType_e {
   HOOK_PARAM_NIL, /**< No hook parameter. */
   HOOK_PARAM_NUMBER, /**< Number parameter. */
   HOOK_PARAM_STRING, /**< String parameter. */
   HOOK_PARAM_BOOL, /**< Boolean parameter. */
   HOOK_PARAM_PILOT, /**< Pilot hook parameter. */
   HOOK_PARAM_FACTION, /**< Faction hook parameter. */
   HOOK_PARAM_ASSET, /**< Asset hook parameter. */
   HOOK_PARAM_JUMP, /**< Jump point hook parameter. */
   HOOK_PARAM_SENTINEL /**< Enum sentinel. */
} HookParamType;

/**
 * @brief The actual hook parameter.
 */
typedef struct HookParam_s {
   HookParamType type; /**< Type of parameter. */
   union {
      double num; /**< Number parameter. */
      const char *str; /**< String parameter. */
      int b; /**< Boolean parameter. */
      LuaPilot lp; /**< Hook parameter pilot data. */
      LuaFaction lf; /**< Hook parameter faction data. */
      LuaPlanet la; /**< Hook parameter planet data. */
      LuaJump lj; /**< Hook parameter jump data. */
   } u; /**< Hook parameter data. */
} HookParam;

/*
 * Exclusion.
 */
void hook_exclusionStart (void);
void hook_exclusionEnd( double dt );

/* add/run hooks */
unsigned long hook_addMisn( unsigned long parent, const char *func, const char *stack );
unsigned long hook_addEvent( unsigned long parent, const char *func, const char *stack );
unsigned long hook_addFunc(int (*func)(void*), void *data, const char *stack);
void hook_rm( unsigned long id );
void hook_rmMisnParent( unsigned long parent );
void hook_rmEventParent( unsigned long parent );
int hook_hasMisnParent( unsigned long parent );
int hook_hasEventParent( unsigned long parent );

/* pilot hook. */
int pilot_runHookParam( Pilot* p, int hook_type, HookParam *param, int nparam );

nlua_env hook_env( unsigned long hook );

/*
 * run hooks
 *
 * Currently used:
 *  - General
 *    - "safe" - Runs once each frame at a same time (last in the frame), good place to do breaking stuff.
 *    - "takeoff" - When taking off
 *    - "jumpin" - When player jumps (after changing system)
 *    - "jumpout" - When player jumps (before changing system)
 *    - "time" - When time is increment drastically (hyperspace and taking off)
 *    - "hail" - When any pilot is hailed
 *    - "board" - When any pilot is boarded
 *    - "input" - When an input command is pressed
 *    - "standing" - Whenever faction changes.
 *    - "load" - Run on load.
 *    - "discover" - When something is discovered.
 *    - "pay" - When player receives or loses money.
 *  - Landing
 *    - "land" - When landed
 *    - "outfits" - When visited outfitter
 *    - "shipyard" - When visited shipyard
 *    - "bar" - When visited bar
 *    - "mission" - When visited mission computer
 *    - "commodity" - When visited commodity exchange
 *    - "equipment" - When visiting equipment place < br/>
 */
int hooks_runParamDeferred( const char* stack, HookParam *param );
int hooks_runParam( const char* stack, HookParam *param );
int hooks_run( const char* stack );
int hook_runIDparam( unsigned long id, HookParam *param );
int hook_runID( unsigned long id ); /* runs hook of specific id */

/* destroys hooks */
void hook_cleanup (void);

/* Timer hooks. */
void hooks_update( double dt );
unsigned long hook_addTimerMisn( unsigned long parent, const char *func, double ms );
unsigned long hook_addTimerEvt( unsigned long parent, const char *func, double ms );

/* Date hooks. */
void hooks_updateDate( ntime_t change );
unsigned long hook_addDateMisn( unsigned long parent, const char *func, ntime_t resolution );
unsigned long hook_addDateEvt( unsigned long parent, const char *func, ntime_t resolution );


#endif /* HOOK_H */

