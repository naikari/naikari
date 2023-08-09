/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file nlua_naik.c
 *
 * @brief Contains Naikari generic Lua bindings.
 */

/** @cond */
#include <lauxlib.h>

#include "naev.h"
/** @endcond */

#include "nlua_naik.h"

#include "hook.h"
#include "input.h"
#include "land.h"
#include "log.h"
#include "nlua_evt.h"
#include "nlua_misn.h"
#include "nluadef.h"
#include "nstring.h"
#include "player.h"


static int cache_table = LUA_NOREF; /* No reference. */


/* Naikari methods. */
static int naikL_version(lua_State *L);
static int naikL_language(lua_State *L);
static int naikL_lastplayed(lua_State *L);
static int naikL_ticks(lua_State *L);
static int naikL_keyGet(lua_State *L);
static int naikL_keyEnable(lua_State *L);
static int naikL_keyEnableAll(lua_State *L);
static int naikL_keyDisableAll(lua_State *L);
static int naikL_eventStart(lua_State *L);
static int naikL_missionStart(lua_State *L);
static int naikL_hookTrigger(lua_State *L);
static int naikL_conf(lua_State *L);
static int naikL_cache(lua_State *L);
static const luaL_Reg naik_methods[] = {
   {"version", naikL_version},
   {"language", naikL_language},
   {"lastplayed", naikL_lastplayed},
   {"ticks", naikL_ticks},
   {"keyGet", naikL_keyGet},
   {"keyEnable", naikL_keyEnable},
   {"keyEnableAll", naikL_keyEnableAll},
   {"keyDisableAll", naikL_keyDisableAll},
   {"eventStart", naikL_eventStart},
   {"missionStart", naikL_missionStart},
   {"hookTrigger", naikL_hookTrigger},
   {"conf", naikL_conf},
   {"cache", naikL_cache},
   {0, 0}
}; /**< Naikari Lua methods. */


/**
 * @brief Loads the Naikari Lua library.
 *
 *    @param env Lua environment.
 *    @return 0 on success.
 */
int nlua_loadNaev( nlua_env env )
{
   nlua_register(env, "naik", naik_methods, 0);

   /* Create cache. */
   if (cache_table == LUA_NOREF) {
      lua_newtable(naevL);
      cache_table = luaL_ref(naevL, LUA_REGISTRYINDEX);
   }

   return 0;
}

/**
 * @brief Naikari generic Lua bindings.
 *
 * @luamod naik
 */

/**
 * @brief Gets the version of Naikari and the save game.
 *
 * @usage game_version, save_version = naik.version()
 *
 *    @luatreturn game_version The version of the game.
 *    @luatreturn save_version Version of current loaded save or nil if not loaded.
 * @luafunc version
 */
static int naikL_version(lua_State *L)
{
   lua_pushstring( L, naev_version(0) );
   if (player.loaded_version==NULL)
      lua_pushnil( L );
   else
      lua_pushstring( L, player.loaded_version );
   return 2;
}


/**
 * @brief Gets the current language locale.
 *
 *    @luatreturn string Current language locale (such as "en" for
 *       English, "de" for German, or "ja" for Japanese).
 * @luafunc language
 */
static int naikL_language(lua_State *L)
{
   lua_pushstring(L, gettext_getLanguage());
   return 1;
}


/**
 * @brief Gets how many days it has been since the player last played.
 *
 *    @luatreturn number Number of days since the player last played.
 * @luafunc lastplayed
 */
static int naikL_lastplayed(lua_State *L)
{
   double d = difftime( time(NULL), player.last_played );
   lua_pushnumber(L, d/(3600.*24.)); /*< convert to days */
   return 1;
}


/**
 * @brief Gets the SDL ticks.
 *
 * Useful for doing timing on Lua functions.
 *
 *    @luatreturn number The SDL ticks since the application started running.
 * @luafunc ticks
 */
static int naikL_ticks(lua_State *L)
{
   lua_pushinteger(L, SDL_GetTicks());
   return 1;
}


/**
 * @brief Gets a human-readable name for the key bound to a function.
 *
 * @usage bindname = naik.keyGet("accel")
 *
 *    @luatparam string keyname Name of the keybinding to get value of. Valid values are listed in src/input.c: keybind_info.
 * @luafunc keyGet
 */
static int naikL_keyGet(lua_State *L)
{
   const char *keyname;
   char buf[128];

   /* Get parameters. */
   keyname = luaL_checkstring( L, 1 );

   input_getKeybindDisplay( keyname, buf, sizeof(buf) );
   lua_pushstring( L, buf );

   return 1;
}


/**
 * @brief Disables or enables a specific keybinding.
 *
 * Use with caution, this can make the player get stuck.
 *
 * @usage naik.keyEnable("accel", false) -- Disables the acceleration key
 *    @luatparam string keyname Name of the key to disable (for example "accel").
 *    @luatparam[opt=false] boolean enable Whether to enable or disable.
 * @luafunc keyEnable
 */
static int naikL_keyEnable(lua_State *L)
{
   const char *key;
   int enable;

   NLUA_CHECKRW(L);

   /* Parameters. */
   key = luaL_checkstring(L,1);
   enable = lua_toboolean(L,2);

   input_toggleEnable( key, enable );
   return 0;
}


/**
 * @brief Enables all inputs.
 *
 * @usage naik.keyEnableAll() -- Enables all inputs
 * @luafunc keyEnableAll
 */
static int naikL_keyEnableAll(lua_State *L)
{
   NLUA_CHECKRW(L);
   input_enableAll();
   return 0;
}


/**
 * @brief Disables all inputs.
 *
 * @usage naik.keyDisableAll() -- Disables all inputs
 * @luafunc keyDisableAll
 */
static int naikL_keyDisableAll(lua_State *L)
{
   NLUA_CHECKRW(L);
   input_disableAll();
   return 0;
}


/**
 * @brief Starts an event, does not start check conditions.
 *
 * @usage naik.eventStart("Some Event")
 *    @luatparam string evtname Name of the event to start.
 *    @luatreturn boolean true on success.
 * @luafunc eventStart
 */
static int naikL_eventStart(lua_State *L)
{
   int ret;
   const char *str;

   NLUA_CHECKRW(L);

   str = luaL_checkstring(L, 1);
   ret = event_start( str, NULL );

   /* Get if console. */
   nlua_getenv(__NLUA_CURENV, "__cli");
   if (lua_toboolean(L,-1) && landed)
      bar_regen();
   lua_pop(L,1);

   lua_pushboolean( L, !ret );
   return 1;
}


/**
 * @brief Starts a mission, does no check start conditions.
 *
 * @usage naik.missionStart("Some Mission")
 *    @luatparam string misnname Name of the mission to start.
 *    @luatreturn boolean true on success.
 * @luafunc missionStart
 */
static int naikL_missionStart(lua_State *L)
{
   int ret;
   const char *str;

   NLUA_CHECKRW(L);

   str = luaL_checkstring(L, 1);
   ret = mission_start( str, NULL );

   /* Get if console. */
   nlua_getenv(__NLUA_CURENV, "__cli");
   if (lua_toboolean(L,-1) && landed)
      bar_regen();
   lua_pop(L,1);

   lua_pushboolean( L, !ret );
   return 1;
}


/**
 * @brief Manually triggers a hook.
 *
 * This is run deferred (next frame) globally (i.e. it affects all
 * missions and events). Meant mainly to be used with hook.custom(), but
 * can work with other hooks too (if you know what you are doing).
 *
 *    @luatparam string hookname Name of the hook to be run.
 *    @luatparam[opt] nil|number|boolean|string|Pilot|Faction|Planet|Jump
 *       params Arguments to pass to the hook's parameters. You can pass
 *       multiple arguments, but this is limited by HOOK_MAX_PARAM
 *       (which is defined in hook.h).
 * @luasee hook.custom
 * @luafunc hookTrigger
 */
static int naikL_hookTrigger(lua_State *L)
{
   const int param_pos = 2; /**< Position of the first hook param. */
   int i, n;
   HookParam hp[HOOK_MAX_PARAM];
   HookParam *p;
   const char *hookname = luaL_checkstring(L, 1);
   n = lua_gettop(L) - 1;

   /* Set up hooks. */
   for (i=0; i<MIN(n, HOOK_MAX_PARAM-1); i++) {
      p = &hp[i];
      switch (lua_type(L, i + param_pos)) {
         case LUA_TNIL:
            p->type = HOOK_PARAM_NIL;
            break;
         case LUA_TNUMBER:
            p->type = HOOK_PARAM_NUMBER;
            p->u.num = lua_tonumber(L, i + param_pos);
            break;
         case LUA_TBOOLEAN:
            p->type = HOOK_PARAM_BOOL;
            p->u.b = lua_toboolean(L, i + param_pos);
            break;
         case LUA_TSTRING:
            p->type = HOOK_PARAM_STRING;
            p->u.str = lua_tostring(L, i + param_pos);
            break;
         case LUA_TUSERDATA:
            if (lua_ispilot(L, i + param_pos)) {
               p->type = HOOK_PARAM_PILOT;
               p->u.lp = lua_topilot(L, i + param_pos);
            }
            else if (lua_isfaction(L, i + param_pos)) {
               p->type = HOOK_PARAM_FACTION;
               p->u.lf = lua_tofaction(L, i + param_pos);
            }
            else if (lua_isplanet(L, i + param_pos)) {
               p->type = HOOK_PARAM_ASSET;
               p->u.la = *lua_toplanet(L, i + param_pos);
            }
            else if (lua_isjump(L, i + param_pos)) {
               p->type = HOOK_PARAM_JUMP;
               p->u.lj = *lua_tojump(L, i + param_pos);
            }
            break;
         default:
            NLUA_ERROR(L, _("Unsupported Lua hook paramater type '%s'!"),
                  lua_typename(L,i+1));
      }
   }
   hp[i].type = HOOK_PARAM_SENTINEL;

   /* Run the deferred hooks. */
   hooks_runParamDeferred(hookname, hp);
   return 0;
}


#define PUSH_STRING( L, name, value ) \
lua_pushstring( L, name ); \
lua_pushstring( L, value ); \
lua_rawset( L, -3 )
#define PUSH_DOUBLE( L, name, value ) \
lua_pushstring( L, name ); \
lua_pushnumber( L, value ); \
lua_rawset( L, -3 )
#define PUSH_INT( L, name, value ) \
lua_pushstring( L, name ); \
lua_pushinteger( L, value ); \
lua_rawset( L, -3 )
#define PUSH_BOOL( L, name, value ) \
lua_pushstring( L, name ); \
lua_pushboolean( L, value ); \
lua_rawset( L, -3 )
/**
 * @brief Gets the configuration information.
 *
 *    @luatreturn table Table of configuration values as they appear in the configuration file.
 * @luafunc conf
 */
static int naikL_conf(lua_State *L)
{
   lua_newtable(L);
   PUSH_STRING( L, "data", conf.ndata );
   PUSH_STRING( L, "language", conf.language );
   PUSH_INT( L, "fsaa", conf.fsaa );
   PUSH_BOOL( L, "vsync", conf.vsync );
   PUSH_INT( L, "width", conf.width );
   PUSH_INT( L, "height", conf.height );
   PUSH_DOUBLE( L, "scalefactor", conf.scalefactor );
   PUSH_DOUBLE( L, "nebu_scale", conf.nebu_scale );
   PUSH_BOOL( L, "fullscreen", conf.fullscreen );
   PUSH_BOOL( L, "modesetting", conf.modesetting );
   PUSH_BOOL( L, "borderless", conf.borderless );
   PUSH_BOOL( L, "minimize", conf.minimize );
   PUSH_BOOL( L, "colorblind", conf.colorblind );
   PUSH_DOUBLE( L, "bg_brightness", conf.bg_brightness );
   PUSH_DOUBLE( L, "gamma_correction", conf.gamma_correction );
   PUSH_BOOL( L, "showfps", conf.fps_show );
   PUSH_INT( L, "maxfps", conf.fps_max );
   PUSH_BOOL( L, "showpause", conf.pause_show );
   PUSH_BOOL( L, "al_efx", conf.al_efx );
   PUSH_BOOL( L, "nosound", conf.nosound );
   PUSH_DOUBLE( L, "sound", conf.sound );
   PUSH_DOUBLE( L, "music", conf.music );
   /* joystick */
   PUSH_INT( L, "mesg_visible", conf.mesg_visible );
   PUSH_DOUBLE( L, "map_overlay_opacity", conf.map_overlay_opacity );
   PUSH_INT( L, "repeat_delay", conf.repeat_delay );
   PUSH_INT( L, "repeat_freq", conf.repeat_freq );
   PUSH_BOOL( L, "zoom_manual", conf.zoom_manual );
   PUSH_DOUBLE( L, "zoom_far", conf.zoom_far );
   PUSH_DOUBLE( L, "zoom_near", conf.zoom_near );
   PUSH_DOUBLE( L, "zoom_speed", conf.zoom_speed );
   PUSH_DOUBLE( L, "zoom_stars", conf.zoom_stars );
   PUSH_INT( L, "font_size_console", conf.font_size_console );
   PUSH_INT( L, "font_size_intro", conf.font_size_intro );
   PUSH_INT( L, "font_size_def", conf.font_size_def );
   PUSH_INT( L, "font_size_small", conf.font_size_small );
   PUSH_DOUBLE( L, "compression_velocity", conf.compression_velocity );
   PUSH_DOUBLE( L, "compression_mult", conf.compression_mult );
   PUSH_BOOL( L, "redirect_file", conf.redirect_file );
   PUSH_BOOL( L, "save_compress", conf.save_compress );
   PUSH_INT(L, "doubletap_afterburn", conf.doubletap_afterburn);
   PUSH_DOUBLE( L, "mouse_doubleclick", conf.mouse_doubleclick );
   PUSH_DOUBLE( L, "autonav_abort", conf.autonav_reset_speed );
   PUSH_BOOL( L, "devmode", conf.devmode );
   PUSH_BOOL( L, "devautosave", conf.devautosave );
   PUSH_BOOL( L, "conf_nosave", conf.nosave );
   PUSH_BOOL( L, "fpu_except", conf.fpu_except );
   PUSH_STRING( L, "dev_save_sys", conf.dev_save_sys );
   PUSH_STRING( L, "dev_save_map", conf.dev_save_map );
   PUSH_STRING( L, "dev_save_asset", conf.dev_save_asset );
   return 1;
}
#undef PUSH_STRING
#undef PUSH_DOUBLE
#undef PUSH_INT
#undef PUSH_BOOL


/**
 * @brief Gets the global Lua runtime cache. This is shared among all
 * environments and is cleared when the game is closed.
 *
 * @usage c = naik.cache()
 *
 *    @luatreturn table The Lua global cache.
 * @luafunc cache
 */
static int naikL_cache(lua_State *L)
{
   lua_rawgeti( L, LUA_REGISTRYINDEX, cache_table );
   return 1;
}
