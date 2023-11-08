/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file faction.c
 *
 * @brief Handles the Naev factions.
 */


/** @cond */
#include <assert.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "faction.h"

#include "array.h"
#include "colour.h"
#include "hook.h"
#include "log.h"
#include "ndata.h"
#include "nlua.h"
#include "nluadef.h"
#include "nxml.h"
#include "nstring.h"
#include "player.h"
#include "opengl.h"
#include "rng.h"
#include "space.h"


#define XML_FACTION_ID     "Factions"   /**< XML section identifier */
#define XML_FACTION_TAG    "faction" /**< XML tag identifier. */


#define FACTION_STATIC        (1<<0) /**< Faction doesn't change standing with player. */
#define FACTION_INVISIBLE     (1<<1) /**< Faction isn't exposed to the player. */
#define FACTION_KNOWN         (1<<2) /**< Faction is known to the player. */
#define FACTION_DYNAMIC       (1<<3) /**< Faction was created dynamically. */

#define faction_setFlag(fa,f) ((fa)->flags |= (f))
#define faction_rmFlag(fa,f)  ((fa)->flags &= ~(f))
#define faction_isFlag(fa,f)  ((fa)->flags & (f))
#define faction_isKnown_(fa)   ((fa)->flags & (FACTION_KNOWN))

/**
 * @struct Faction
 *
 * @brief Represents a faction.
 */
typedef struct Faction_ {
   factionId_t id; /**< Faction's id. */
   char *name; /**< Normal Name. */
   char *longname; /**< Long Name. */
   char *displayname; /**< Display name. */
   char *ai; /**< Name of the faction's default pilot AI. */

   /* Graphics. */
   glTexture *logo_small; /**< Small logo. */
   glTexture *logo_tiny; /**< Tiny logo. */
   glColour colour; /**< Faction specific colour. */

   /* Enemies */
   factionId_t *enemies; /**< Enemies by ID of the faction. */

   /* Allies */
   factionId_t *allies; /**< Allies by ID of the faction. */

   /* Player information. */
   double player_def; /**< Default player standing. */
   double player; /**< Standing with player - from -100 to 100 */

   /* Scheduler. */
   nlua_env sched_env; /**< Lua scheduler script. */

   /* Behaviour. */
   nlua_env env; /**< Faction specific environment. */

   /* Equipping. */
   nlua_env equip_env; /**< Faction equipper enviornment. */

   /* Flags. */
   unsigned int flags; /**< Flags affecting the faction. */
   unsigned int oflags; /**< Original flags (for when new game is started). */
} Faction;

static Faction **faction_stack = NULL; /**< Faction stack. */


/* ID Generators. */
static factionId_t faction_id = FACTION_PLAYER; /**< Stack of faction ids to assure uniqueness */


/*
 * Prototypes
 */
/* static */
static int faction_getStackPos(const factionId_t id);
static factionId_t faction_getRaw(const char *name);
static int faction_sortCompare(const void *p1, const void *p2);
static void faction_freeOne( Faction *f );
static void faction_sanitizePlayer( Faction* faction );
static void faction_modPlayerLua(factionId_t f, double mod,
      const char *source, int secondary);
static int faction_parse( Faction* temp, xmlNodePtr parent );
static void faction_parseSocial( xmlNodePtr parent );
static void faction_addStandingScript( Faction* temp, const char* scriptname );
/* externed */
int pfaction_save( xmlTextWriterPtr writer );
int pfaction_load( xmlNodePtr parent );


/**
 * @brief Gets the faction's position in the stack.
 *
 *    @param id ID of the faction to get.
 *    @return Position of faction in stack or -1 if not found.
 */
static int faction_getStackPos(const factionId_t id)
{
   int i;

   for (i=0; i<array_size(faction_stack); i++) {
      if (faction_stack[i]->id == id)
         return i;
   }

   return -1;
}


/**
 * @brief Gets a faction ID by name.
 *
 *    @param name Name of the faction to seek.
 *    @return ID of the faction.
 */
static factionId_t faction_getRaw(const char* name)
{
   int i;
   /* Escorts are part of the "player" faction. */
   if (strcmp(name, "Escort") == 0)
      return FACTION_PLAYER;

   if (name != NULL) {
      for (i=0; i<array_size(faction_stack); i++) {
         if (strcmp(faction_stack[i]->name, name) == 0)
            return faction_stack[i]->id;
      }
   }
   return 0;
}


/**
 * @brief qsort compare function for faction stack.
 */
static int faction_sortCompare(const void *p1, const void *p2)
{
   Faction *f1, *f2;
   double presence1, presence2;

   f1 = *(Faction**)p1;
   f2 = *(Faction**)p2;

   /* Sort by current system presence (higher presences first). */
   presence1 = system_getPresence(cur_system, f1->id);
   presence2 = system_getPresence(cur_system, f2->id);
   if (presence1 > presence2)
      return -1;
   else if (presence1 < presence2)
      return +1;

   /* Don't care about any other factors. */
   return 0;
}


/**
 * @brief Sorts factions to optimize performance for current system.
 *
 * This prioritizes moving factions to the top of the faction stack if
 * they have higher presence in the current system. This increases the
 * average efficiency of faction_getStackPos().
 */
void factions_sort(void)
{
   if (cur_system == NULL) {
      WARN(_("Attempted to sort factions with no cur_system set."));
      return;
   }

   qsort(faction_stack, array_size(faction_stack), sizeof(Faction*),
         faction_sortCompare);
}


/**
 * @brief Checks to see if a faction exists by name.
 *
 *    @param name Name of the faction to seek.
 *    @return ID of the faction.
 */
int faction_exists(const char* name)
{
   return faction_getRaw(name) != 0;
}


/**
 * @brief Gets a faction ID by name.
 *
 *    @param name Name of the faction to seek.
 *    @return ID of the faction.
 */
factionId_t faction_get(const char* name)
{
   factionId_t id = faction_getRaw(name);
   if (!faction_isFaction(id))
      WARN(_("Faction '%s' not found in stack."), name);
   return id;
}


/**
 * @brief Returns all faction IDs in an array (array.h).
 */
factionId_t* faction_getAll()
{
   int i;
   factionId_t *f;

   f = array_create_size(factionId_t, array_size(faction_stack));

   for (i=0; i<array_size(faction_stack); i++)
      if (!faction_isFlag(faction_stack[i], FACTION_INVISIBLE))
         array_push_back(&f, faction_stack[i]->id);

   return f;
}

/**
 * @brief Gets all the known factions in an array (array.h).
 */
factionId_t* faction_getKnown()
{
   int i;
   factionId_t *f;

   /* Set up. */
   f = array_create_size(factionId_t, array_size(faction_stack));

   /* Get IDs. */
   for (i=0; i<array_size(faction_stack); i++)
      if (!faction_isFlag(faction_stack[i], FACTION_INVISIBLE)
            && faction_isKnown_(faction_stack[i]))
         array_push_back(&f, faction_stack[i]->id);

   return f;
}

/**
 * @brief Clears the known factions.
 */
void faction_clearKnown()
{
   int i;

   for (i=0; i<array_size(faction_stack); i++)
      if (faction_isKnown_(faction_stack[i]))
         faction_rmFlag(faction_stack[i], FACTION_KNOWN);
}

/**
 * @brief Is the faction invisible?
 */
int faction_isInvisible(factionId_t id)
{
   int i;

   i = faction_getStackPos(id);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), id);
      return 0;
   }

   return faction_isFlag(faction_stack[i], FACTION_INVISIBLE);
}

/**
 * @brief Sets the faction's invisible state
 */
int faction_setInvisible(factionId_t id, int state)
{
   int i;

   i = faction_getStackPos(id);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), id);
      return -1;
   }
   if (state)
      faction_setFlag(faction_stack[i], FACTION_INVISIBLE);
   else
      faction_rmFlag(faction_stack[i], FACTION_INVISIBLE);

   return 0;
}

/**
 * @brief Is the faction known?
 */
int faction_isKnown(factionId_t id)
{
   int i;

   i = faction_getStackPos(id);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), id);
      return 0;
   }

   return faction_isKnown_(faction_stack[i]);
}


/**
 * @brief Is faction dynamic.
 */
int faction_isDynamic(factionId_t id)
{
   int i;

   i = faction_getStackPos(id);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), id);
      return 0;
   }

   return faction_isFlag(faction_stack[i], FACTION_DYNAMIC);
}

/**
 * @brief Sets the factions known state
 */
int faction_setKnown(factionId_t id, int state)
{
   int i;

   i = faction_getStackPos(id);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), id);
      return -1;
   }

   if (state)
      faction_setFlag(faction_stack[i], FACTION_KNOWN);
   else
      faction_rmFlag(faction_stack[i], FACTION_KNOWN);

   return 0;
}

/**
 * @brief Gets a factions "real" (internal) name.
 *
 *    @param f Faction to get the name of.
 *    @return Name of the faction (internal/English).
 */
const char* faction_name(factionId_t f)
{
   int i;

   /* Don't want player to see their escorts as "Player" faction. */
   if (f == FACTION_PLAYER)
      return N_("Escort");

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   return faction_stack[i]->name;
}


/**
 * @brief Gets a factions short name (human-readable).
 *
 *    @param f Faction to get the name of.
 *    @return Name of the faction (in player's native language).
 */
const char* faction_shortname(factionId_t f)
{
   int i;

   /* Don't want player to see their escorts as "Player" faction. */
   if (f == FACTION_PLAYER)
      return N_("Escort");

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   /* Possibly get display name. */
   if (faction_stack[i]->displayname != NULL)
      return _(faction_stack[i]->displayname);

   return _(faction_stack[i]->name);
}


/**
 * @brief Gets the faction's long name (formal, human-readable).
 *
 *    @param f Faction to get the name of.
 *    @return The faction's long name (in player's native language).
 */
const char* faction_longname(factionId_t f)
{
   int i;

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   if (faction_stack[i]->longname != NULL)
      return _(faction_stack[i]->longname);

   return _(faction_stack[i]->name);
}


/**
 * @brief Gets the name of the default AI profile for the faction's pilots.
 *
 *    @param f Faction ID.
 *    @return The faction's AI profile name.
 */
const char* faction_default_ai(factionId_t f)
{
   int i;

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   return faction_stack[i]->ai;
}


/**
 * @brief Gets the faction's small logo (64x64 or smaller).
 *
 *    @param f Faction to get the logo of.
 *    @return The faction's small logo image.
 */
glTexture* faction_logoSmall(factionId_t f)
{
   int i;

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   return faction_stack[i]->logo_small;
}


/**
 * @brief Gets the faction's tiny logo (24x24 or smaller).
 *
 *    @param f Faction to get the logo of.
 *    @return The faction's tiny logo image.
 */
glTexture* faction_logoTiny(factionId_t f)
{
   int i;

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   return faction_stack[i]->logo_tiny;
}


/**
 * @brief Gets the colour of the faction
 *
 *    @param f Faction to get the colour of.
 *    @return The faction's colour
 */
const glColour* faction_colour(factionId_t f)
{
   int i;

   i = faction_getStackPos(f);
   if (i < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   return &faction_stack[i]->colour;
}


/**
 * @brief Gets the list of enemies of a faction.
 *
 *    @param f Faction to get enemies of.
 *    @return Array (array.h): The enemies of the faction.
 */
factionId_t* faction_getEnemies(factionId_t f)
{
   int fsp;
   int i;
   factionId_t *enemies;
   factionId_t *tmp;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   /* Player's faction ratings can change, so regenerate each call. */
   if (f == FACTION_PLAYER) {
      enemies = array_create(factionId_t);

      for (i=0; i<array_size(faction_stack); i++)
         if (faction_isPlayerEnemy(faction_stack[i]->id)) {
            tmp = &array_grow(&enemies);
            *tmp = faction_stack[i]->id;
         }

      array_free(faction_stack[fsp]->enemies);
      faction_stack[fsp]->enemies = enemies;
   }

   return faction_stack[fsp]->enemies;
}


/**
 * @brief Gets the list of allies of a faction.
 *
 *    @param f Faction to get allies of.
 *    @return Array (array.h): The allies of the faction.
 */
factionId_t* faction_getAllies(factionId_t f)
{
   int fsp;
   int i;
   factionId_t *allies;
   factionId_t *tmp;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return NULL;
   }

   /* Player's faction ratings can change, so regenerate each call. */
   if (f == FACTION_PLAYER) {
      allies = array_create(factionId_t);

      for (i=0; i<array_size(faction_stack); i++)
         if (faction_isPlayerFriend(faction_stack[i]->id)) {
            tmp = &array_grow(&allies);
            *tmp = faction_stack[i]->id;
         }

      array_free(faction_stack[fsp]->allies);
      faction_stack[fsp]->allies = allies;
   }

   return faction_stack[fsp]->allies;
}


/**
 * @brief Clears all the enemies of a dynamic faction.
 *
 *    @param f Faction to clear enemies of.
 */
void faction_clearEnemy(factionId_t f)
{
   int fsp;
   Faction *ff;
   int i;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   ff = faction_stack[fsp];

   /* Cycle through the enemies and make sure they remove this faction
    * as an enemy first. */
   for (i=0; i<array_size(ff->enemies); i++) {
      faction_rmEnemy(ff->enemies[i], f);
   }

   array_erase(&ff->enemies, array_begin(ff->enemies), array_end(ff->enemies));
}


/**
 * @brief Adds an enemy to the faction's enemies list.
 *
 *    @param f The faction to add an enemy to.
 *    @param o The other faction to make an enemy.
 */
void faction_addEnemy(factionId_t f, factionId_t o)
{
   int fsp;
   Faction *ff;
   int i;
   factionId_t *tmp;

   if (f == o)
      return;

   /* player cannot be made an enemy this way */
   if (f == FACTION_PLAYER) {
      WARN(_("%ld is the player faction"), f);
      return;
   }
   if (o == FACTION_PLAYER) {
      WARN(_("%ld is the player faction"), o);
      return;
   }

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   ff = faction_stack[fsp];

   for (i=0; i<array_size(ff->enemies); i++) {
      if (ff->enemies[i] == o)
         return;
   }

   tmp = &array_grow(&ff->enemies);
   *tmp = o;
}


/**
 * @brief Removes an enemy from the faction's enemies list.
 *
 *    @param f The faction to remove an enemy from.
 *    @param o The other faction to remove as an enemy.
 */
void faction_rmEnemy(factionId_t f, factionId_t o)
{
   int fsp;
   Faction *ff;
   int i;

   if (f == o)
      return;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   ff = faction_stack[fsp];

   for (i=0; i<array_size(ff->enemies); i++) {
      if (ff->enemies[i] == o) {
         array_erase(&ff->enemies, &ff->enemies[i], &ff->enemies[i+1]);
         return;
      }
   }
}


/**
 * @brief Clears all the ally of a dynamic faction.
 *
 *    @param f Faction to clear ally of.
 */
void faction_clearAlly(factionId_t f)
{
   int fsp;
   Faction *ff;
   int i;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   ff = faction_stack[fsp];

   /* Cycle through the allies and make sure they remove this faction
    * as an ally first. */
   for (i=0; i<array_size(ff->allies); i++) {
      faction_rmAlly(ff->allies[i], f);
   }

   array_erase(&ff->allies, array_begin(ff->allies), array_end(ff->allies));
}


/**
 * @brief Adds an ally to the faction's allies list.
 *
 *    @param f The faction to add an ally to.
 *    @param o The other faction to make an ally.
 */
void faction_addAlly(factionId_t f, factionId_t o)
{
   int fsp;
   Faction *ff;
   int i;
   factionId_t *tmp;

   /* player cannot be made an enemy this way */
   if (f == FACTION_PLAYER) {
      WARN(_("%ld is the player faction"), f);
      return;
   }
   if (o == FACTION_PLAYER) {
      WARN(_("%ld is the player faction"), o);
      return;
   }

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   ff = faction_stack[fsp];

   for (i=0; i<array_size(ff->allies); i++) {
      if (ff->allies[i] == o)
         return;
   }

   tmp = &array_grow(&ff->allies);
   *tmp = o;
}


/**
 * @brief Removes an ally from the faction's allies list.
 *
 *    @param f The faction to remove an ally from.
 *    @param o The other faction to remove as an ally.
 */
void faction_rmAlly(factionId_t f, factionId_t o)
{
   int fsp;
   Faction *ff;
   int i;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   ff = faction_stack[fsp];

   for (i=0; i<array_size(ff->allies); i++) {
      if (ff->allies[i] == o) {
         array_erase(&ff->allies, &ff->allies[i], &ff->allies[i+1]);
         return;
      }
   }
}


/**
 * @brief Gets the state associated to the faction scheduler.
 */
nlua_env faction_getScheduler(factionId_t f)
{
   int fsp;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return LUA_NOREF;
   }

   return faction_stack[fsp]->sched_env;
}


/**
 * @brief Gets the equipper state associated to the faction scheduler.
 */
nlua_env faction_getEquipper(factionId_t f)
{
   int fsp;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return LUA_NOREF;
   }

   return faction_stack[fsp]->equip_env;
}


/**
 * @brief Sanitizes player faction standing.
 *
 *    @param faction Faction to sanitize.
 */
static void faction_sanitizePlayer(Faction* faction)
{
   if (faction->player > 100.)
      faction->player = 100.;
   else if (faction->player < -100.)
      faction->player = -100.;
}


/**
 * @brief Mods player using the power of Lua.
 */
static void faction_modPlayerLua(factionId_t f, double mod,
      const char *source, int secondary)
{
   int fsp;
   Faction *faction;
   double old, delta;
   HookParam hparam[4];

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   faction = faction_stack[fsp];

   /* Make sure it's not static. */
   if (faction_isFlag(faction, FACTION_STATIC))
      return;

   /* Player is dead or cleared. */
   if (player.p == NULL)
      return;

   old = faction->player;

   if (faction->env == LUA_NOREF)
      faction->player += mod;
   else {

      /* Set up the function:
       * faction_hit(current, amount, source, secondary, fac) */
      nlua_getenv(faction->env, "faction_hit");
      lua_pushnumber(naevL, faction->player);
      lua_pushnumber(naevL, mod);
      lua_pushstring(naevL, source);
      lua_pushboolean(naevL, secondary);
      lua_pushfaction(naevL, faction->id);

      /* Call function. */
      if (nlua_pcall(faction->env, 5, 1)) {
         WARN(_("Faction '%s': %s"), faction->name, lua_tostring(naevL, -1));
         lua_pop(naevL, 1);
         return;
      }

      /* Parse return. */
      if (!lua_isnumber(naevL, -1))
         WARN(_("Lua script for faction '%s' did not return a number from"
                  " 'faction_hit(...)'."),
               faction->name);
      else
         faction->player = lua_tonumber(naevL, -1);
      lua_pop(naevL, 1);
   }

   /* Sanitize just in case. */
   faction_sanitizePlayer(faction);

   /* Run hook if necessary. */
   delta = faction->player - old;
   if (FABS(delta) > 1e-10) {
      hparam[0].type = HOOK_PARAM_FACTION;
      hparam[0].u.lf = f;
      hparam[1].type = HOOK_PARAM_NUMBER;
      hparam[1].u.num = delta;
      hparam[2].type = HOOK_PARAM_BOOL;
      hparam[2].u.b = secondary;
      hparam[3].type = HOOK_PARAM_SENTINEL;
      hooks_runParam("standing", hparam);

      /* Tell space the faction changed. */
      space_factionChange();
   }
}


/**
 * @brief Modifies the player's standing with a faction.
 *
 * Affects enemies and allies too.
 *
 *    @param f Faction to modify player's standing.
 *    @param mod Modifier to modify by.
 *    @param source Source of the faction modifier.
 *
 *   Possible sources:
 *    - "kill" : Pilot death.
 *    - "distress" : Pilot distress signal.
 *    - "script" : Either a mission or an event.
 *
 */
void faction_modPlayer(factionId_t f, double mod, const char *source)
{
   int fsp;
   int i;
   Faction *faction;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   faction = faction_stack[fsp];

   /* Modify faction standing with parent faction. */
   faction_modPlayerLua(f, mod, source, 0);

   /* Now mod allies to a lesser degree */
   for (i=0; i<array_size(faction->allies); i++)
      /* Modify faction standing */
      faction_modPlayerLua(faction->allies[i], mod, source, 1);

   /* Now mod enemies */
   for (i=0; i<array_size(faction->enemies); i++)
      /* Modify faction standing. */
      faction_modPlayerLua(faction->enemies[i], -mod, source, 1);
}

/**
 * @brief Modifies the player's standing without affecting others.
 *
 * Does not affect allies nor enemies.
 *
 *    @param f Faction whose standing to modify.
 *    @param mod Amount to modify standing by.
 *    @param source Source of the faction modifier.
 *
 *   Possible sources:
 *    - "kill" : Pilot death.
 *    - "distress" : Pilot distress signal.
 *    - "script" : Either a mission or an event.
 *
 * @sa faction_modPlayer
 */
void faction_modPlayerSingle(factionId_t f, double mod, const char *source)
{
   faction_modPlayerLua(f, mod, source, 0);
}


/**
 * @brief Modifies the player's standing without affecting others.
 *
 * Does not affect allies nor enemies and does not run through the Lua script.
 *
 *    @param f Faction whose standing to modify.
 *    @param mod Amount to modify standing by.
 *
 * @sa faction_modPlayer
 */
void faction_modPlayerRaw(factionId_t f, double mod)
{
   int fsp;
   Faction *faction;
   HookParam hparam[3];

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   faction = faction_stack[fsp];

   faction->player += mod;
   /* Run hook if necessary. */
   hparam[0].type = HOOK_PARAM_FACTION;
   hparam[0].u.lf = f;
   hparam[1].type = HOOK_PARAM_NUMBER;
   hparam[1].u.num = mod;
   hparam[2].type = HOOK_PARAM_SENTINEL;
   hooks_runParam("standing", hparam);

   /* Sanitize just in case. */
   faction_sanitizePlayer(faction);

   /* Tell space the faction changed. */
   space_factionChange();
}


/**
 * @brief Sets the player's standing with a faction.
 *
 *    @param f Faction to set the player's standing for.
 *    @param value Value to set the player's standing to.
 */
void faction_setPlayer(factionId_t f, double value)
{
   int fsp;
   Faction *faction;
   HookParam hparam[3];
   double mod;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return;
   }
   faction = faction_stack[fsp];

   mod = value - faction->player;
   faction->player = value;
   /* Run hook if necessary. */
   hparam[0].type = HOOK_PARAM_FACTION;
   hparam[0].u.lf = f;
   hparam[1].type = HOOK_PARAM_NUMBER;
   hparam[1].u.num = mod;
   hparam[2].type = HOOK_PARAM_SENTINEL;
   hooks_runParam("standing", hparam);

   /* Sanitize just in case. */
   faction_sanitizePlayer(faction);

   /* Tell space the faction changed. */
   space_factionChange();
}


/**
 * @brief Gets the player's standing with a faction.
 *
 *    @param f Faction to get player's standing from.
 *    @return The standing the player has with the faction.
 */
double faction_getPlayer(factionId_t f)
{
   int fsp;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return -100;
   }

   return faction_stack[fsp]->player;
}


/**
 * @brief Gets the player's default standing with a faction.
 *
 *    @param f Faction to get player's default standing from.
 *    @return The default standing the player has with the faction.
 */
double faction_getPlayerDef(factionId_t f)
{
   int fsp;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return -100;
   }

   return faction_stack[fsp]->player_def;
}


/**
 * @brief Gets whether or not the player is a friend of the faction.
 *
 *    @param f Faction to check friendliness of.
 *    @return 1 if the player is a friend, 0 otherwise.
 */
int faction_isPlayerFriend(factionId_t f)
{
   int fsp;
   Faction *faction;
   int r;

   /* Player faction is always friends with the player. */
   if (f == FACTION_PLAYER)
      return 1;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      /* This warning is disabled because it produces false positives
       * during cleanup of pilots. */
      //WARN(_("Faction id '%ld' is invalid."), f);
      return 0;
   }
   faction = faction_stack[fsp];

   if (faction->env == LUA_NOREF)
      return 0;
   else
   {
      /* Set up the function:
       * faction_player_friend( standing ) */
      nlua_getenv(faction->env, "faction_player_friend");
      lua_pushnumber( naevL, faction->player );

      /* Call function. */
      if (nlua_pcall(faction->env, 1, 1))
      {
         /* An error occurred. */
         WARN(_("Faction '%s': %s"), faction->name, lua_tostring(naevL, -1));
         lua_pop(naevL, 1);
         return 0;
      }

      /* Parse return. */
      if (!lua_isboolean(naevL, -1))
      {
         WARN(_("Lua script for faction '%s' did not return a boolean from"
                  " 'faction_player_friend(...)'."),
               faction->name);
         r = 0;
      }
      else
         r = lua_toboolean(naevL, -1);
      lua_pop(naevL, 1);

      return r;
   }
}


/**
 * @brief Gets whether or not the player is an enemy of the faction.
 *
 *    @param f Faction to check hostility of.
 *    @return 1 if the player is an enemy, 0 otherwise.
 */
int faction_isPlayerEnemy(factionId_t f)
{
   int fsp;
   Faction *faction;
   int r;

   /* Player faction is never enemies with the player. */
   if (f == FACTION_PLAYER)
      return 0;

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      /* This warning is disabled because it produces false positives
       * during cleanup of pilots. */
      //WARN(_("Faction id '%ld' is invalid."), f);
      return 0;
   }
   faction = faction_stack[fsp];

   if (faction->env == LUA_NOREF)
      return 0;
   else
   {
      /* Set up the function:
       * faction_player_enemy( standing ) */
      nlua_getenv(faction->env, "faction_player_enemy");
      lua_pushnumber(naevL, faction->player);

      /* Call function. */
      if (nlua_pcall(faction->env, 1, 1))
      {
         /* An error occurred. */
         WARN(_("Faction '%s': %s"), faction->name, lua_tostring(naevL, -1));
         lua_pop(naevL, 1);
         return 0;
      }

      /* Parse return. */
      if (!lua_isboolean(naevL, -1))
      {
         WARN(_("Lua script for faction '%s' did not return a boolean from"
                  " 'faction_player_enemy(...)'."),
               faction->name);
         r = 0;
      }
      else
         r = lua_toboolean(naevL, -1);
      lua_pop(naevL, 1);

      return r;
   }
}


/**
 * @brief Gets the colour of the faction based on it's standing with the player.
 *
 * Used to unify the colour checks all over.
 *
 *    @param f Faction to get the colour of based on player's standing.
 *    @return Pointer to the colour.
 */
const glColour* faction_getColour(factionId_t f)
{
   if (!faction_isFaction(f))
      return &cInert;

   if (!faction_isKnown(f))
      return &cInert;

   if (faction_isPlayerFriend(f))
      return &cFriend;

   if (faction_isPlayerEnemy(f))
      return &cHostile;

   return &cNeutral;
}


/**
 * @brief Gets the faction character associated to its standing with the player.
 *
 * Use this to do something like "#%c", faction_getColourChar( some_faction ) in the
 *  font print routines.
 *
 *    @param f Faction to get the colour of based on player's standing.
 *    @return The character associated to the faction.
 */
char faction_getColourChar(factionId_t f)
{
   if (!faction_isFaction(f))
      return 'I';

   if (!faction_isKnown(f))
      return 'I';

   if (faction_isPlayerEnemy(f))
      return 'H';

   if (faction_isPlayerFriend(f))
      return 'F';

   return 'N';
}


/**
 * @brief Gets the faction symbol associated to its standing with the player.
 *
 *    @param f Faction to get the colour of based on player's standing.
 *    @return The character associated to the faction.
 */
const char *faction_getSymbol(factionId_t f)
{
   if (!faction_isFaction(f))
      return "";

   if (!faction_isKnown(f))
      return "? ";

   if (faction_isPlayerEnemy(f))
      return "!! ";

   if (faction_isPlayerFriend(f))
      return "+ ";

   return "~ ";
}


/**
 * @brief Gets the player's standing in human readable form.
 *
 *    @param f Faction to get standing of.
 *    @return Human readable player's standing (in player's native language).
 */
const char *faction_getStandingText(factionId_t f)
{
   int fsp;
   Faction *faction;
   const char *r;

   /* Escorts always have the same standing. */
   if (f == FACTION_PLAYER)
      return _("Subordinate");

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return _("???");
   }
   faction = faction_stack[fsp];

   if (faction->env == LUA_NOREF)
      return _("???");
   else
   {
      /* Set up the function:
       * faction_standing_text( standing ) */
      nlua_getenv(faction->env, "faction_standing_text");
      lua_pushnumber(naevL, faction->player);

      /* Call function. */
      if (nlua_pcall(faction->env, 1, 1))
      {
         /* An error occurred. */
         WARN(_("Faction '%s': %s"), faction->name, lua_tostring(naevL, -1));
         lua_pop(naevL, 1);
         return _("???");
      }

      /* Parse return. */
      if (!lua_isstring(naevL, -1))
      {
         WARN(_("Lua script for faction '%s' did not return a string from"
                  " 'faction_standing_text(...)'."),
               faction->name);
         r = _("???");
      }
      else
         r = lua_tostring(naevL, -1);
      lua_pop(naevL, 1);

      return r;
   }
}


/**
 * @brief Gets the broad faction standing.
 *
 *    @param f Faction to get broad standing of.
 *    @param bribed Whether or not the respective pilot is bribed.
 *    @param override If positive sets to ally, if negative sets to hostile.
 *    @return Human readable broad player's standing.
 */
const char *faction_getStandingBroad(factionId_t f, int bribed, int override)
{
   int fsp;
   Faction *faction;
   const char *r;

   /* Escorts always have the same standing. */
   if (f == FACTION_PLAYER)
      return _("Subordinate");

   fsp = faction_getStackPos(f);
   if (fsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), f);
      return _("???");
   }
   faction = faction_stack[fsp];

   if (faction->env == LUA_NOREF)
      return _("???");
   else
   {
      /* Set up the function:
       * faction_standing_broad( standing, bribed, override ) */
      nlua_getenv(faction->env, "faction_standing_broad");
      lua_pushnumber(naevL, faction->player);
      lua_pushboolean(naevL, bribed);
      lua_pushnumber(naevL, override);

      /* Call function. */
      if (nlua_pcall(faction->env, 3, 1))
      {
         /* An error occurred. */
         WARN(_("Faction '%s': %s"), faction->name, lua_tostring(naevL, -1));
         lua_pop(naevL, 1);
         return _("???");
      }

      /* Parse return. */
      if (!lua_isstring(naevL, -1))
      {
         WARN(_("Lua script for faction '%s' did not return a string from"
                  " 'faction_standing_broad(...)'."),
               faction->name);
         r = _("???");
      }
      else
         r = lua_tostring(naevL, -1);
      lua_pop(naevL, 1);

      return r;
   }
}


/**
 * @brief Checks whether two factions are enemies.
 *
 *    @param a Faction A.
 *    @param b Faction B.
 *    @return 1 if A and B are enemies, 0 otherwise.
 */
int areEnemies(factionId_t a, factionId_t b)
{
   int asp, bsp;
   Faction *fa, *fb;
   int i;

   if (a == b)
      return 0;

   /* player handled separately */
   if (a == FACTION_PLAYER) {
      return faction_isPlayerEnemy(b);
   }
   else if (b == FACTION_PLAYER) {
      return faction_isPlayerEnemy(a);
   }

   asp = faction_getStackPos(a);
   if (asp < 0) {
      WARN(_("Faction id '%ld' is invalid."), a);
      return 0;
   }
   bsp = faction_getStackPos(b);
   if (bsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), b);
      return 0;
   }
   fa = faction_stack[asp];
   fb = faction_stack[bsp];

   for (i=0; i<array_size(fa->enemies); i++) {
      if (fa->enemies[i] == b)
         return 1;
   }
   for (i=0; i<array_size(fb->enemies); i++) {
      if (fb->enemies[i] == a)
         return 1;
   }

   return 0;
}


/**
 * @brief Checks whether two factions are allies or not.
 *
 *    @param a Faction A.
 *    @param b Faction B.
 *    @return 1 if A and B are allies, 0 otherwise.
 */
int areAllies(factionId_t a, factionId_t b)
{
   int asp, bsp;
   Faction *fa, *fb;
   int i;

   /* If they are the same they must be allies. */
   if (a == b)
      return 1;

   /* we assume player becomes allies with high rating */
   if (a == FACTION_PLAYER) {
      return faction_isPlayerFriend(b);
   }
   else if (b == FACTION_PLAYER) {
      return faction_isPlayerFriend(a);
   }

   asp = faction_getStackPos(a);
   if (asp < 0) {
      WARN(_("Faction id '%ld' is invalid."), a);
      return 0;
   }
   bsp = faction_getStackPos(b);
   if (bsp < 0) {
      WARN(_("Faction id '%ld' is invalid."), b);
      return 0;
   }
   fa = faction_stack[asp];
   fb = faction_stack[bsp];

   for (i=0; i<array_size(fa->allies); i++) {
      if (fa->allies[i] == b)
         return 1;
   }
   for (i=0; i<array_size(fb->allies); i++) {
      if (fb->allies[i] == a)
         return 1;
   }

   return 0;
}


/**
 * @brief Checks whether or not a faction is valid.
 *
 *    @param f Faction to check for validity.
 *    @return 1 if faction is valid, 0 otherwise.
 */
int faction_isFaction(factionId_t f)
{
   return ((f != 0) && (faction_getStackPos(f) >= 0));
}


/**
 * @brief Parses a single faction, but doesn't set the allies/enemies bit.
 *
 *    @param temp Faction to load data into.
 *    @param parent Parent node to extract faction from.
 *    @return Faction created from parent node.
 */
static int faction_parse( Faction* temp, xmlNodePtr parent )
{
   xmlNodePtr node;
   int player_found;
   char buf[PATH_MAX], *dat, *ctmp;
   size_t ndat;

   /* Clear memory. */
   memset(temp, 0, sizeof(Faction));
   temp->id = ++faction_id;
   temp->equip_env = LUA_NOREF;
   temp->env = LUA_NOREF;
   temp->sched_env = LUA_NOREF;

   player_found = 0;
   node   = parent->xmlChildrenNode;
   do {
      /* Only care about nodes. */
      xml_onlyNodes(node);

      /* Can be 0 or negative, so we have to take that into account. */
      if (xml_isNode(node,"player")) {
         temp->player_def = xml_getFloat(node);
         player_found = 1;
         continue;
      }

      xmlr_strd(node,"name",temp->name);
      xmlr_strd(node,"longname",temp->longname);
      xmlr_strd(node,"display",temp->displayname);
      xmlr_strd(node,"ai",temp->ai);
      if (xml_isNode(node, "colour")) {
         ctmp = xml_get(node);
         if (ctmp != NULL)
            temp->colour = *col_fromName(xml_raw(node));
         /* If no named colour is present, RGB attributes are used. */
         else {
            /* Initialize in case a colour channel is absent. */
            xmlr_attr_float(node,"r",temp->colour.r);
            xmlr_attr_float(node,"g",temp->colour.g);
            xmlr_attr_float(node,"b",temp->colour.b);
            temp->colour.a = 1.;
            col_gammaToLinear( &temp->colour );
         }
         continue;
      }

      if (xml_isNode(node, "spawn")) {
         if (temp->sched_env != LUA_NOREF)
            WARN(_("Faction '%s' has duplicate 'spawn' tag."), temp->name);
         snprintf( buf, sizeof(buf), FACTIONS_PATH"spawn/%s.lua", xml_raw(node) );
         temp->sched_env = nlua_newEnv(1);
         nlua_loadStandard( temp->sched_env );
         dat = ndata_read( buf, &ndat );
         if (nlua_dobufenv(temp->sched_env, dat, ndat, buf) != 0) {
            WARN(_("Failed to run spawn script: %s\n"
                  "%s\n"
                  "Most likely Lua file has improper syntax, please check"),
                  buf, lua_tostring(naevL,-1));
            nlua_freeEnv( temp->sched_env );
            temp->sched_env = LUA_NOREF;
         }
         free(dat);
         continue;
      }

      if (xml_isNode(node, "standing")) {
         if (temp->env != LUA_NOREF)
            WARN(_("Faction '%s' has duplicate 'standing' tag."), temp->name);
         faction_addStandingScript( temp, xml_raw(node) );
         continue;
      }

      if (xml_isNode(node, "known")) {
         faction_setFlag(temp, FACTION_KNOWN);
         continue;
      }

      if (xml_isNode(node, "equip")) {
         if (temp->equip_env != LUA_NOREF)
            WARN(_("Faction '%s' has duplicate 'equip' tag."), temp->name);
         snprintf( buf, sizeof(buf), FACTIONS_PATH"equip/%s.lua", xml_raw(node) );
         temp->equip_env = nlua_newEnv(1);
         nlua_loadStandard( temp->equip_env );
         dat = ndata_read( buf, &ndat );
         if (nlua_dobufenv(temp->equip_env, dat, ndat, buf) != 0) {
            WARN(_("Failed to run equip script: %s\n"
                  "%s\n"
                  "Most likely Lua file has improper syntax, please check"),
                  buf, lua_tostring(naevL, -1));
            nlua_freeEnv( temp->equip_env );
            temp->equip_env = LUA_NOREF;
         }
         free(dat);
         continue;
      }

      if (xml_isNode(node,"logo")) {
         if (temp->logo_small != NULL)
            WARN(_("Faction '%s' has duplicate 'logo' tag."), temp->name);
         snprintf( buf, sizeof(buf), FACTION_LOGO_PATH"%s_small.png", xml_get(node) );
         temp->logo_small = gl_newImage(buf, 0);
         snprintf( buf, sizeof(buf), FACTION_LOGO_PATH"%s_tiny.png", xml_get(node) );
         temp->logo_tiny = gl_newImage(buf, 0);
         continue;
      }

      if (xml_isNode(node,"static")) {
         faction_setFlag(temp, FACTION_STATIC);
         continue;
      }

      if (xml_isNode(node,"invisible")) {
         faction_setFlag(temp, FACTION_INVISIBLE);
         continue;
      }

      /* Avoid warnings. */
      if (xml_isNode(node,"allies") || xml_isNode(node,"enemies"))
         continue;

      DEBUG(_("Unknown node '%s' in faction '%s'"),node->name,temp->name);
   } while (xml_nextNode(node));

   if (temp->name == NULL)
      WARN(_("Unable to read data from '%s'"), FACTION_DATA_PATH);
   if (player_found == 0)
      DEBUG(_("Faction '%s' missing player tag."), temp->name);
   if ((temp->env==LUA_NOREF) && !faction_isFlag( temp, FACTION_STATIC ))
      WARN(_("Faction '%s' has no Lua and isn't static!"), temp->name);

   return 0;
}


/**
 * @brief Sets up a standing script for a faction.
 *
 *    @param temp Faction to associate the script to.
 *    @param scriptname Name of the lua script to use (e.g., "static").
 */
static void faction_addStandingScript( Faction* temp, const char* scriptname ) {
   char buf[PATH_MAX], *dat;
   size_t ndat;

   snprintf( buf, sizeof(buf), FACTIONS_PATH"standing/%s.lua", scriptname );
   temp->env = nlua_newEnv(1);
   nlua_loadStandard( temp->env );
   dat = ndata_read( buf, &ndat );
   if (nlua_dobufenv(temp->env, dat, ndat, buf) != 0) {
      WARN(_("Failed to run standing script: %s\n"
            "%s\n"
            "Most likely Lua file has improper syntax, please check"),
            buf, lua_tostring(naevL,-1));
      nlua_freeEnv( temp->env );
      temp->env = LUA_NOREF;
   }
   free(dat);
}


/**
 * @brief Parses the social tidbits of a faction: allies and enemies.
 *
 *    @param parent Node containing the faction.
 */
static void faction_parseSocial( xmlNodePtr parent )
{
   xmlNodePtr node, cur;
   factionId_t f;
   int fsp;
   Faction *base;
   factionId_t *tmp;

   /* Get name. */
   base = NULL;
   node = parent->xmlChildrenNode;
   do {
      xml_onlyNodes(node);
      if (xml_isNode(node,"name")) {
         f = faction_get(xml_get(node));
         fsp = faction_getStackPos(f);
         if (fsp < 0) {
            WARN(_("Faction id '%ld' is invalid."), f);
            continue;
         }
         base = faction_stack[fsp];
         break;
      }
   } while (xml_nextNode(node));

   assert( base != NULL );

   /* Create arrays, not much memory so it doesn't really matter. */
   base->allies = array_create(factionId_t);
   base->enemies = array_create(factionId_t);

   /* Parse social stuff. */
   node = parent->xmlChildrenNode;
   do {

      /* Grab the allies */
      if (xml_isNode(node,"allies")) {
         cur = node->xmlChildrenNode;

         do {
            if (xml_isNode(cur,"ally")) {
               tmp = &array_grow(&base->allies);
               *tmp = faction_get(xml_get(cur));
            }
         } while (xml_nextNode(cur));
      }

      /* Grab the enemies */
      if (xml_isNode(node,"enemies")) {
         cur = node->xmlChildrenNode;

         do {
            if (xml_isNode(cur,"enemy")) {
               tmp = &array_grow( &base->enemies );
               *tmp = faction_get(xml_get(cur));
            }
         } while (xml_nextNode(cur));
      }
   } while (xml_nextNode(node));
}


/**
 * @brief Resets player standing and flags of factions to default.
 */
void factions_reset (void)
{
   int i;
   for (i=0; i<array_size(faction_stack); i++) {
      faction_stack[i]->player = faction_stack[i]->player_def;
      faction_stack[i]->flags = faction_stack[i]->oflags;
   }
}


/**
 * @brief Loads up all the factions from the data file.
 *
 *    @return 0 on success.
 */
int factions_load (void)
{
   xmlNodePtr factions, node;
   int i, j, k, r;
   int fsp;
   Faction *f, *sf;
   Faction **fp;


   /* Load the document. */
   xmlDocPtr doc = xml_parsePhysFS( FACTION_DATA_PATH );
   if (doc == NULL)
      return -1;

   node = doc->xmlChildrenNode; /* Factions node */
   if (!xml_isNode(node,XML_FACTION_ID)) {
      ERR(_("Malformed %s file: missing root element '%s'"), FACTION_DATA_PATH, XML_FACTION_ID);
      return -1;
   }

   factions = node->xmlChildrenNode; /* first faction node */
   if (factions == NULL) {
      ERR(_("Malformed %s file: does not contain elements"), FACTION_DATA_PATH);
      return -1;
   }

   /* player faction is hard-coded */
   faction_stack = array_create(Faction*);
   fp = &array_grow(&faction_stack);
   *fp = malloc(sizeof(Faction));
   f = *fp;
   memset(f, 0, sizeof(Faction));
   f->id = FACTION_PLAYER;
   f->name = strdup("Player");
   f->flags = FACTION_STATIC | FACTION_INVISIBLE;
   f->equip_env = LUA_NOREF;
   f->env = LUA_NOREF;
   f->sched_env = LUA_NOREF;
   f->allies = array_create(factionId_t);
   f->enemies = array_create(factionId_t);

   /* First pass - gets factions */
   node = factions;
   do {
      if (naev_pollQuit())
         break;

      if (xml_isNode(node,XML_FACTION_TAG)) {
         fp = &array_grow(&faction_stack);
         *fp = malloc(sizeof(Faction));
         f = *fp;

         /* Load faction. */
         faction_parse(f, node);
         f->oflags = f->flags;
      }
   } while (xml_nextNode(node));

   /* Second pass - sets allies and enemies */
   node = factions;
   do {
      if (naev_pollQuit())
         break;

      if (xml_isNode(node,XML_FACTION_TAG))
         faction_parseSocial(node);
   } while (xml_nextNode(node));

   /* Third pass, Make allies/enemies symmetric. */
   for (i=0; i<array_size(faction_stack); i++) {
      if (naev_pollQuit())
         break;

      f = faction_stack[i];

      /* First run over allies and make sure it's mutual. */
      for (j=0; j<array_size(f->allies); j++) {
         fsp = faction_getStackPos(f->allies[j]);
         if (fsp < 0) {
            WARN(_("Faction id '%ld' is invalid."), f->allies[j]);
            continue;
         }
         sf = faction_stack[fsp];

         r = 0;
         for (k=0; k < array_size(sf->allies); k++) {
            if (sf->allies[k] == f->id) {
               r = 1;
               break;
            }
         }

         /* Add ally if necessary. */
         if (r == 0)
            faction_addAlly(f->allies[j], f->id);
      }

      /* Now run over enemies. */
      for (j=0; j < array_size(f->enemies); j++) {
         fsp = faction_getStackPos(f->enemies[j]);
         if (fsp < 0) {
            WARN(_("Faction id '%ld' is invalid."), f->enemies[j]);
            continue;
         }
         sf = faction_stack[fsp];

         r = 0;
         for (k=0; k<array_size(sf->enemies); k++) {
            if (sf->enemies[k] == f->id) {
               r = 1;
               break;
            }
         }

         if (r == 0)
            faction_addEnemy(f->enemies[j], f->id);
      }
   }

   xmlFreeDoc(doc);

   DEBUG(n_("Loaded %d Faction", "Loaded %d Factions",
            array_size(faction_stack)),
         array_size(faction_stack));

   return 0;
}


/**
 * @brief Frees a single faction.
 */
static void faction_freeOne( Faction *f )
{
   free(f->name);
   free(f->longname);
   free(f->displayname);
   free(f->ai);
   gl_freeTexture(f->logo_small);
   gl_freeTexture(f->logo_tiny);
   array_free(f->allies);
   array_free(f->enemies);
   if (f->sched_env != LUA_NOREF)
      nlua_freeEnv(f->sched_env);
   if (f->env != LUA_NOREF)
      nlua_freeEnv(f->env);
   if (!faction_isFlag(f, FACTION_DYNAMIC) && (f->equip_env != LUA_NOREF))
      nlua_freeEnv(f->equip_env);
}


/**
 * @brief Frees the factions.
 */
void factions_free (void)
{
   int i;

   /* free factions */
   for (i=0; i<array_size(faction_stack); i++) {
      faction_freeOne(faction_stack[i]);
      free(faction_stack[i]);
   }
   array_free(faction_stack);
   faction_stack = NULL;
}


/**
 * @brief Saves player's standings with the factions.
 *
 *    @param writer The xml writer to use.
 *    @return 0 on success.
 */
int pfaction_save( xmlTextWriterPtr writer )
{
   int i;

   xmlw_startElem(writer,"factions");

   for (i=0; i<array_size(faction_stack); i++) {
      /* Must not be the player. */
      if (faction_stack[i]->id == FACTION_PLAYER)
         continue;

      /* Must not be static. */
      if (faction_isFlag(faction_stack[i], FACTION_STATIC))
         continue;

      xmlw_startElem(writer,"faction");

      xmlw_attr(writer, "name", "%s", faction_stack[i]->name);
      xmlw_elem(writer, "standing", "%f", faction_stack[i]->player);

      if (faction_isKnown_(faction_stack[i]))
         xmlw_elemEmpty(writer, "known");

      xmlw_endElem(writer); /* "faction" */
   }

   xmlw_endElem(writer); /* "factions" */

   return 0;
}


/**
 * @brief Loads the player's faction standings.
 *
 *    @param parent Parent xml node to read from.
 *    @return 0 on success.
 */
int pfaction_load( xmlNodePtr parent )
{
   xmlNodePtr node, cur, sub;
   char *str;
   factionId_t faction;
   int fsp;

   node = parent->xmlChildrenNode;

   do {
      if (xml_isNode(node,"factions")) {
         cur = node->xmlChildrenNode;
         do {
            if (xml_isNode(cur,"faction")) {
               xmlr_attr_strd(cur, "name", str);
               faction = faction_get(str);

               if (faction != 0) {
                  fsp = faction_getStackPos(faction);
                  if (fsp >= 0) {
                     sub = cur->xmlChildrenNode;
                     do {
                        if (xml_isNode(sub, "standing")) {

                           /* Must not be static. */
                           if (!faction_isFlag(faction_stack[fsp],
                                    FACTION_STATIC))
                              faction_stack[fsp]->player = xml_getFloat(sub);
                           continue;
                        }
                        if (xml_isNode(sub,"known")) {
                           faction_setFlag(faction_stack[fsp], FACTION_KNOWN);
                           continue;
                        }
                     } while (xml_nextNode(sub));
                  }
                  else {
                     WARN(_("Faction id '%ld' is invalid."), faction);
                  }
               }
               free(str);
            }
         } while (xml_nextNode(cur));
      }
   } while (xml_nextNode(node));

   return 0;
}


/**
 * @brief Returns an array of faction ids.
 *
 *    @param which Which factions to get. (0,1,2,3 : all, friendly, neutral, hostile)
 *    @return Array (array.h): The faction IDs of the specified alignment.
 */
factionId_t *faction_getGroup(int which)
{
   factionId_t *group;
   int i;

   switch(which) {
      case 0: /* 'all' */
         group = array_create(factionId_t);
         for (i=0; i<array_size(faction_stack); i++) {
            array_push_back(&group, faction_stack[i]->id);
         }
         return group;

      case 1: /* 'friendly' */
         group = array_create(factionId_t);
         for (i=0; i<array_size(faction_stack); i++) {
            if (faction_isPlayerFriend(faction_stack[i]->id))
               array_push_back(&group, faction_stack[i]->id);
         }
         return group;

      case 2: /* 'neutral' */
         group = array_create(factionId_t);
         for (i=0; i<array_size(faction_stack); i++) {
            if (!faction_isPlayerFriend(faction_stack[i]->id)
                  && !faction_isPlayerEnemy(faction_stack[i]->id))
               array_push_back(&group, faction_stack[i]->id);
         }
         return group;

      case 3: /* 'hostile' */
         group = array_create(factionId_t);
         for (i=0; i<array_size(faction_stack); i++) {
            if (faction_isPlayerEnemy(faction_stack[i]->id))
               array_push_back(&group, faction_stack[i]->id);
         }
         return group;

      default:
         return NULL;
   }
}


/**
 * @brief Clears dynamic factions.
 */
void factions_clearDynamic (void)
{
   int i, j;
   Faction *f;
   factionId_t *others;
   const char *name;

   for (i=0; i<array_size(faction_stack); i++) {
      f = faction_stack[i];
      if (faction_isFlag(f, FACTION_DYNAMIC)) {
         /* First clear allies and enemies, so that they don't keep
          * referencing this deleted faction. */
         faction_clearEnemy(f->id);
         faction_clearAlly(f->id);

         /* Now free the dynamic faction and decrement i so we stay in
          * the right place after the array size changes. */
         faction_freeOne(f);
         free(faction_stack[i]);
         array_erase(&faction_stack, &faction_stack[i], &faction_stack[i+1]);
         i--;
      }
   }

   /* Debug checks. */
   for (i=0; i<array_size(faction_stack); i++) {
      f = faction_stack[i];
      name = faction_longname(f->id);
      if (faction_isFlag(f, FACTION_DYNAMIC))
         WARN(_("Failed to remove dynamic faction: %s (FID %ld)"),
               name, f->id);
      else {
         others = faction_getEnemies(f->id);
         for (j=0; j<array_size(others); j++) {
            if (!faction_isFaction(others[j]))
               WARN(_("Faction '%ld' is not a valid faction, but still enemies"
                        " with faction: %s (FID %ld)"),
                     others[j], name, f->id);
         }
         others = faction_getAllies(f->id);
         for (j=0; j<array_size(others); j++) {
            if (!faction_isFaction(others[j]))
               WARN(_("Faction '%ld' is not a valid faction, but still allies"
                        " with faction: %s (FID %ld)"),
                     others[j], name, f->id);
         }
      }
   }
}


/**
 * @brief Dynamically add a faction.
 *
 *    @param base Faction to base it off (negative for none).
 *    @param name Name of the faction to set.
 *    @param display Display name to use.
 *    @param ai Default pilot AI to use (if NULL, inherit from base).
 */
factionId_t faction_dynAdd(factionId_t base, const char* name,
      const char* display, const char* ai)
{
   int fsp;
   Faction *f, *bf, *of;
   Faction **fp;
   int i;

   fp = &array_grow(&faction_stack);
   *fp = malloc(sizeof(Faction));
   f = *fp;
   memset(f, 0, sizeof(Faction));
   f->id = ++faction_id;
   f->name = strdup(name);
   f->displayname = (display == NULL) ? NULL : strdup(display);
   f->ai = (ai == NULL) ? NULL : strdup(ai);
   f->allies = array_create(factionId_t);
   f->enemies = array_create(factionId_t);
   f->equip_env = LUA_NOREF;
   f->env = LUA_NOREF;
   f->sched_env = LUA_NOREF;
   f->flags = FACTION_STATIC | FACTION_INVISIBLE | FACTION_DYNAMIC | FACTION_KNOWN;
   faction_addStandingScript(f, "static");

   if (base > 0) {
      fsp = faction_getStackPos(base);
      if (fsp < 0) {
         WARN(_("Faction id '%ld' is invalid."), base);
         return 0;
      }
      bf = faction_stack[fsp];

      if ((bf->ai != NULL) && (f->ai == NULL))
         f->ai = strdup(bf->ai);
      if (bf->logo_small != NULL)
         f->logo_small = gl_dupTexture(bf->logo_small);
      if (bf->logo_tiny != NULL)
         f->logo_tiny = gl_dupTexture(bf->logo_tiny);

      for (i=0; i<array_size(bf->allies); i++) {
         fsp = faction_getStackPos(bf->allies[i]);
         if (fsp < 0) {
            WARN(_("Faction id '%ld' is invalid."), bf->allies[i]);
            continue;
         }
         of = faction_stack[fsp];
         faction_addAlly(f->id, of->id);
         faction_addAlly(of->id, f->id);
      }
      for (i=0; i<array_size(bf->enemies); i++) {
         fsp = faction_getStackPos(bf->enemies[i]);
         if (fsp < 0) {
            WARN(_("Faction id '%ld' is invalid."), bf->enemies[i]);
            continue;
         }
         of = faction_stack[fsp];
         faction_addEnemy(f->id, of->id);
         faction_addEnemy(of->id, f->id);
      }

      f->player_def = bf->player_def;
      f->player = bf->player;
      f->colour = bf->colour;

      /* Lua stuff. */
      f->equip_env = bf->equip_env;
   }

   return f->id;
}
