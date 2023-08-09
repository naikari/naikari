/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file nlua_hook.c
 *
 * @brief Lua hook module.
 */


/** @cond */
#include <lauxlib.h>
#include <lua.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "nlua_hook.h"

#include "event.h"
#include "hook.h"
#include "log.h"
#include "mission.h"
#include "nlua_evt.h"
#include "nlua_misn.h"
#include "nlua_pilot.h"
#include "nlua_time.h"
#include "nluadef.h"
#include "nstring.h"


/* Hook methods. */
static int hookL_rm( lua_State *L );
static int hook_load( lua_State *L );
static int hook_land( lua_State *L );
static int hook_takeoff( lua_State *L );
static int hook_jumpout( lua_State *L );
static int hook_jumpin( lua_State *L );
static int hook_enter( lua_State *L );
static int hook_hail( lua_State *L );
static int hook_death(lua_State *L);
static int hookL_attacked(lua_State *L);
static int hook_board( lua_State *L );
static int hook_timer( lua_State *L );
static int hook_date( lua_State *L );
static int hook_commbuy( lua_State *L );
static int hook_commsell( lua_State *L );
static int hook_gather( lua_State *L );
static int hook_outfitbuy( lua_State *L );
static int hook_outfitsell( lua_State *L );
static int hook_shipbuy( lua_State *L );
static int hook_shipsell( lua_State *L );
static int hook_input( lua_State *L );
static int hook_mouse( lua_State *L );
static int hook_safe( lua_State *L );
static int hook_update( lua_State *L );
static int hook_renderbg( lua_State *L );
static int hook_renderfg( lua_State *L );
static int hook_standing( lua_State *L );
static int hook_discover( lua_State *L );
static int hook_pay( lua_State *L );
static int hook_custom( lua_State *L );
static int hook_pilot( lua_State *L );
static const luaL_Reg hook_methods[] = {
   {"rm", hookL_rm},
   {"load", hook_load},
   {"land", hook_land},
   {"takeoff", hook_takeoff},
   {"jumpout", hook_jumpout},
   {"jumpin", hook_jumpin},
   {"enter", hook_enter},
   {"hail", hook_hail},
   {"death", hook_death},
   {"attacked", hookL_attacked},
   {"board", hook_board},
   {"timer", hook_timer},
   {"date", hook_date},
   {"comm_buy", hook_commbuy},
   {"gather", hook_gather},
   {"comm_sell", hook_commsell},
   {"outfit_buy", hook_outfitbuy},
   {"outfit_sell", hook_outfitsell},
   {"ship_buy", hook_shipbuy},
   {"ship_sell", hook_shipsell},
   {"input", hook_input},
   {"mouse", hook_mouse},
   {"safe", hook_safe},
   {"update", hook_update},
   {"renderbg", hook_renderbg},
   {"renderfg", hook_renderfg},
   {"standing", hook_standing},
   {"discover", hook_discover},
   {"pay", hook_pay},
   {"custom", hook_custom},
   {"pilot", hook_pilot},
   {0,0}
}; /**< Hook Lua methods. */


/*
 * Prototypes.
 */
static int hookL_setarg( unsigned long hook, int ind );
static unsigned long hook_generic( lua_State *L, const char* stack, double ms, int pos, ntime_t date );


/**
 * @brief Loads the hook Lua library.
 *    @param env Lua environment.
 *    @return 0 on success.
 */
int nlua_loadHook( nlua_env env )
{
   nlua_register(env, "hook", hook_methods, 0);
   return 0;
}


/**
 * @brief Lua bindings to manipulate hooks.
 *
 * Hooks allow you to trigger functions to certain actions like when the
 * player jumps or a pilot dies.
 *
 * The function an action is hooked to is passed a list of hook
 * parameter arguments, plus an optional argument. The hook parameters
 * (and how many hook parameters there are) vary by the type of action
 * being hooked.
 *
 * Example usage would be:
 * @code
 * function player_board(target, arg)
 *    -- Causes the player to get paid any time they board a ship from
 *    -- the faction specified by the optional argument.
 *    if target:faction() == arg then
 *       player.pay(10000)
 *    end
 * end
 *
 * -- Hooks the function, specifying the Pirate faction as the optional
 * -- argument.
 * hookid = hook.board("player_board", faction.get("Pirate"))
 * @endcode
 *
 * @luamod hook
 */


/**
 * @brief Removes a hook previously created.
 *
 * @usage hook.rm( h ) -- Hook is removed
 *
 *    @luatparam number h Identifier of the hook to remove.
 * @luafunc rm
 */
static int hookL_rm( lua_State *L )
{
   long h;

   /* Remove the hook. */
   h = luaL_optlong( L, 1, -1 );
   /* ... Or do a no-op if caller passes nil. */
   if (h < 0)
      return 0;
   hook_rm((unsigned long)h);

   /* Clean up hook data. */
   nlua_getenv(__NLUA_CURENV, "__hook_arg");
   if (!lua_isnil(L,-1)) {
      lua_pushnumber( L, h ); /* t, n */
      lua_pushnil( L );       /* t, n, nil */
      lua_settable( L, -3 );  /* t */
   }
   lua_pop( L, 1 );        /* */

   return 0;
}


/**
 * @brief Sets a Lua argument for a hook.
 *
 *    @param hook Hook to set argument for.
 *    @param ind Index of argument to set.
 *    @return 0 on success.
 */
static int hookL_setarg( unsigned long hook, int ind )
{
   nlua_env env = hook_env(hook);

   /* If a table set __save, this won't work for tables of tables however. */
   if (lua_istable(naevL, ind)) {
      lua_pushboolean( naevL, 1 );/* b */
      lua_setfield( naevL, ind, "__save" ); /* v */
   }

   /* Create if necessary the actual hook argument table. */
   nlua_getenv(env, "__hook_arg");  /* t */
   if (lua_isnil(naevL,-1)) {       /* nil */
      lua_pop( naevL, 1 );          /* */
      lua_newtable( naevL );        /* t */
      lua_pushvalue( naevL, -1 );   /* t, t */
      nlua_setenv(env, "__hook_arg");/*t */
      lua_pushboolean( naevL, 1 );  /* t, s */
      lua_setfield( naevL, -2, "__save" );/* t */
   }
   lua_pushnumber( naevL, hook ); /* t, k */
   lua_pushvalue( naevL, ind );   /* t, k, v */
   lua_settable( naevL, -3 );     /* t */
   lua_pop( naevL, 1 );           /* */
   return 0;
}


/**
 * @brief Unsets a Lua argument.
 */
void hookL_unsetarg( unsigned long hook )
{
   nlua_env env = hook_env(hook);

   if (env == LUA_NOREF)
       return;

   nlua_getenv(env, "__hook_arg"); /* t */
   if (!lua_isnil(naevL,-1)) {
      lua_pushnumber( naevL, hook );      /* t, h */
      lua_pushnil( naevL );               /* t, h, n */
      lua_settable( naevL, -3 );          /* t */
   }
   lua_pop( naevL, 1 );
}


/**
 * @brief Gets a Lua argument for a hook.
 *
 *    @param hook Hook to get argument of.
 *    @return 0 on success.
 */
int hookL_getarg( unsigned long hook )
{
   nlua_env env = hook_env(hook);

   if (env == LUA_NOREF) {
       lua_pushnil(naevL);
       return 0;
   }

   nlua_getenv(env, "__hook_arg"); /* t */
   if (!lua_isnil(naevL,-1)) {    /* t */
      lua_pushnumber( naevL, hook ); /* t, k */
      lua_gettable( naevL, -2 );  /* t, v */
      lua_remove( naevL, -2 );    /* v */
   }
   return 0;
}


/**
 * @brief Creates a mission hook to a certain stack.
 *
 * Basically a generic approach to hooking.
 *
 *    @param L Lua state.
 *    @param stack Stack to put the hook in.
 *    @param sec Seconds to delay (pass stack as NULL to set as timer).
 *    @param pos Position in the stack of the function name.
 *    @param date Resolution of the timer. (If passed, create a date-based hook.)
 *    @return The hook ID or 0 on error.
 */
static unsigned long hook_generic( lua_State *L, const char* stack, double sec, int pos, ntime_t date )
{
   int i;
   const char *func;
   unsigned long h;
   Event_t *running_event;
   Mission *running_mission;

   /* Last parameter must be function to hook */
   func = luaL_checkstring(L,pos);

   /* Get stuff. */
   running_event = event_getFromLua(L);
   running_mission = misn_getFromLua(L);

   if (running_mission != NULL) {
      /* make sure mission is a player mission */
      for (i=0; i<MISSION_MAX; i++)
         if (player_missions[i]->id == running_mission->id)
            break;
      if (i>=MISSION_MAX) {
         WARN(_("Mission not in stack trying to hook, forgot to run misn.accept()?"));
         return 0;
      }

      if (stack != NULL)
         h = hook_addMisn( running_mission->id, func, stack );
      else if (date != 0)
         h = hook_addDateMisn( running_mission->id, func, date );
      else
         h = hook_addTimerMisn( running_mission->id, func, sec );
   }
   else if (running_event != NULL) {
      if (stack != NULL)
         h = hook_addEvent( running_event->id, func, stack );
      else if (date != 0)
         h = hook_addDateEvt( running_event->id, func, date );
      else
         h = hook_addTimerEvt( running_event->id, func, sec );
   }
   else {
      NLUA_ERROR(L,_("Attempting to set a hook outside of a mission or event."));
      return 0;
   }

   if (h == 0) {
      NLUA_ERROR(L,_("No hook target was set."));
      return 0;
   }

   /* Check parameter. */
   if (!lua_isnoneornil(L,pos+1))
      hookL_setarg( h, pos+1 );

   return h;
}
/**
 * @brief Hooks the function to the player landing.
 *
 * Can also be used to hook the various subparts of the landing menu.
 * Possible targets for where are:
 *
 * <ul>
 *    <li>"land": when landing (default with no parameter)</li>
 *    <li>"outfits": when visiting outfitter</li>
 *    <li>"shipyard": when visiting shipyard</li>
 *    <li>"bar": when visiting bar</li>
 *    <li>"mission": when visiting mission computer</li>
 *    <li>"commodity": when visiting commodity exchange</li>
 *    <li>"equipment": when visiting equipment screen</li>
 * </ul>
 *
 * The hook receives only the optional argument.
 *
 * @usage hook.land( "my_function" ) -- Land calls my_function
 * @usage hook.land( "my_function", "equipment" ) -- Calls my_function at equipment screen
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luatparam[opt] string where Where to hook the function.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc land
 */
static int hook_land( lua_State *L )
{
   const char *where;
   unsigned long h;

   if (lua_gettop(L) < 2)
      h = hook_generic( L, "land", 0., 1, 0 );
   else {
      where = luaL_checkstring(L, 2);
      h = hook_generic( L, where, 0., 1, 0 );
   }

   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player loading the game (starts landed).
 *
 * The hook receives only the optional argument.
 *
 * @usage hook.load( "my_function" ) -- Load calls my_function
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc load
 */
static int hook_load( lua_State *L )
{
   unsigned long h;
   h = hook_generic( L, "load", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player taking off.
 *
 * The hook receives only the optional argument.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc takeoff
 */
static int hook_takeoff( lua_State *L )
{
   unsigned long h = hook_generic( L, "takeoff", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player jumping (before changing systems).
 *
 * The hook receives only the optional argument.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc jumpout
 */
static int hook_jumpout( lua_State *L )
{
   unsigned long h = hook_generic( L, "jumpout", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player jumping (after changing systems).
 *
 * The hook receives only the optional argument.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc jumpin
 */
static int hook_jumpin( lua_State *L )
{
   unsigned long h = hook_generic( L, "jumpin", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player entering a system (triggers when taking
 *  off too).
 *
 * The hook receives only the optional argument.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc enter
 */
static int hook_enter( lua_State *L )
{
   unsigned long h = hook_generic( L, "enter", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player hailing any ship (not a planet).
 *
 * Hook parameter is the ship being hailed.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc hail
 */
static int hook_hail( lua_State *L )
{
   unsigned long h = hook_generic( L, "hail", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to any pilot dying.
 *
 * Hook parameters are the pilot that died, and pilot that killed them
 * (or nil if not killed by a pilot).
 *
 *    @luatparam string funcname Name of function to run when hook is
 *       triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc death
 */
static int hook_death(lua_State *L)
{
   unsigned long h = hook_generic(L, "death", 0., 1, 0);
   lua_pushnumber(L, h);
   return 1;
}
/**
 * @brief Hooks the function to any pilot getting attacked.
 *
 * Hook parameters are the pilot that was attacked, the attacking pilot
 * (or nil if not attacked by a pilot), and the damage inflicted.
 *
 *    @luatparam string funcname Name of function to run when hook is
 *       triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc attacked
 */
static int hookL_attacked(lua_State *L)
{
   unsigned long h = hook_generic(L, "attacked", 0., 1, 0);
   lua_pushnumber(L, h);
   return 1;
}
/**
 * @brief Hooks the function to the player boarding any ship.
 *
 * Hook parameter is the ship being boarded.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc board
 */
static int hook_board( lua_State *L )
{
   unsigned long h = hook_generic( L, "board", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks a timer.
 *
 * The hook receives only the optional argument.
 *
 *    @luatparam number s Seconds to delay.
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc timer
 */
static int hook_timer( lua_State *L )
{
   double s       = luaL_checknumber( L, 1 );
   unsigned long h = hook_generic( L, NULL, s, 2, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks a date change with custom resolution.
 *
 * The hook receives only the optional argument.
 *
 * @usage hook.date( time.create( 0, 0, 1000 ), "some_func", nil ) -- Hooks with a 1000 second resolution
 *
 *    @luatparam Time resolution Resolution of the timer (should be a time structure).
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc date
 */
static int hook_date( lua_State *L )
{
   ntime_t t      = luaL_validtime( L, 1 );
   unsigned long h = hook_generic( L, NULL, 0., 2, t );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player buying any sort of commodity.
 *
 * Hook parameter is the raw (untranslated) name of the commodity and
 * the quantity being bought.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc comm_buy
 */
static int hook_commbuy( lua_State *L )
{
   unsigned long h = hook_generic( L, "comm_buy", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player selling any sort of commodity.
 *
 * Hook parameter is the raw (untranslated) name of the commodity and
 * the quantity being bought.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc comm_sell
 */
static int hook_commsell( lua_State *L )
{
   unsigned long h = hook_generic( L, "comm_sell", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player gatehring any sort of commodity in space.
 *
 * Hook parameter is the raw (untranslated) name of the commodity and
 * the quantity being gathered.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc gather
 */
static int hook_gather( lua_State *L )
{
   unsigned long h = hook_generic( L, "gather", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player buying any sort of outfit.
 *
 * Hook parameter is the raw (untranslated) name of the outfit and the
 * quantity being bought.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc outfit_buy
 */
static int hook_outfitbuy( lua_State *L )
{
   unsigned long h = hook_generic( L, "outfit_buy", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player selling any sort of outfit.
 *
 * Hook parameter is the raw (untranslated) name of the outfit and the
 * quantity being sold.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc outfit_sell
 */
static int hook_outfitsell( lua_State *L )
{
   unsigned long h = hook_generic( L, "outfit_sell", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player buying any sort of ship.
 *
 * Hook parameter is the raw (untranslated) name of the ship type
 * bought.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc ship_buy
 */
static int hook_shipbuy( lua_State *L )
{
   unsigned long h = hook_generic( L, "ship_buy", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player selling any sort of ship.
 *
 * Hook parameter is the raw (untranslated) name of the ship type sold
 * and the player-given name of the ship.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc ship_sell
 */
static int hook_shipsell( lua_State *L )
{
   unsigned long h = hook_generic( L, "ship_sell", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player pressing or releasing any input.
 *
 * Hook parameters are the name of the key (e.g. "accel") and whether or
 * not it's a press.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc input
 */
static int hook_input( lua_State *L )
{
   unsigned long h = hook_generic( L, "input", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to the player clicking the mouse.
 *
 * Hook parameter is the button pressed:
 *
 * <ul>
 *    <li>1: left mouse button</li>
 *    <li>2: middle mouse button</li>
 *    <li>3: right mouse button</li>
 * </ul>
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc mouse
 */
static int hook_mouse( lua_State *L )
{
   unsigned long h = hook_generic( L, "mouse", 0., 1, 0 );
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to any faction standing change.
 *
 * Hook parameters are faction whose standing is being changed, the
 * change amount, and whether or not the change is secondary.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc standing
 */
static int hook_standing( lua_State *L )
{
   unsigned long h = hook_generic(L, "standing", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to when the player discovers an asset, jump point or the likes.
 *
 * The parameters passed to the function are the type which can be one of:<br/>
 * - "asset" <br/>
 * - "jump" <br/>
 * and the actual asset or jump point discovered with the following format: <br/>
 * function f( type, discovery )
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc discover
 */
static int hook_discover( lua_State *L )
{
   unsigned long h = hook_generic(L, "discover", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hooks the function to when the player receives or loses money through player.pay() (the Lua function only).
 *
 * Hook parameters are the amount paid (will be negative if it was a
 * loss of money), and the reason specified by player.pay() (nil by
 * default).
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc pay
 */
static int hook_pay( lua_State *L )
{
   unsigned long h = hook_generic(L, "pay", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hook run once at the end of the next frame.
 *
 * This hook runs once (and only once) at the end of the next frame,
 * regardless of anything that can happen, and removes itself. This is
 * a good way to do possibly breaking stuff like for example
 * player.teleport().
 *
 * The hook receives only the optional argument.
 *
 *    @luatparam string funcname Name of function to run when hook is
 *       triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luasee update
 * @luafunc safe
 */
static int hook_safe( lua_State *L )
{
   unsigned long h = hook_generic(L, "safe", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hook run at the end of each frame when the update routine is run.
 *
 * This hook is similar to hook.safe(), but you have to manually remove
 * it or it continues forever. Also, it is not run while the game is
 * paused or a modal dialog is open, whereas hook.safe() will run even
 * in those cases.
 *
 * The parameters passed to the function are the current delta-tick
 * (time passed in game) and real delta-tick (independent of game
 * status).
 *
 *    @luatparam string funcname Name of function to run when hook is
 *       triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luasee safe
 * @luafunc update
 */
static int hook_update( lua_State *L )
{
   unsigned long h = hook_generic(L, "update", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hook that runs during rendering the background (just above the static background stuff). Meant to be only for rendering things.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc renderbg
 */
static int hook_renderbg( lua_State *L )
{
   unsigned long h = hook_generic(L, "renderbg", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Hook that runs during rendering the foreground (just below the gui stuff). Meant to be only for rendering things.
 *
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc renderfg
 */
static int hook_renderfg( lua_State *L )
{
   unsigned long h = hook_generic(L, "renderfg", 0., 1, 0);
   lua_pushnumber( L, h );
   return 1;
}
/**
 * @brief Custom hook that must be manually triggered.
 *
 * Custom hooks can be used to cause missions and events to affect each
 * other. Use hook.trigger() to trigger the hook at the appropriate
 * time.
 *
 * Hook parameters (and number of hook parameters) are chosen by the
 * respective hook.trigger() call(s).
 *
 *    @luatparam string hookname Name to give the hook. This should not
 *       overlap with standard names.
 *    @luatparam string funcname Name of function to run when hook is
 *       triggered.
 *    @luaparam[opt] arg Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luasee naev.hookTrigger
 * @luafunc custom
 */
static int hook_custom( lua_State *L )
{
   const char *hookname = luaL_checkstring(L,1);
   unsigned long h = hook_generic(L, hookname, 0., 2, 0);
   lua_pushnumber( L, h );
   return 1;
}


/**
 * @brief Hooks the function to a specific pilot.
 *
 * You can hook to different actions. Currently hook system supports:
 * <ul>
 *    <li>"death": triggered when the pilot dies (before marked as
 *       dead). Hook parameters are the dying pilot and the pilot that
 *       killed them (or nil if not killed by a pilot).</li>
 *    <li>"exploded": triggered when the pilot has died and the final
 *       explosion has begun. Hook parameter is the exploded pilot.</li>
 *    <li>"kill": triggered when the pilot kills another pilot (before
 *       marked as dead). Hook parameters are the killing pilot (or nil
 *       if not killed by a pilot) and the killed pilot.</li>
 *    <li>"boarding": triggered when the pilot boards another pilot
 *       (start of boarding). Hook parameters are the boarding pilot and
 *       the pilot being boarded.</li>
 *    <li>"board": triggered when the pilot is boarded (start of
 *       boarding). Hook parameters are the pilot being boarded and the
 *       boarding pilot.</li>
 *    <li>"disable": triggered when the pilot is disabled (with disable
 *       set). Hook parameters are the disabled pilot and the pilot that
 *       disabled them (or nil if not disabled by a pilot).</li>
 *    <li>"undisable": triggered when the pilot recovers from being
 *       disabled. Hook parameter is the recovered pilot.</li>
 *    <li>"jump": triggered when the pilot jumps to hyperspace (before
 *       they actually jump out). Hook parameters are the jumping
 *       pilot and the jump point being jumped through.</li>
 *    <li>"hail": triggered when the pilot is hailed by the player. Hook
 *       parameter is the pilot being hailed.</li>
 *    <li>"land": triggered when the pilot is landing (right when
 *       starting land descent). Hook parameters are the landing
 *       pilot and the planet being landed on.</li>
 *    <li>"attacked": triggered when the pilot is attacked. Hook
 *       parameters are the attacked pilot, the attacking pilot (or nil
 *       if not attacked by a pilot), and the damage inflicted.</li>
 *    <li>"idle": triggered when the pilot becomes idle in manual
 *       control. Hook parameter is the idle pilot.</li>
 *    <li>"lockon": triggered when the pilot locked on a missile on its
 *       target. Hook parameter is the pilot which achieved the
 *       lockon.</li>
 * </ul>
 *
 * If you pass nil as pilot, it will set it as a global hook that
 * will trigger for all pilots.
 *
 * <strong>Do not do unsafe things in pilot hooks. This means stuff like
 * player.teleport(). If you have doubts, use a "safe" hook.</strong>
 *
 *    @luatparam Pilot|nil pilot Pilot identifier to hook (or nil for all).
 *    @luatparam string type One of the supported hook types.
 *    @luatparam string funcname Name of function to run when hook is triggered.
 *    @luaparam[opt] Argument to pass to hook.
 *    @luatreturn number Hook identifier.
 * @luafunc pilot
 */
static int hook_pilot( lua_State *L )
{
   unsigned long h;
   LuaPilot p;
   int type;
   const char *hook_type;
   char buf[ PATH_MAX ];

   /* Parameters. */
   if (lua_ispilot(L,1))
      p           = luaL_checkpilot(L,1);
   else if (lua_isnil(L,1))
      p           = 0;
   else {
      NLUA_ERROR(L, _("Invalid parameter #1 for hook.pilot, expecting pilot or nil."));
      return 0;
   }
   hook_type   = luaL_checkstring(L,2);

   /* Check to see if hook_type is valid */
   if (strcmp(hook_type, "death") == 0)
      type = PILOT_HOOK_DEATH;
   else if (strcmp(hook_type, "exploded") == 0)
      type = PILOT_HOOK_EXPLODED;
   else if (strcmp(hook_type, "kill") == 0)
      type = PILOT_HOOK_KILL;
   else if (strcmp(hook_type, "boarding") == 0)
      type = PILOT_HOOK_BOARDING;
   else if (strcmp(hook_type, "board") == 0)
      type = PILOT_HOOK_BOARD;
   else if (strcmp(hook_type, "disable") == 0)
      type = PILOT_HOOK_DISABLE;
   else if (strcmp(hook_type, "undisable") == 0)
      type = PILOT_HOOK_UNDISABLE;
   else if (strcmp(hook_type, "jump") == 0)
      type = PILOT_HOOK_JUMP;
   else if (strcmp(hook_type, "hail") == 0)
      type = PILOT_HOOK_HAIL;
   else if (strcmp(hook_type, "land") == 0)
      type = PILOT_HOOK_LAND;
   else if (strcmp(hook_type, "attacked") == 0)
      type = PILOT_HOOK_ATTACKED;
   else if (strcmp(hook_type, "idle") == 0)
      type = PILOT_HOOK_IDLE;
   else if (strcmp(hook_type, "lockon") == 0)
      type = PILOT_HOOK_LOCKON;
   else { /* hook_type not valid */
      NLUA_ERROR(L, _("Invalid pilot hook type: '%s'"), hook_type);
      return 0;
   }

   /* actually add the hook */
   snprintf( buf, sizeof(buf), "p_%s", hook_type );
   h = hook_generic( L, buf, 0., 3, 0 );
   if (p==0)
      pilots_addGlobalHook( type, h );
   else
      pilot_addHook( pilot_get(p), type, h );

   lua_pushnumber( L, h );
   return 1;
}
