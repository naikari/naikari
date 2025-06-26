/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file nlua_player.c
 *
 * @brief Lua player module.
 */


/** @cond */
#include <lauxlib.h>
#include <lua.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "nlua_player.h"

#include "array.h"
#include "board.h"
#include "comm.h"
#include "credits.h"
#include "event.h"
#include "gui.h"
#include "gui_omsg.h"
#include "hook.h"
#include "land.h"
#include "land_outfits.h"
#include "log.h"
#include "map.h"
#include "map_overlay.h"
#include "mission.h"
#include "nlua_col.h"
#include "nlua_outfit.h"
#include "nlua_pilot.h"
#include "nlua_planet.h"
#include "nlua_ship.h"
#include "nlua_system.h"
#include "nlua_vec2.h"
#include "nluadef.h"
#include "nstring.h"
#include "pause.h"
#include "player.h"


#define PLAYER_CHECK() if (player.p == NULL) return 0


/* Player methods. */
static int playerL_getname( lua_State *L );
static int playerL_shipname( lua_State *L );
static int playerL_pay( lua_State *L );
static int playerL_credits( lua_State *L );
static int playerL_msg( lua_State *L );
static int playerL_msgClear( lua_State *L );
static int playerL_omsgAdd( lua_State *L );
static int playerL_omsgChange( lua_State *L );
static int playerL_omsgRm( lua_State *L );
static int playerL_allowSave( lua_State *L );
/* Faction stuff. */
static int playerL_getPosition( lua_State *L );
static int playerL_getPilot( lua_State *L );
/* Fuel stuff. */
static int playerL_jumps( lua_State *L );
static int playerL_fuel( lua_State *L );
static int playerL_refuel( lua_State *L );
static int playerL_autonav( lua_State *L );
static int playerL_autonavDest( lua_State *L );
static int playerL_autonavAbort( lua_State *L );
static int playerL_autonavReset( lua_State *L );
/* Cinematics. */
static int playerL_cinematics( lua_State *L );
static int playerL_damageSPFX( lua_State *L );
static int playerL_screenshot( lua_State *L );
/* Board stuff. */
static int playerL_unboard( lua_State *L );
/* Land stuff. */
static int playerL_isLanded( lua_State *L );
static int playerL_takeoff( lua_State *L );
static int playerL_land( lua_State *L );
static int playerL_allowLand( lua_State *L );
static int playerL_landWindow( lua_State *L );
/* Hail stuff. */
static int playerL_commclose( lua_State *L );
/* Cargo stuff. */
static int playerL_ships( lua_State *L );
static int playerL_shipOutfits( lua_State *L );
static int playerL_shipOutfitAdd( lua_State *L );
static int playerL_shipOutfitRm( lua_State *L );
static int playerL_outfits( lua_State *L );
static int playerL_numOutfit( lua_State *L );
static int playerL_addOutfit( lua_State *L );
static int playerL_rmOutfit( lua_State *L );
static int playerL_addShip( lua_State *L );
static int playerL_swapShip( lua_State *L );
static int playerL_misnActive( lua_State *L );
static int playerL_misnDone( lua_State *L );
static int playerL_evtActive( lua_State *L );
static int playerL_evtDone( lua_State *L );
static int playerL_teleport( lua_State *L );
static int playerL_dt_mod( lua_State *L );
static const luaL_Reg playerL_methods[] = {
   { "name", playerL_getname },
   { "ship", playerL_shipname },
   { "pay", playerL_pay },
   { "credits", playerL_credits },
   { "msg", playerL_msg },
   { "msgClear", playerL_msgClear },
   { "omsgAdd", playerL_omsgAdd },
   { "omsgChange", playerL_omsgChange },
   { "omsgRm", playerL_omsgRm },
   { "allowSave", playerL_allowSave },
   { "pos", playerL_getPosition },
   { "pilot", playerL_getPilot },
   { "jumps", playerL_jumps },
   { "fuel", playerL_fuel },
   { "refuel", playerL_refuel },
   { "autonav", playerL_autonav },
   { "autonavDest", playerL_autonavDest },
   { "autonavAbort", playerL_autonavAbort },
   { "autonavReset", playerL_autonavReset },
   { "cinematics", playerL_cinematics },
   { "damageSPFX", playerL_damageSPFX },
   { "screenshot", playerL_screenshot },
   { "unboard", playerL_unboard },
   { "isLanded", playerL_isLanded },
   { "takeoff", playerL_takeoff },
   { "land", playerL_land },
   { "allowLand", playerL_allowLand },
   { "landWindow", playerL_landWindow },
   { "commClose", playerL_commclose },
   { "ships", playerL_ships },
   { "shipOutfits", playerL_shipOutfits },
   { "shipOutfitAdd", playerL_shipOutfitAdd },
   { "shipOutfitRm", playerL_shipOutfitRm },
   { "outfits", playerL_outfits },
   { "numOutfit", playerL_numOutfit },
   { "outfitAdd", playerL_addOutfit },
   { "outfitRm", playerL_rmOutfit },
   { "addShip", playerL_addShip },
   { "swapShip", playerL_swapShip },
   { "misnActive", playerL_misnActive },
   { "misnDone", playerL_misnDone },
   { "evtActive", playerL_evtActive },
   { "evtDone", playerL_evtDone },
   { "teleport", playerL_teleport },
   { "dt_mod", playerL_dt_mod },
   {0,0}
}; /**< Player Lua methods. */


/**
 * @brief Loads the player Lua library.
 *    @param env Lua environment.
 */
int nlua_loadPlayer( nlua_env env )
{
   nlua_register(env, "player", playerL_methods, 0);
   return 0;
}


/**
 * @brief Lua bindings to interact with the player.
 *
 * These bindings let you modify stuff about the player and find out special
 *  information. General usage would be calls like:
 * @code
 * pname = player.name()
 * shipname = player.ship()
 * @endcode
 * @luamod player
 */
/**
 * @brief Gets the player's name.
 *
 *    @luatreturn string The name of the player.
 * @luafunc name
 */
static int playerL_getname( lua_State *L )
{
   PLAYER_CHECK();
   lua_pushstring(L,player.name);
   return 1;
}
/**
 * @brief Gets the player's ship's name (given by the player).
 *
 * @note Not to be confused with getting the player's ship that can be done with player.pilot():ship().
 *
 *    @luatreturn string The name of the ship the player is currently in.
 * @luafunc ship
 */
static int playerL_shipname( lua_State *L )
{
   PLAYER_CHECK();
   lua_pushstring(L,player.p->name);
   return 1;
}
/**
 * @brief Pays the player an amount of money.
 *
 * @usage player.pay( 500 ) -- Gives player 500 credits
 *
 *    @luatparam number amount Amount of money to pay the player in credits.
 *    @luatparam[opt] string reason String value to pass to the pay hook.
 *    @luatparam[opt] boolean nohooks Set to true to not trigger pay hooks.
 * @luafunc pay
 */
static int playerL_pay( lua_State *L )
{
   HookParam p[3];
   credits_t money;
   int nohooks;
   const char *reason = NULL;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   money = CLAMP( CREDITS_MIN, CREDITS_MAX, (credits_t)round(luaL_checknumber(L,1)) );
   player_modCredits( money );
   nohooks = lua_toboolean(L,2);
   if (lua_isstring(L,3)) {
      reason = lua_tostring(L,3);
   }

   if (!nohooks) {
      p[0].type = HOOK_PARAM_NUMBER;
      p[0].u.num = (double)money;
      if (reason != NULL) {
         p[1].type = HOOK_PARAM_STRING;
         p[1].u.str = reason;
      }
      else
         p[1].type = HOOK_PARAM_NIL;
      p[2].type = HOOK_PARAM_SENTINEL;
      hooks_runParam( "pay", p );
   }

   /* Update land window so credits display can update. */
   if (landed)
      land_updateTabs();

   return 0;
}
/**
 * @brief Gets how many credits the player has on him.
 *
 * @usage monies = player.credits()
 * @usage monies, readable = player.credits( 2 )
 *
 *    @luatparam number decimal Optional argument that makes it return human readable form with so many decimals.
 *    @luatreturn number The amount of credits in numerical form.
 *    @luatreturn string The amount of credits in human-readable form.
 * @luafunc credits
 */
static int playerL_credits( lua_State *L )
{
   char buf[STRMAX_SHORT];
   int has_dec, decimals;

   PLAYER_CHECK();

   /* Parse parameters. */
   if (lua_isnumber(L,1)) {
      has_dec  = 1;
      decimals = lua_tointeger(L,1);
   }
   else
      has_dec  = 0;

   /* Push return. */
   lua_pushnumber(L, player.p->credits);
   if (has_dec) {
      credits2str(buf, sizeof(buf), player.p->credits, decimals);
      lua_pushstring(L, buf);
   }

   return 1 + has_dec;
}
/**
 * @brief Sends the player an in-game message.
 *
 *    @luatparam string message Message to send the player.
 * @luafunc msg
 */
static int playerL_msg( lua_State *L )
{
   const char* str;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   str = luaL_checkstring(L,1);
   player_messageRaw(str);

   return 0;
}
/**
 * @brief Clears the player's message buffer.
 *
 * @luafunc msgClear
 */
static int playerL_msgClear( lua_State *L )
{
   NLUA_CHECKRW(L);
   PLAYER_CHECK();
   gui_clearMessages();
   return 0;
}
/**
 * @brief Adds an overlay message.
 *
 * @usage player.omsgAdd( "some_message", 5 )
 *    @luatparam string msg Message to add.
 *    @luatparam number duration Duration to add message (if 0. is infinite).
 *    @luatparam[opt] number fontsize Size of the font to use.
 *    @luatreturn number ID of the created overlay message.
 * @luafunc omsgAdd
 */
static int playerL_omsgAdd( lua_State *L )
{
   const char *str;
   double duration;
   unsigned int id;
   int fontsize;
   const glColour *col;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   /* Input. */
   str      = luaL_checkstring(L,1);
   duration = luaL_checknumber(L,2);
   fontsize = luaL_optinteger(L,3,OMSG_FONT_DEFAULT_SIZE);
   col      = luaL_optcolour(L,4,&cWhite);

   /* Infinity. */
   if (duration < 1e-10)
      duration = INFINITY;

   /* Output. */
   id       = omsg_add( str, duration, fontsize, col );
   lua_pushnumber( L, id );
   return 1;
}
/**
 * @brief Changes an overlay message.
 *
 * @usage player.omsgChange( omsg_id, "new message", 3 )
 *    @luatparam number id ID of the overlay message to change.
 *    @luatparam string msg Message to change to.
 *    @luatparam number duration New duration to set (0. for infinity).
 *    @luatreturn boolean true if all went well, false otherwise.
 * @luafunc omsgChange
 */
static int playerL_omsgChange( lua_State *L )
{
   const char *str;
   double duration;
   unsigned int id;
   int ret;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   /* Input. */
   id       = luaL_checklong(L,1);
   str      = luaL_checkstring(L,2);
   duration = luaL_checknumber(L,3);

   /* Infinity. */
   if (duration < 1e-10)
      duration = INFINITY;

   /* Output. */
   ret      = omsg_change( id, str, duration );
   lua_pushboolean(L,!ret);
   return 1;
}
/**
 * @brief Removes an overlay message.
 *
 * @usage player.omsgRm( msg_id )
 *    @luatparam number id ID of the overlay message to remove.
 * @luafunc omsgRm
 */
static int playerL_omsgRm( lua_State *L )
{
   unsigned int id;
   NLUA_CHECKRW(L);
   PLAYER_CHECK();
   id       = luaL_checklong(L,1);
   omsg_rm( id );
   return 0;
}
/**
 * @brief Sets player save ability.
 *
 * @usage player.allowSave( b )
 *    @luatparam[opt=true] boolean b true if the player is allowed to save, false otherwise.
 * @luafunc allowSave
 */
static int playerL_allowSave( lua_State *L )
{
   unsigned int b;
   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   b = 1;
   if (lua_gettop(L) > 0)
      b = lua_toboolean(L, 1);

   if (b)
      player_rmFlag(PLAYER_NOSAVE);
   else
      player_setFlag(PLAYER_NOSAVE);

   /* Update land window main tab for the Save Snapshot button. */
   if (landed)
      land_updateTabs();

   return 0;
}

/**
 * @brief Gets the player's position.
 *
 * @usage v = player.pos()
 *
 *    @luatreturn Vec2 The position of the player.
 * @luafunc pos
 */
static int playerL_getPosition( lua_State *L )
{
   PLAYER_CHECK();
   lua_pushvector(L, player.p->solid->pos);
   return 1;
}

/**
 * @brief Gets the player's associated pilot.
 *
 *    @luatreturn Pilot The player's pilot.
 * @luafunc pilot
 */
static int playerL_getPilot( lua_State *L )
{
   /* No need to run check here or stuff that depends on player.pilot() working will fail. */
   lua_pushpilot(L, PLAYER_ID);
   return 1;
}


/**
 * @brief Gets a player's jump range based on their remaining fuel.
 *
 * @usage jumps = player.jumps()
 *
 *    @luatreturn number|nil The player's maximum number of jumps, or
 *       nil if the player has infinite jumps.
 * @luafunc jumps
 */
static int playerL_jumps( lua_State *L )
{
   int jumps;

   PLAYER_CHECK();

   jumps = pilot_getJumps(player.p);
   if (jumps == -1)
      return 0;

   lua_pushnumber(L, pilot_getJumps(player.p));
   return 1;
}


/**
 * @brief Gets the amount of fuel a player has.
 *
 * @usage fuel, consumption = player.fuel()
 *
 *    @luatreturn number The player's fuel and
 *    @luatreturn number The amount of fuel needed per jump.
 * @luafunc fuel
 */
static int playerL_fuel( lua_State *L )
{
   PLAYER_CHECK();
   lua_pushnumber(L,player.p->fuel);
   lua_pushnumber(L,player.p->fuel_consumption);
   return 2;
}


/**
 * @brief Refuels the player.
 *
 * @usage player.refuel() -- Refuel fully
 * @usage player.refuel( 200 ) -- Refuels partially
 *
 *    @luatparam[opt] number fuel Amount of fuel to add, will set to max if nil.
 * @luafunc refuel
 */
static int playerL_refuel( lua_State *L )
{
   double f;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   if (lua_gettop(L) > 0) {
      f = luaL_checknumber(L,1);
      player.p->fuel += f;
   }
   else
      player.p->fuel = player.p->fuel_max;

   /* Make sure value is valid. */
   player.p->fuel = CLAMP(0, player.p->fuel_max, player.p->fuel);

   return 0;
}


/**
 * @brief Checks to see if the player has autonav enabled.
 *
 * @usage autonav = player.autonav()
 *    @luatreturn boolean true if the player has autonav enabled.
 * @luafunc autonav
 */
static int playerL_autonav( lua_State *L )
{
   PLAYER_CHECK();
   lua_pushboolean( L, player_isFlag( PLAYER_AUTONAV ) );
   return 1;
}


/**
 * @brief Gets the player's long term autonav destination.
 *
 * @usage sys, jumps = player.autonavDest()
 *
 *    @luatreturn System|nil The destination system (or nil if none selected).
 *    @luatreturn number|nil The number of jumps left.
 * @luafunc autonavDest
 */
static int playerL_autonavDest( lua_State *L )
{
   LuaSystem ls;
   StarSystem *dest;
   int jumps;

   /* Get destination. */
   dest = map_getDestination( &jumps );
   if (dest == NULL)
      return 0;

   ls = system_index( dest );
   lua_pushsystem( L, ls );
   lua_pushnumber( L, jumps );
   return 2;
}


/**
 * @brief Stops the players autonav if active.
 *
 * @note Does not do anything if the player is not in autonav.
 *
 * @usage player.autonavAbort()
 * @usage player.autonavAbort(_("Your engines malfunctioned!"))
 *
 *    @luatparam[opt] string msg Abort message.
 * @luafunc autonavAbort
 */
static int playerL_autonavAbort( lua_State *L )
{
   const char *str = luaL_optstring(L, 1, NULL);

   /* Force-abort autonav since this is script-controlled, and we don't
    * want a script's decision to abort autonav to be overridden if the
    * player pilot is under manual control. */
   player_autonavAbort(str, 1);

   return 0;
}


/**
 * @brief Resets the game speed without disabling autonav.
 *
 * @note Does not do anything if the player is not in autonav.
 *
 * @usage
 * -- Resets speed, then immediately resumes time compression
 * player.autonavReset()
 *
 * @usage
 * -- Resets speed for 3 seconds
 * player.autonavReset(3)
 *
 *    @luatparam[opt=0] number timer How many seconds to wait before
 *       starting autonav up again.
 * @luafunc autonavReset
 */
static int playerL_autonavReset( lua_State *L )
{
   double timer = luaL_optnumber(L,1,0.);
   player_autonavResetSpeed();
   player.autonav_timer = timer;
   return 0;
}



/**
 * @brief Puts the game in cinematics mode or back to regular mode.
 *
 * Cinematics mode aborts autonav if active, forces speed to be the
 * game's base speed (unaffected by the Time Passage Rate of the ship
 * the player is flying), and hides the GUI by default. It can also
 * disable the ability of the player to speed up the game with the speed
 * key, but this is generally not recommended.<br/>
 * <br/>
 * It is important to note that this function does <em>not</em> affect
 * the player's ability to control their ship. To prevent the player
 * from doing things during cinematics, use pilot.control().<br/>
 * <br/>
 * Possible values to pass to the table of options are:<br/>
 * <ul>
 *  <li>"abort" (string): Autonav abort message.</li>
 *  <li>"no2x" (boolean): Whether to prevent the player from increasing
 *       the speed of the game. Defaults to false.</li>
 *  <li>"gui" (boolean): Whether to enable the player's gui. Defaults to
 *       false.</li>
 * </ul>
 * <br/>
 *
 * @usage
 * -- Enables cinematics without hiding the GUI, showing
 * -- "Let the show begin!" if autonav is aborted.
 * player.cinematics(true, {gui=true, abort=_("Let the show begin!")})
 *
 * @usage
 * -- Disables cinematics.
 * player.cinematics(false)
 *
 *    @luatparam[opt=true] boolean enable If true sets cinematics mode,
 *       if false disables.
 *    @luatparam[opt] table options Table of options. See above for
 *       information about what options can be passed.
 * @luasee pilot.control
 * @luasee camera.set
 * @luafunc cinematics
 */
static int playerL_cinematics( lua_State *L )
{
   int b;
   const char *abort_msg;
   int f_gui, f_2x;

   NLUA_CHECKRW(L);

   /* Defaults. */
   abort_msg = NULL;
   f_gui     = 0;
   f_2x      = 0;

   /* Parse parameters. */
   if (lua_gettop(L) >= 1)
      b = lua_toboolean(L, 1);
   else
      b = 1;

   if (lua_gettop(L) >= 2) {
      if (!lua_istable(L,2)) {
         NLUA_ERROR( L, _("Second parameter to cinematics should be a table of options or omitted!") );
         return 0;
      }

      lua_getfield( L, 2, "abort" );
      if (!lua_isnil( L, -1 ))
         abort_msg = luaL_checkstring( L, -1 );
      lua_pop( L, 1 );

      lua_getfield( L, 2, "gui" );
      f_gui = lua_toboolean(L, -1);
      lua_pop( L, 1 );

      lua_getfield( L, 2, "no2x" );
      f_2x = lua_toboolean(L, -1);
      lua_pop( L, 1 );
   }

   if (b) {
      /* Set Cinematics flag (used to ensure speeds are kept at 1x). */
      player_setFlag(PLAYER_CINEMATICS);

      /* Get rid of stuff that could be bothersome. We force-abort
       * autonav here in case the player pilot is under manual
       * control. */
      player_autonavAbort(abort_msg, 1);
      ovr_setOpen(0);

      /* Reset the player's speed. Because of the Cinematics flag, this
       * will override the ship's base speed. */
      player.speed = 1.;
      player_resetSpeed();

      /* Handle options. */
      if (!f_gui) {
         player_setFlag(PLAYER_CINEMATICS_GUI);
         gl_setDefViewport(0., 0., SCREEN_W, SCREEN_H);
      }
      if (f_2x)
         player_setFlag(PLAYER_CINEMATICS_2X);
   }
   else {
      /* Clean up flags. */
      player_rmFlag(PLAYER_CINEMATICS);
      player_rmFlag(PLAYER_CINEMATICS_GUI);
      player_rmFlag(PLAYER_CINEMATICS_2X);

      /* Reset speed properly to player speed. */
      player_resetSpeed();

      /* Reload GUI. */
      gui_reload();
   }

   return 0;
}


/**
 * @brief Applies the damage effects to the player.
 *
 *    @luatparam number mod How strong the effect should be. It should be a value between 0 and 1, usually corresponding to how much armour damage the player has taken with respect to their total armour.
 * @luafunc damageSPFX
 */
static int playerL_damageSPFX( lua_State *L )
{
   (void) L;
   return 0;
}


/**
 * @brief Takes a screenshot (same as the keyboard action).
 *
 * @luafunc screenshot
 */
static int playerL_screenshot( lua_State *L )
{
   (void) L;
   player_screenshot();
   return 0;
}


/**
 * @brief Unboards the player from its boarded target.
 *
 * Use from inside a board hook.
 *
 * @usage player.unboard()
 *
 * @luafunc unboard
 */
static int playerL_unboard( lua_State *L )
{
   (void) L;
   NLUA_CHECKRW(L);
   board_unboard();
   return 0;
}


/**
 * @brief Checks to see if the player is landed or not.
 *
 *    @luatreturn boolean Whether or not the player is currently landed.
 * @luafunc isLanded
 */
static int playerL_isLanded( lua_State *L )
{
   lua_pushboolean( L, landed );
   return 1;
}


/**
 * @brief Forces the player to take off if they are landed.
 *
 * Assume the pilot is still landed until the current running function returns
 *  If you want to create pilots on take off please hook the takeoff/land hooks.
 *
 * @luafunc takeoff
 */
static int playerL_takeoff( lua_State *L )
{
   NLUA_CHECKRW(L);

   if (!landed) {
      NLUA_ERROR(L,_("Player must be landed to force takeoff."));
      return 0;
   }

   land_queueTakeoff();

   return 0;
}


/**
 * @brief Automagically lands the player on a planet.
 *
 * Note that this will teleport the player to the system in question as necessary.
 *
 *    @luatparam Planet pnt Planet to land the player on.
 * @luafunc land
 */
static int playerL_land( lua_State *L )
{
   NLUA_CHECKRW(L);
   PLAYER_CHECK();
   Planet *pnt = luaL_validplanet(L,1);
   const char *sysname = planet_getSystem( pnt->name );
   if (sysname == NULL)
      NLUA_ERROR(L,_("Planet '%s' is not in a system!"), pnt->name);

   if (strcmp(sysname,cur_system->name) != 0) {
      /* Refer to playerL_teleport for the voodoo that happens here. */
      pilot_rmFlag( player.p, PILOT_HYPERSPACE );
      pilot_rmFlag( player.p, PILOT_HYP_BEGIN );
      pilot_rmFlag( player.p, PILOT_HYP_BRAKE );
      pilot_rmFlag( player.p, PILOT_HYP_PREP );
      player_accelOver();
      player_autonavEnd();

      space_gfxUnload( cur_system );

      player_targetClearAll();

      space_init( sysname );

      map_clear();
      map_select(map_getDestination(NULL), 0);

      player.p->solid->pos = pnt->pos;
   }
   space_queueLand( pnt );
   return 0;
}


/**
 * @brief Allows or disallows the player to land.
 *
 * This will allow or disallow landing on a system level and is reset when the
 *  player enters another system.
 *
 * @usage player.allowLand() -- Allows the player to land
 * @usage player.allowLand( false ) -- Doesn't allow the player to land.
 * @usage player.allowLand( false, "No landing." ) -- Doesn't allow the player to land with the message "No landing."
 *
 *    @luatparam[opt=true] boolean b Whether or not to allow the player to land.
 *    @luatparam[opt] string msg Message displayed when player tries to land (only if disallowed to land). Can be omitted to use default.
 * @luafunc allowLand
 */
static int playerL_allowLand( lua_State *L )
{
   int b;
   const char *str;

   NLUA_CHECKRW(L);

   str = NULL;
   if (lua_gettop(L) > 0) {
      b     = lua_toboolean(L,1);
      if (lua_isstring(L,2))
         str   = lua_tostring(L,2);
   }
   else
      b     = 1;

   if (b)
      player_rmFlag( PLAYER_NOLAND );
   else {
      player_setFlag( PLAYER_NOLAND );
      player_nolandMsg( str );
   }
   return 0;
}


/**
 * @brief Sets the active land window.
 *
 * Valid windows are:<br/>
 *  - main<br/>
 *  - bar<br/>
 *  - missions<br/>
 *  - outfits<br/>
 *  - shipyard<br/>
 *  - equipment<br/>
 *  - commodity<br/>
 *
 * @usage player.landWindow( "outfits" )
 *    @luatparam string winname Name of the window.
 *    @luatreturn boolean True on success.
 * @luafunc landWindow
 */
static int playerL_landWindow( lua_State *L )
{
   int ret;
   const char *str;
   int win;

   NLUA_CHECKRW(L);

   if (!landed) {
      NLUA_ERROR(L, _("Must be landed to set the active land window."));
      return 0;
   }

   str = luaL_checkstring(L,1);
   if (strcasecmp(str,"main")==0)
      win = LAND_WINDOW_MAIN;
   else if (strcasecmp(str,"bar")==0)
      win = LAND_WINDOW_BAR;
   else if (strcasecmp(str,"missions")==0)
      win = LAND_WINDOW_MISSION;
   else if (strcasecmp(str,"outfits")==0)
      win = LAND_WINDOW_OUTFITS;
   else if (strcasecmp(str,"shipyard")==0)
      win = LAND_WINDOW_SHIPYARD;
   else if (strcasecmp(str,"equipment")==0)
      win = LAND_WINDOW_EQUIPMENT;
   else if (strcasecmp(str,"commodity")==0)
      win = LAND_WINDOW_COMMODITY;
   else
      NLUA_INVALID_PARAMETER(L);

   /* Sets the window. */
   ret = land_setWindow( win );

   lua_pushboolean( L, !ret );
   return 1;
}


/**
 * @brief Forces the player to close comm if they are chatting.
 *
 * @luafunc commClose
 */
static int playerL_commclose( lua_State *L )
{
   (void) L;
   NLUA_CHECKRW(L);
   comm_queueClose();
   return 0;
}


/**
 * @brief Gets information about the player's ships.
 *
 * The returned table contains one ship table for each of the player's
 * ships, and each ship table contains the following values:<br/>
 * <ul>
 *    <li>"name" (string): The name of the ship (technically, the name
 *       of the pilot) given by the player.</li>
 *    <li>"ship" (Ship): The actual ship type of the player ship (e.g.
 *       the value returned by ship.get("Llama") if the ship is a
 *       Llama).</li>
 * </ul>
 * <br/>
 *
 * @usage
 * for i, v in ipairs(player.ships()) do
 *    print(v.name) -- Prints player-defined pilot name
 *    print(v.ship:name()) -- Prints name of the ship (e.g. "Llama")
 * end
 *
 *   @luatreturn {ShipTable,...} ships Table of ship tables. See above
 *       for an explanation of the ship table format.
 * @luafunc ships
 */
static int playerL_ships( lua_State *L )
{
   int i;
   const PlayerShip_t *ships;

   ships = player_getShipStack();

   lua_newtable(L);  /* t */
   for (i=0; i<array_size(ships); i++) {
      lua_pushnumber(L, i+1); /* t, k */
      lua_newtable(L);        /* t, k, t */

      lua_pushstring(L, ships[i].p->name); /* t, k, t, s */
      lua_setfield(L, -2, "name"); /* t, k, t */

      lua_pushship(L, ships[i].p->ship); /* t, k, t, s */
      lua_setfield(L, -2, "ship"); /* t, k, t */

      lua_rawset(L, -3); /* t */
   }

   return 1;
}


/**
 * @brief Gets the outfits for one of the player's ships.
 *
 * @usage outfits = player.shipOutfits("Llama") -- Gets the Llama's outfits
 *
 *   @luatparam string name Name of the ship to get the outfits of.
 *   @luatreturn {Outfit,...} Table of outfits.
 * @luafunc shipOutfits
 */
static int playerL_shipOutfits( lua_State *L )
{
   const char *str;
   int i, j;
   const PlayerShip_t *ships;
   Pilot *p;

   PLAYER_CHECK();

   /* Get name. */
   str = luaL_checkstring(L, 1);

   ships = player_getShipStack();

   /* Get outfit. */
   lua_newtable(L);

   p = NULL;
   if (strcmp(str, player.p->name)==0)
      p = player.p;
   else {
      for (i=0; i<array_size(ships); i++) {
         if (strcmp(str, ships[i].p->name)==0) {
            p = ships[i].p;
            break;
         }
      }
   }

   if (p == NULL) {
      NLUA_ERROR( L, _("Player does not own a ship named '%s'"), str );
      return 0;
   }

   lua_newtable( L );
   j = 1;
   for (i=0; i<array_size(p->outfits); i++) {
      if (p->outfits[i]->outfit == NULL)
         continue;

      /* Set the outfit. */
      lua_pushnumber( L, j++ );
      lua_pushoutfit( L, p->outfits[i]->outfit );
      lua_rawset( L, -3 );
   }

   return 1;
}


/**
 * @brief Adds an outfit to one of the player's ships.
 *
 * This by default tries to add them to the first empty slot. Will not
 * overwrite existing outfits.
 *
 * @note The outfit is added in the same manner as pilot.outfitAdd. It
 *    does not pull from the player's existing outfits, but rather adds
 *    an entirely new one.
 *
 * @usage player.shipOutfitAdd("Titanic", "Laser Cannon MK1", 2)
 *
 *    @luatparam string name Name of the ship to add outfits to.
 *    @luatparam string|Outfit outfit Outfit or raw (untranslated) name
 *       of the outfit to add.
 *    @luatparam[opt=1] number q Quantity of the outfit to add.
 *    @luatparam[opt=false] boolean bypass_cpu Whether to skip CPU
 *       checks when adding an outfit.
 *    @luatreturn number The number of outfits added.
 * @luafunc shipOutfitAdd
 */
static int playerL_shipOutfitAdd( lua_State *L )
{
   const char *str;
   int i;
   const PlayerShip_t *ships;
   Pilot *p;
   const Outfit *o;
   int ret;
   int q, added, bypass_cpu;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   /* Get parameters. */
   str = luaL_checkstring(L, 1);
   o = luaL_validoutfit(L, 2);
   q = luaL_optinteger(L, 3, 1);
   bypass_cpu = lua_toboolean(L, 4);

   /* Get name. */
   str = luaL_checkstring(L, 1);

   ships = player_getShipStack();

   /* Get outfit. */
   lua_newtable(L);

   p = NULL;
   if (strcmp(str, player.p->name)==0)
      p = player.p;
   else {
      for (i=0; i<array_size(ships); i++) {
         if (strcmp(str, ships[i].p->name)==0) {
            p = ships[i].p;
            break;
         }
      }
   }

   if (p == NULL) {
      NLUA_ERROR( L, _("Player does not own a ship named '%s'"), str );
      return 0;
   }

   /* Add outfit. */
   added = 0;
   for (i=0; i<array_size(p->outfits); i++) {
      /* Must still have to add outfit. */
      if (q <= 0)
         break;

      /* Must not have outfit already. */
      if (p->outfits[i]->outfit != NULL)
         continue;

      /* Slot size check cannot be skipped since it affects the
       * player. */
      if (!outfit_fitsSlot(o, &p->outfits[i]->sslot->slot))
         continue;

      if (!bypass_cpu) {
         /* Test if can add outfit (CPU check). */
         ret = pilot_addOutfitTest(p, o, p->outfits[i], 0);
         if (ret)
            break;
      }

      /* Add outfit - already tested. */
      ret = pilot_addOutfitRaw(p, o, p->outfits[i]);
      pilot_calcStats(p);

      /* Add ammo if needed. */
      if ((ret == 0) && (outfit_ammo(o) != NULL))
         pilot_addAmmo(p, p->outfits[i], outfit_ammo(o), outfit_amount(o));

      /* We added an outfit. */
      q--;
      added++;
   }

   if (added > 0) {
      if (p->autoweap)
         /* Update the weapon sets. */
         pilot_weaponAuto(p);

      /* Update equipment window since it's a player pilot. */
      outfits_updateEquipmentOutfits();
   }

   lua_pushnumber(L, added);
   return 1;
}


/**
 * @brief Removes an outfit to one of the player's ships.
 *
 * "all" will remove all outfits except cores.
 * "cores" will remove all cores, but nothing else.
 *
 * @note The outfit is removed in the same manner as pilot.outfitRm. It
 *    does not return the outfit to the player's outfits list, but
 *    instead deletes it entirely.
 *
 * @usage player.shipOutfitRm("Titanic", "all")
 * @usage player.shipOutfitRm("Titanic", "cores")
 * @usage player.shipOutfitRm("Titanic", "Laser Cannon MK1")
 * @usage player.shipOutfitRm("Titanic", "Laser Cannon MK1", 2)
 *
 *    @luatparam string name Name of the ship to remove outfits from.
 *    @luatparam string|Outfit outfit Outfit or raw (untranslated) name
 *       of the outfit to remove.
 *    @luatparam[opt=1] number q Quantity of the outfit to remove.
 *    @luatreturn number The number of outfits removed.
 * @luafunc shipOutfitRm
 */
static int playerL_shipOutfitRm( lua_State *L )
{
   const char *str;
   int i;
   const PlayerShip_t *ships;
   Pilot *p;
   const char *outfit;
   const Outfit *o;
   int q, removed, matched;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   /* Get parameters. */
   str = luaL_checkstring(L, 1);
   q = luaL_optinteger(L, 3, 1);

   ships = player_getShipStack();

   /* Get outfit. */
   lua_newtable(L);

   p = NULL;
   if (strcmp(str, player.p->name)==0)
      p = player.p;
   else {
      for (i=0; i<array_size(ships); i++) {
         if (strcmp(str, ships[i].p->name) == 0) {
            p = ships[i].p;
            break;
         }
      }
   }

   if (p == NULL) {
      NLUA_ERROR(L, _("Player does not own a ship named '%s'"), str);
      return 0;
   }

   matched = 0;
   removed = 0;
   if (lua_isstring(L, 2)) {
      outfit = luaL_checkstring(L, 2);

      /* If outfit is "all", we remove everything except cores. */
      if (strcmp(outfit, "all") == 0) {
         for (i=0; i<array_size(p->outfits); i++) {
            if (p->outfits[i]->sslot->required)
               continue;
            pilot_rmOutfitRaw(p, p->outfits[i]);
            removed++;
         }
         pilot_calcStats(p); /* Recalculate stats. */
         matched = 1;
      }
      /* If outfit is "cores", we remove cores only. */
      else if (strcmp(outfit, "cores") == 0) {
         for (i=0; i<array_size(p->outfits); i++) {
            if (!p->outfits[i]->sslot->required)
               continue;
            pilot_rmOutfitRaw(p, p->outfits[i]);
            removed++;
         }
         pilot_calcStats(p); /* Recalculate stats. */
         matched = 1;
      }
   }

   if (!matched) {
      o = luaL_validoutfit(L,2);

      /* Remove the outfit outfit. */
      for (i=0; i<array_size(p->outfits); i++) {
         /* Must still need to remove. */
         if (q <= 0)
            break;

         /* Not found. */
         if (p->outfits[i]->outfit != o)
            continue;

         /* Remove outfit. */
         pilot_rmOutfit(p, p->outfits[i]);
         q--;
         removed++;
      }
   }

   if (removed > 0) {
      if (p->autoweap)
         /* Update the weapon sets. */
         pilot_weaponAuto(p);

      /* Update equipment window since it's a player pilot. */
      outfits_updateEquipmentOutfits();
   }

   lua_pushnumber(L, removed);
   return 1;
}


/**
 * @brief Gets all the outfits the player owns.
 *
 * If you want the quantity, call player.numOutfit() on the individual outfit.
 *
 * @usage player.outfits() -- A table of all the player's outfits.
 *
 *   @luatreturn {Outfit,...} Table of outfits.
 * @luafunc outfits
 */
static int playerL_outfits( lua_State *L )
{
   int i;
   const PlayerOutfit_t *outfits;

   outfits = player_getOutfits();

   lua_newtable(L);
   for (i=0; i<array_size(outfits); i++) {
      lua_pushoutfit(L, (Outfit*)outfits[i].o);
      lua_rawseti(L, -2, i+1);
   }

   return 1;
}


/**
 * @brief Gets the number of outfits the player owns in their list (excludes equipped on ships).
 *
 * @usage q = player.numOutfit( "Laser Cannon MK0", true ) -- Number of 'Laser Cannon MK0' the player owns (unequipped)
 *
 *    @luatparam string name Name of the outfit to remove.
 *    @luatparam[opt] bool unequipped_only Whether or not to check only the unequipped outfits and not equipped outfits. Defaults to false.
 *    @luatreturn number The quantity the player owns.
 * @luafunc numOutfit
 */
static int playerL_numOutfit( lua_State *L )
{
   const Outfit *o;
   int q, unequipped_only;

   /* Handle parameters. */
   o = luaL_validoutfit(L, 1);
   unequipped_only = lua_toboolean(L, 2);

   /* Count the outfit. */
   if (unequipped_only)
      q = player_outfitOwned( o );
   else
      q = player_outfitOwnedTotal( o );
   lua_pushnumber( L, q );

   return 1;
}
/**
 * @brief Adds an outfit to the player's outfit list.
 *
 * @usage player.outfitAdd( "Laser Cannon" ) -- Gives the player a laser cannon
 * @usage player.outfitAdd( "Plasma Blaster", 2 ) -- Gives the player two plasma blasters
 *
 *    @luatparam string name Name of the outfit to give.
 *    @luatparam[opt=1] number q Quantity to give.
 * @luafunc outfitAdd
 */
static int playerL_addOutfit( lua_State *L  )
{
   const Outfit *o;
   int q;

   NLUA_CHECKRW(L);

   /* Handle parameters. */
   o = luaL_validoutfit(L, 1);
   q = luaL_optinteger(L, 2, 1);

   /* Add the outfits. */
   player_addOutfit( o, q );

   /* Update equipment list. */
   outfits_updateEquipmentOutfits();

   return 0;
}
/**
 * @brief Removes an outfit from the player's outfit list.
 *
 * "all" will remove all outfits.
 *
 * @usage player.outfitRm( "Plasma Blaster", 2 ) -- Removes two plasma blasters from the player
 *
 *    @luatparam string name Name of the outfit to give.
 *    @luatparam[opt] number q Quantity to remove (default 1).
 * @luafunc outfitRm
 */
static int playerL_rmOutfit( lua_State *L )
{
   const char *str;
   const Outfit *o, **outfits;
   const PlayerOutfit_t *poutfits;
   int i, q;

   NLUA_CHECKRW(L);
   NLUA_MIN_ARGS(1);

   /* Get quantity. */
   q = luaL_optinteger(L, 2, 1);

   /* Handle special case it's "all". */
   if (lua_isstring(L, 1)) {
      str = luaL_checkstring(L, 1);

      if (strcmp(str,"all")==0) {
         poutfits = player_getOutfits();
         outfits = array_create_size( const Outfit*, array_size( poutfits ) );
         for (i=0; i<array_size(poutfits); i++)
            array_push_back( &outfits, poutfits[i].o );

         for (i=0; i<array_size(outfits); i++) {
            o = outfits[i];
            q = player_outfitOwned(o);
            player_rmOutfit(o, q);
         }
         /* Clean up. */
         array_free(outfits);

         /* Update equipment list. */
         outfits_updateEquipmentOutfits();
         return 0;
      }
   }

   /* Usual case. */
   o = luaL_validoutfit(L, 1);
   player_rmOutfit( o, q );

   /* Update equipment list. */
   outfits_updateEquipmentOutfits();

   return 0;
}


/**
 * @brief Gives the player a new ship.
 *
 * @note Should be given when landed, ideally on a planet with a shipyard. Furthermore, this invalidates all player.pilot() references.
 *
 * @usage player.addShip( "Pirate Kestrel", "Seiryuu" ) -- Gives the player a Pirate Kestrel named Seiryuu if player cancels the naming.
 *
 *    @luatparam string ship Name of the ship to add.
 *    @luatparam[opt] string name Name to give the ship if player refuses to name it (defaults to shipname if omitted).
 *    @luatparam[opt=false] boolean noname If true does not let the player name the ship.
 *    @luatreturn string The new ship's name.
 * @luafunc addShip
 */
static int playerL_addShip( lua_State *L )
{
   NLUA_CHECKRW(L);
   Pilot *new_ship;
   /* Handle parameters. */
   const Ship *s     = luaL_validship(L, 1);
   const char *name  = luaL_optstring(L, 2, _(s->name) );
   int noname        = lua_toboolean(L, 3);
   /* Add the ship, look in case it's cancelled. */
   do {
      new_ship = player_newShip( s, name, 0, noname );
   } while (new_ship == NULL);
   /* Return the new name. */
   lua_pushstring( L, new_ship->name );
   return 1;
}


/**
 * @brief Swaps the player's current ship with a ship they own by name.
 *
 * @note You shouldn't use this directly unless you know what you are doing. If the player's cargo doesn't fit in the new ship, it won't be moved over and can lead to a whole slew of issues.
 * @note This invalidates all player.pilot() references!
 *
 *    @luatparam string ship Name of the ship to swap to. (this is name given by the player, not ship name)
 *    @luatparam[opt=false] boolean ignore_cargo Whether or not to ignore cargo and not move it, or try to move it over.
 *    @luatparam[opt=false] boolean remove If true removes the player's current ship (so it replaces and doesn't swap).
 * @luafunc swapShip
 */
static int playerL_swapShip( lua_State *L )
{
   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   const char *str = luaL_checkstring(L,1);
   int ignore_cargo= lua_toboolean(L,2);
   const char *cur = player.p->name;
   player_swapShip( str, !ignore_cargo );
   if (lua_toboolean(L,3))
      player_rmShip( cur );

   return 0;
}


/**
 * @brief Checks to see if the player has a mission active.
 *
 * @usage if player.misnActive( "The Space Family" ) then -- Player is doing space family mission
 *
 *    @luatparam string name Name of the mission to check.
 *    @luatreturn boolean true if the mission is active, false if it isn't.
 * @luafunc misnActive
 */
static int playerL_misnActive( lua_State *L )
{
   MissionData *misn;
   const char *str;

   str  = luaL_checkstring(L,1);
   misn = mission_getFromName( str );
   if (misn == NULL) {
      NLUA_ERROR(L, _("Mission '%s' not found in stack"), str);
      return 0;
   }

   lua_pushboolean( L, mission_alreadyRunning( misn ) );
   return 1;
}

/**
 * @brief Checks to see if player has done a mission.
 *
 * This only works with missions that have the unique flag.
 *
 * @usage if player.misnDone( "The Space Family" ) then -- Player finished mission
 *    @luatparam string name Name of the mission to check.
 *    @luatreturn boolean true if mission was finished, false if it wasn't.
 * @luafunc misnDone
 */
static int playerL_misnDone( lua_State *L )
{
   const char *str;
   int id;

   /* Handle parameters. */
   str = luaL_checkstring(L, 1);

   /* Get mission ID. */
   id = mission_getID( str );
   if (id == -1) {
      NLUA_ERROR(L, _("Mission '%s' not found in stack"), str);
      return 0;
   }

   lua_pushboolean( L, player_missionAlreadyDone( id ) );
   return 1;
}


/**
 * @brief Checks to see if the player has an event active.
 *
 * @usage if player.evtActive( "Shipwreck" ) then -- The shipwreck event is active
 *
 *    @luatparam string name Name of the mission to check.
 *    @luatreturn boolean true if the mission is active, false if it isn't.
 * @luafunc evtActive
 */
static int playerL_evtActive( lua_State *L )
{
   int evtid;
   const char *str;

   str  = luaL_checkstring(L,1);
   evtid = event_dataID( str );
   if (evtid < 0) {
      NLUA_ERROR(L, _("Event '%s' not found in stack"), str);
      return 0;
   }

   lua_pushboolean( L, event_alreadyRunning( evtid ) );
   return 1;
}


/**
 * @brief Checks to see if player has done an event.
 *
 * This only works with events that have the unique flag.
 *
 * @usage if player.evtDone( "Shipwreck" ) then -- Player finished event
 *    @luatparam string name Name of the event to check.
 *    @luatreturn boolean true if event was finished, false if it wasn't.
 * @luafunc evtDone
 */
static int playerL_evtDone( lua_State *L )
{
   const char *str;
   int id;

   /* Handle parameters. */
   str = luaL_checkstring(L, 1);

   /* Get event ID. */
   id = event_dataID( str );
   if (id == -1) {
      NLUA_ERROR(L, _("Event '%s' not found in stack"), str);
      return 0;
   }

   lua_pushboolean( L, player_eventAlreadyDone( id ) );
   return 1;
}


/**
 * @brief Teleports the player to a new planet or system (only if not landed).
 *
 * If the destination is a system, the coordinates of the player will not change.
 * If the destination is a planet, the player will be placed over that planet.
 *
 * @usage player.teleport( system.get("Arcanis") ) -- Teleports the player to Arcanis.
 * @usage player.teleport( "Arcanis" ) -- Teleports the player to Arcanis.
 * @usage player.teleport( "Dvaer Prime" ) -- Teleports the player to Dvaer, and relocates him to Dvaer Prime.
 *
 *    @luatparam System|Planet|string dest System or name of a system or planet or name of a planet to teleport the player to.
 * @luafunc teleport
 */
static int playerL_teleport( lua_State *L )
{
   Planet *pnt;
   StarSystem *sys;
   const char *name, *pntname, *sysname;

   NLUA_CHECKRW(L);
   PLAYER_CHECK();

   /* Must not be landed. */
   if (landed)
      NLUA_ERROR(L,_("Can not teleport the player while landed!"));
   if (comm_isOpen())
      NLUA_ERROR(L,_("Can not teleport the player while the comm is open!"));
   if (player_isBoarded())
      NLUA_ERROR(L,_("Can not teleport the player while they are boarded!"));

   pnt = NULL;

   /* Get a system. */
   if (lua_issystem(L,1)) {
      sys   = luaL_validsystem(L,1);
      name  = system_getIndex(sys->id)->name;
   }
   /* Get a planet. */
   else if (lua_isplanet(L,1)) {
      pnt   = luaL_validplanet(L,1);
      name  = planet_getSystem( pnt->name );
      if (name == NULL) {
         NLUA_ERROR( L, _("Planet '%s' does not belong to a system."), pnt->name );
         return 0;
      }
   }
   /* Get destination from string. */
   else if (lua_isstring(L,1)) {
      name = lua_tostring(L,1);
      sysname = system_existsCase( name );
      if (sysname == NULL) {
         /* No system found, assume destination string is the name of a planet. */
         pntname = name;
         name = planet_getSystem( pntname );
         pnt  = planet_get( pntname );
         if (pnt == NULL) {
            NLUA_ERROR( L, _("'%s' is not a valid teleportation target."), name );
            return 0;
         }

         if (name == NULL) {
            NLUA_ERROR( L, _("Planet '%s' does not belong to a system."), pntname );
            return 0;
         }
      }
      else
         sys = system_get( sysname );
   }
   else
      NLUA_INVALID_PARAMETER(L);

   /* Check if system exists. */
   if (system_get( name ) == NULL) {
      NLUA_ERROR( L, _("System '%s' does not exist."), name );
      return 0;
   }

   /* Jump out hook is run first. */
   hooks_run( "jumpout" );

   /* Just in case remove hyperspace flags. */
   pilot_rmFlag( player.p, PILOT_HYPERSPACE );
   pilot_rmFlag( player.p, PILOT_HYP_BEGIN );
   pilot_rmFlag( player.p, PILOT_HYP_BRAKE );
   pilot_rmFlag( player.p, PILOT_HYP_PREP );
   /* Don't follow anything. */
   player_accelOver();
   player_autonavEnd();

   /* Free graphics. */
   space_gfxUnload( cur_system );

   /* Reset targets when teleporting.
    * Both of these functions invoke gui_setNav(), which updates jump and
    * planet targets simultaneously. Thus, invalid reads may arise and the
    * target reset must be done prior to calling space_init and destroying
    * the old system.
    */
   player_targetClearAll();

   /* Go to the new system. */
   space_init( name );

   /* Map gets deformed when jumping this way. */
   map_clear();
   map_select(map_getDestination(NULL), 0);

   /* Run hooks - order is important. */
   hooks_run( "jumpin" );
   hooks_run( "enter" );
   events_trigger( EVENT_TRIGGER_ENTER );
   missions_run( MIS_AVAIL_SPACE, -1, NULL, NULL );

   /* Move to planet. */
   if (pnt != NULL)
      player.p->solid->pos = pnt->pos;

   return 0;
}


/**
 * @brief Gets the dt_mod of the player, which multiplies all time stuff.
 */
static int playerL_dt_mod( lua_State *L )
{
   lua_pushnumber(L,dt_mod);
   return 1;
}

