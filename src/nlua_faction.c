/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file nlua_faction.c
 *
 * @brief Handles the Lua faction bindings.
 *
 * These bindings control the factions.
 */

/** @cond */
#include <lauxlib.h>

#include "naev.h"
/** @endcond */

#include "nlua_faction.h"

#include "array.h"
#include "faction.h"
#include "log.h"
#include "nlua_col.h"
#include "nlua_tex.h"
#include "nluadef.h"


/* Faction metatable methods */
static int factionL_get( lua_State *L );
static int factionL_eq( lua_State *L );
static int factionL_name( lua_State *L );
static int factionL_nameRaw( lua_State *L );
static int factionL_longname( lua_State *L );
static int factionL_areenemies( lua_State *L );
static int factionL_areallies( lua_State *L );
static int factionL_modplayer( lua_State *L );
static int factionL_modplayersingle( lua_State *L );
static int factionL_modplayerraw( lua_State *L );
static int factionL_setplayerstanding( lua_State *L );
static int factionL_playerstanding( lua_State *L );
static int factionL_enemies( lua_State *L );
static int factionL_allies( lua_State *L );
static int factionL_logoSmall( lua_State *L );
static int factionL_logoTiny( lua_State *L );
static int factionL_colour( lua_State *L );
static int factionL_getPrefix(lua_State *L);
static int factionL_isknown( lua_State *L );
static int factionL_setknown( lua_State *L );
static int factionL_dynAdd( lua_State *L );
static int factionL_dynAlly( lua_State *L );
static int factionL_dynEnemy( lua_State *L );
static const luaL_Reg faction_methods[] = {
   {"get", factionL_get},
   {"__eq", factionL_eq},
   {"__tostring", factionL_name},
   {"name", factionL_name},
   {"nameRaw", factionL_nameRaw},
   {"longname", factionL_longname},
   {"areEnemies", factionL_areenemies},
   {"areAllies", factionL_areallies},
   {"modPlayer", factionL_modplayer},
   {"modPlayerSingle", factionL_modplayersingle},
   {"modPlayerRaw", factionL_modplayerraw},
   {"setPlayerStanding", factionL_setplayerstanding},
   {"playerStanding", factionL_playerstanding},
   {"enemies", factionL_enemies},
   {"allies", factionL_allies},
   {"logoSmall", factionL_logoSmall},
   {"logoTiny", factionL_logoTiny},
   {"colour", factionL_colour},
   {"getPrefix", factionL_getPrefix},
   {"known", factionL_isknown},
   {"setKnown", factionL_setknown},
   {"dynAdd", factionL_dynAdd},
   {"dynAlly", factionL_dynAlly},
   {"dynEnemy", factionL_dynEnemy},
   {0, 0}
}; /**< Faction metatable methods. */


/**
 * @brief Loads the faction library.
 *
 *    @param env Environment to load faction library into.
 *    @return 0 on success.
 */
int nlua_loadFaction( nlua_env env )
{
   nlua_register(env, FACTION_METATABLE, faction_methods, 1);
   return 0; /* No error */
}


/**
 * @brief Lua bindings to deal with factions.
 *
 * Use like:
 * @code
 * f = faction.get( "Empire" )
 * if f:playerStanding() < 0 then
 *    -- player is hostile to "Empire"
 * end
 * @endcode
 *
 * @luamod faction
 */
/**
 * @brief Gets the faction based on its name.
 *
 * @usage f = faction.get( "Empire" )
 *
 *    @luatparam string name Name of the faction to get.
 *    @luatreturn Faction The faction matching name.
 * @luafunc get
 */
static int factionL_get( lua_State *L )
{
   LuaFaction f;
   const char *name;

   name = luaL_checkstring(L,1);
   f = faction_get(name);
   if (!faction_isFaction(f)) {
      NLUA_ERROR(L,_("Faction '%s' not found in stack."), name );
      return 0;
   }
   lua_pushfaction(L,f);
   return 1;
}


/**
 * @brief Gets faction at index.
 *
 *    @param L Lua state to get faction from.
 *    @param ind Index position to find the faction.
 *    @return Faction found at the index in the state.
 */
LuaFaction lua_tofaction( lua_State *L, int ind )
{
   return *((LuaFaction*) lua_touserdata(L,ind));
}


/**
 * @brief Gets faction (or faction name) at index, raising an error if type isn't a valid faction.
 *
 *    @param L Lua state to get faction from.
 *    @param ind Index position to find the faction.
 *    @return Faction found at the index in the state.
 */
LuaFaction luaL_validfaction( lua_State *L, int ind )
{
   LuaFaction id;

   if (lua_isfaction(L,ind))
      id = lua_tofaction(L,ind);
   else if (lua_isstring(L,ind))
      id = faction_get( lua_tostring(L, ind) );
   else {
      luaL_typerror(L, ind, FACTION_METATABLE);
      return 0;
   }

   if (!faction_isFaction(id))
      NLUA_ERROR(L, _("Faction '%s' not found in stack. (FID returned: %ld)"),
            lua_tostring(L, ind), id);

   return id;
}


/**
 * @brief Pushes a faction on the stack.
 *
 *    @param L Lua state to push faction into.
 *    @param faction Faction to push.
 *    @return Newly pushed faction.
 */
LuaFaction* lua_pushfaction( lua_State *L, LuaFaction faction )
{
   LuaFaction *f;
   f = (LuaFaction*) lua_newuserdata(L, sizeof(LuaFaction));
   *f = faction;
   luaL_getmetatable(L, FACTION_METATABLE);
   lua_setmetatable(L, -2);
   return f;
}
/**
 * @brief Checks to see if ind is a faction.
 *
 *    @param L Lua state to check.
 *    @param ind Index position to check.
 *    @return 1 if ind is a faction.
 */
int lua_isfaction( lua_State *L, int ind )
{
   int ret;

   if (lua_getmetatable(L,ind)==0)
      return 0;
   lua_getfield(L, LUA_REGISTRYINDEX, FACTION_METATABLE);

   ret = 0;
   if (lua_rawequal(L, -1, -2))  /* does it have the correct mt? */
      ret = 1;

   lua_pop(L, 2);  /* remove both metatables */
   return ret;
}

/**
 * @brief __eq (equality) metamethod for factions.
 *
 * You can use the '==' operator within Lua to compare factions with this.
 *
 * @usage if f == faction.get( "Dvaered" ) then
 *
 *    @luatparam Faction f Faction comparing.
 *    @luatparam Faction comp faction to compare against.
 *    @luatreturn boolean true if both factions are the same.
 * @luafunc __eq
 */
static int factionL_eq( lua_State *L )
{
   LuaFaction a = luaL_validfaction(L, 1);
   LuaFaction b = luaL_validfaction(L, 2);
   lua_pushboolean(L, a == b);
   return 1;
}

/**
 * @brief Gets the faction's translated short name.
 *
 * This translated name should be used for display purposes (e.g.
 * messages) where the shorter version of the faction's display name
 * should be used. It cannot be used as an identifier for the faction;
 * for that, use faction.nameRaw() instead.
 *
 * @usage shortname = f:name()
 *
 *    @luatparam Faction f The faction to get the name of.
 *    @luatreturn string The name of the faction.
 * @luafunc name
 */
static int factionL_name( lua_State *L )
{
   LuaFaction f;
   const char *name;

   f = luaL_validfaction(L, 1);
   name = faction_shortname(f);

   if (name == NULL) {
      NLUA_ERROR(L, _("Faction is invalid."));
      return 0;
   }

   lua_pushstring(L, name);
   return 1;
}

/**
 * @brief Gets the faction's raw / "real" (untranslated, internal) name.
 *
 * This untranslated name should be used for identification purposes
 * (e.g. can be passed to faction.get()). It should not be used for
 * display purposes; for that, use faction.name() or faction.longname()
 * instead.
 *
 * @usage name = f:nameRaw()
 *
 *    @luatparam Faction f The faction to get the name of.
 *    @luatreturn string The name of the faction.
 * @luafunc nameRaw
 */
static int factionL_nameRaw( lua_State *L )
{
   LuaFaction f;
   const char *name;

   f = luaL_validfaction(L, 1);
   name = faction_name(f);

   if (name == NULL) {
      NLUA_ERROR(L, _("Faction is invalid."));
      return 0;
   }

   lua_pushstring(L, name);
   return 1;
}

/**
 * @brief Gets the faction's translated long name.
 *
 * This translated name should be used for display purposes (e.g.
 * messages) where the longer version of the faction's display name
 * should be used. It cannot be used as an identifier for the faction;
 * for that, use faction.nameRaw() instead.
 *
 * @usage longname = f:longname()
 *    @luatparam Faction f Faction to get long name of.
 *    @luatreturn string The long name of the faction (translated).
 * @luafunc longname
 */
static int factionL_longname( lua_State *L )
{
   LuaFaction f;
   const char *name;

   f = luaL_validfaction(L, 1);
   name = faction_longname(f);

   if (name == NULL) {
      NLUA_ERROR(L, _("Faction is invalid."));
      return 0;
   }

   lua_pushstring(L, name);
   return 1;
}

/**
 * @brief Checks to see if f is an enemy of e.
 *
 * @usage if f:areEnemies( faction.get( "Dvaered" ) ) then
 *
 *    @luatparam Faction f Faction to check against.
 *    @luatparam Faction e Faction to check if is an enemy.
 *    @luatreturn string true if they are enemies, false if they aren't.
 * @luafunc areEnemies
 */
static int factionL_areenemies( lua_State *L )
{
   LuaFaction f = luaL_validfaction(L, 1);
   LuaFaction ff = luaL_validfaction(L, 2);
   lua_pushboolean(L, areEnemies( f, ff ));
   return 1;
}

/**
 * @brief Checks to see if f is an ally of a.
 *
 * @usage if f:areAllies( faction.get( "Pirate" ) ) then
 *
 *    @luatparam Faction f Faction to check against.
 *    @luatparam faction a Faction to check if is an enemy.
 *    @luatreturn boolean true if they are enemies, false if they aren't.
 * @luafunc areAllies
 */
static int factionL_areallies( lua_State *L )
{
   LuaFaction f = luaL_validfaction(L, 1);
   LuaFaction ff = luaL_validfaction(L, 2);
   lua_pushboolean(L, areAllies( f, ff ));
   return 1;
}

/**
 * @brief Modifies the player's standing with the faction.
 *
 * Also modifies standing with allies and enemies of the faction.
 *
 * @usage f:modPlayer( -5 ) -- Lowers faction by 5
 *
 *    @luatparam Faction f Faction to modify player's standing with.
 *    @luatparam number mod The modifier to modify faction by.
 * @luafunc modPlayer
 */
static int factionL_modplayer( lua_State *L )
{
   NLUA_CHECKRW(L);
   LuaFaction f = luaL_validfaction(L, 1);
   double n = luaL_checknumber(L,2);
   faction_modPlayer( f, n, "script" );
   return 0;
}

/**
 * @brief Modifies the player's standing with the faction.
 *
 * Does not affect other faction standings.
 *
 * @usage f:modPlayerSingle( 10 )
 *
 *    @luatparam Faction f Faction to modify player's standing with.
 *    @luatparam number mod The modifier to modify faction by.
 * @luafunc modPlayerSingle
 */
static int factionL_modplayersingle( lua_State *L )
{
   NLUA_CHECKRW(L);
   LuaFaction f = luaL_validfaction(L, 1);
   double n = luaL_checknumber(L,2);
   faction_modPlayerSingle( f, n, "script" );

   return 0;
}

/**
 * @brief Modifies the player's standing with the faction.
 *
 * Does not affect other faction standings and is not processed by the faction
 *  Lua script, so it indicates exactly the amount to be changed.
 *
 * @usage f:modPlayerRaw( 10 )
 *
 *    @luatparam Faction f Faction to modify player's standing with.
 *    @luatparam number mod The modifier to modify faction by.
 * @luafunc modPlayerRaw
 */
static int factionL_modplayerraw( lua_State *L )
{
   NLUA_CHECKRW(L);
   LuaFaction f = luaL_validfaction(L, 1);
   double n = luaL_checknumber(L,2);
   faction_modPlayerRaw( f, n );
   return 0;
}

/**
 * @brief Sets the player's standing with the faction.
 *
 * @usage f:setPlayerStanding(70) -- Make player an ally
 *
 *    @luatparam Faction f Faction to set the player's standing for.
 *    @luatparam number value Value to set the player's standing to (from -100 to 100).
 * @luafunc setPlayerStanding
 */
static int factionL_setplayerstanding( lua_State *L )
{
   NLUA_CHECKRW(L);
   LuaFaction f = luaL_validfaction(L, 1);
   double n = luaL_checknumber( L, 2 );
   faction_setPlayer( f, n );
   return 0;
}

/**
 * @brief Gets the player's standing with the faction.
 *
 * @usage if f:playerStanding() > 70 then -- Player is an ally
 *
 *    @luatparam Faction f Faction to get player's standing with.
 *    @luatreturn number The value of the standing and the human readable string.
 * @luafunc playerStanding
 */
static int factionL_playerstanding( lua_State *L )
{
   LuaFaction f = luaL_validfaction(L, 1);
   double n = faction_getPlayer( f );
   lua_pushnumber( L, n );
   lua_pushstring( L, faction_getStandingText( f ) );
   return 2;
}

/**
 * @brief Gets the enemies of the faction.
 *
 * @usage for k,v in pairs(f:enemies()) do -- Iterates over enemies
 *
 *    @luatparam Faction f Faction to get enemies of.
 *    @luatreturn {Faction,...} A table containing the enemies of the faction.
 * @luafunc enemies
 */
static int factionL_enemies( lua_State *L )
{
   int i;
   LuaFaction f;
   LuaFaction *factions;

   f = luaL_validfaction(L,1);

   /* Push the enemies in a table. */
   lua_newtable(L);
   factions = faction_getEnemies( f );
   for (i=0; i<array_size(factions); i++) {
      lua_pushnumber(L, i+1); /* key */
      lua_pushfaction(L, factions[i]); /* value */
      lua_rawset(L, -3);
   }

   return 1;
}

/**
 * @brief Gets the allies of the faction.
 *
 * @usage for k,v in pairs(f:allies()) do -- Iterate over faction allies
 *
 *    @luatparam Faction f Faction to get allies of.
 *    @luatreturn {Faction,...} A table containing the allies of the faction.
 * @luafunc allies
 */
static int factionL_allies( lua_State *L )
{
   int i;
   LuaFaction f;
   LuaFaction *factions;

   f = luaL_validfaction(L,1);

   /* Push the enemies in a table. */
   lua_newtable(L);
   factions = faction_getAllies( f );
   for (i=0; i<array_size(factions); i++) {
      lua_pushnumber(L, i+1); /* key */
      lua_pushfaction(L, factions[i]); /* value */
      lua_rawset(L, -3);
   }

   return 1;
}


/**
 * @brief Gets the small faction logo which is 64x64 or smaller.
 *
 *    @luatparam Faction f Faction to get logo from.
 *    @luatreturn Tex The small faction logo or nil if not applicable.
 * @luafunc logoSmall
 */
static int factionL_logoSmall( lua_State *L )
{
   LuaFaction lf;
   glTexture *tex;
   lf = luaL_validfaction(L,1);
   tex = faction_logoSmall( lf );
   if (tex == NULL)
      return 0;
   lua_pushtex( L, gl_dupTexture( tex ) );
   return 1;
}


/**
 * @brief Gets the tiny faction logo which is 24x24 or smaller.
 *
 *    @luatparam Faction f Faction to get logo from.
 *    @luatreturn Tex The tiny faction logo or nil if not applicable.
 * @luafunc logoTiny
 */
static int factionL_logoTiny( lua_State *L )
{
   LuaFaction lf;
   glTexture *tex;
   lf = luaL_validfaction(L,1);
   tex = faction_logoTiny( lf );
   if (tex == NULL)
      return 0;
   lua_pushtex( L, gl_dupTexture( tex ) );
   return 1;
}


/**
 * @brief Gets the faction colour.
 *
 *    @luatparam Faction f Faction to get colour from.
 *    @luatreturn Colour|nil The faction colour or nil if not applicable.
 * @luafunc colour
 */
static int factionL_colour( lua_State *L )
{
   LuaFaction lf;
   const glColour *col;
   lf = luaL_validfaction(L,1);
   col = faction_getColour(lf);
   if (col == NULL)
      return 0;
   lua_pushcolour( L, *col );
   return 1;
}


/**
 * @brief Gets the faction's prefix based on relation to the player.
 *
 * This returns a string which can be used to prefix references to the
 * faction. It contains a color character, plus a symbol which shows the
 * same information for colorblind accessibility. Note that you may need
 * to also append the string "#0" after the text you are prefixing with
 * this to reset the text color.
 *
 * @usage s = f:getPrefix() .. f:name() .. "#0"
 *
 *    @luatparam Faction f Faction to get the prefix of.
 *    @luatreturn string The prefix.
 * @luafunc getPrefix
 */
static int factionL_getPrefix(lua_State *L)
{
   LuaFaction f;
   char str[STRMAX_SHORT];

   f = luaL_validfaction(L, 1);

   snprintf(str, sizeof(str), "#%c%s",
         faction_getColourChar(f), faction_getSymbol(f));
   lua_pushstring(L, str);

   return 1;
}


/**
 * @brief Checks to see if a faction is known by the player.
 *
 * @usage b = f:known()
 *
 *    @luatparam Faction f Faction to check if the player knows.
 *    @luatreturn boolean true if the player knows the faction.
 * @luafunc known
 */
static int factionL_isknown( lua_State *L )
{
   LuaFaction fac = luaL_validfaction(L, 1);
   lua_pushboolean(L, faction_isKnown(fac));
   return 1;
}


/**
 * @brief Sets a faction's known state.
 *
 * @usage f:setKnown( false ) -- Makes faction unknown.
 *    @luatparam Faction f Faction to set known.
 *    @luatparam[opt=true] boolean b Whether or not to set as known.
 * @luafunc setKnown
 */
static int factionL_setknown( lua_State *L )
{
   LuaFaction fac;
   int b;

   NLUA_CHECKRW(L);
   fac = luaL_validfaction(L, 1);

   if (lua_gettop(L) >= 2)
      b = lua_toboolean(L, 2);
   else
      b = 1;

   faction_setKnown( fac, b );
   return 0;
}


/**
 * @brief Adds a faction dynamically.
 *
 * <p>The dynamically added faction lasts until a new system is entered,
 * or until the game exits, whichever is sooner. You can safely call
 * this again even if the dynamic faction has already been created, in
 * which case the already existing dynamic faction will be returned.
 * However, the dynamic faction must not be the same name as a
 * non-dynamic faction; attempting to create a dynamic faction with the
 * same name as a non-dynamic faction will result in an error.</p>
 *
 * <p>If "base" is non-nil, the following is copied from the base
 * faction:</p>
 *
 * <ul>
 *    <li>The faction's default AI, unless another is specified by the
 *       "ai" argument.</li>
 *    <li>The faction's allies, unless cleared by the "clear_allies"
 *       argument.</li>
 *    <li>The faction's enemies, unless cleared by the "clear_enemies"
 *       argument.</li>
 *    <li>The faction's logo.</li>
 *    <li>The faction's player standing.</li>
 *    <li>The faction's color.</li>
 *    <li>The faction's equip script.</li>
 * </ul>
 *
 * <p>The "params" parameter fine-tunes the dynamic faction, but only if
 * the function call is actually creating the faction (rather than
 * returning a previously existing dynamic faction), i.e. these options
 * only apply at the time the faction is actually created and cannot be
 * configured afterward. The following arguments can be passed to the
 * "params" parameter:</p>
 *
 * <ul>
 *    <li>"ai" (string): Default AI to give to pilots of the faction.
 *       This should be considered required if not basing the faction on
 *       another faction, as creating a pilot with no AI can lead to
 *       weird results.</li>
 *    <li>"clear_allies" (boolean): Whether or not to clear all allies
 *       from the faction on creation (useful only if basing the faction
 *       on another faction).</li>
 *    <li>"clear_enemies" (boolean): Whether or not to clear all enemies
 *       from the faction on creation (useful only if basing the faction
 *       on another faction).</li>
 * </ul>
 *
 * @note Created faction is known by default.
 *
 *    @luatparam Faction|string|nil base Faction or raw (untranslated)
 *       name of faction to base it off of or nil for no base faction.
 *    @luatparam string name Raw (untranslated) name to give the
 *       faction.
 *    @luatparam[opt] string display Raw (untranslated) display name to
 *       give the faction.
 *    @luatparam[opt] table params Table of extra keyword arguments. See
 *       above for supported arguments.
 *    @luatreturn Faction The added faction or the already existing
 *       dynamic faction with the same name.
 * @luafunc dynAdd
 */
static int factionL_dynAdd( lua_State *L )
{
   LuaFaction fac, newfac;
   const char *name, *display, *ai;
   int clear_allies, clear_enemies;

   NLUA_CHECKRW(L);

   if (!lua_isnoneornil(L, 1))
      fac = luaL_validfaction(L,1);
   else
      fac = 0;
   name     = luaL_checkstring(L,2);
   display  = luaL_optstring(L,3,name);

   /* Parse parameters. */
   if (lua_istable(L,4)) {
      lua_getfield(L,4,"ai");
      ai    = luaL_optstring(L,-1,NULL);
      lua_pop(L,1);

      lua_getfield(L,4,"clear_allies");
      clear_allies = lua_toboolean(L,-1);
      lua_pop(L,1);

      lua_getfield(L,4,"clear_enemies");
      clear_enemies = lua_toboolean(L,-1);
      lua_pop(L,1);
   }
   else {
      ai             = NULL;
      clear_allies   = 0;
      clear_enemies  = 0;
   }

   /* Check if exists. */
   if (faction_exists(name)) {
      /* Faction exists; attempt to use the existing faction. */
      newfac = faction_get(name);
      if (!faction_isDynamic(newfac)) {
         NLUA_ERROR(L, _("Faction '%s' already exists!"), name);
         return 0;
      }
   }
   else {
      /* Create new faction. */
      newfac = faction_dynAdd(fac, name, display, ai);

      /* Clear if necessary. */
      if (clear_allies)
         faction_clearAlly(newfac);
      if (clear_enemies)
         faction_clearEnemy(newfac);
   }

   lua_pushfaction(L, newfac);

   return 1;
}


/**
 * @brief Sets whether a faction is an ally of a dynamic faction.
 *
 * Both factions will be adjusted, but the first faction <em>must</em>
 * be a dynamic faction. The second faction can be any faction. This
 * restriction is in place because the changes do not persist in between
 * game sessions. To adjust ally status of permanent factions, use the
 * unidiff system instead.
 *
 *    @luatparam Faction fac Dynamic faction to adjust.
 *    @luatparam Faction ally Faction to adjust ally status of.
 *    @luatparam[opt=true] boolean enable true to make the factions
 *       allies, false to make the factions not allies.
 * @luafunc dynAlly
 */
static int factionL_dynAlly( lua_State *L )
{
   LuaFaction fac, ally;
   int enable;

   NLUA_CHECKRW(L);
   fac = luaL_validfaction(L,1);
   if (!faction_isDynamic(fac))
      NLUA_ERROR(L,_("Can only add allies to dynamic factions"));
   ally = luaL_validfaction(L,2);

   if (lua_gettop(L) >= 3)
      enable = lua_toboolean(L,3);
   else
      enable = 1;

   if (enable)
      faction_addAlly(fac, ally);
   else
      faction_rmAlly(fac, ally);
   return 0;
}


/**
 * @brief Sets whether a faction is an enemy of a dynamic faction.
 *
 * Both factions will be adjusted, but the first faction <em>must</em>
 * be a dynamic faction. The second faction can be any faction. This
 * restriction is in place because the changes do not persist in between
 * game sessions. To adjust enemy status of permanent factions, use the
 * unidiff system instead.
 *
 *    @luatparam Faction fac Dynamic faction to adjust.
 *    @luatparam Faction enemy Faction to adjust enemy status of.
 *    @luatparam[opt=true] boolean enable true to make the factions
 *       enemies, false to make the factions not enemies.
 * @luafunc dynEnemy
 */
static int factionL_dynEnemy( lua_State *L )
{
   LuaFaction fac, enemy;
   int enable;

   NLUA_CHECKRW(L);
   fac = luaL_validfaction(L,1);
   if (!faction_isDynamic(fac))
      NLUA_ERROR(L,_("Can only add allies to dynamic factions"));
   enemy = luaL_validfaction(L,2);

   if (lua_gettop(L) >= 3)
      enable = lua_toboolean(L,3);
   else
      enable = 1;

   if (enable)
      faction_addEnemy(fac, enemy);
   else
      faction_rmEnemy(fac, enemy);
   return 0;
}
