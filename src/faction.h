/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef FACTION_H
#  define FACTION_H


#include "colour.h"
#include "nlua.h"
#include "opengl.h"


#define FACTION_PLAYER 1 /**< Hardcoded player faction identifier. */


typedef unsigned long factionId_t; /**< Type for pilot IDs. */


/* get stuff */
void factions_sort(void);
int faction_isFaction(factionId_t f);
int faction_exists(const char* name);
factionId_t faction_get(const char* name);
factionId_t* faction_getAll();
factionId_t* faction_getKnown();
int faction_isInvisible(factionId_t id);
int faction_setInvisible(factionId_t id, int state);
int faction_isKnown(factionId_t id);
int faction_isDynamic(factionId_t id);
const char* faction_name(factionId_t f);
const char* faction_shortname(factionId_t f);
const char* faction_longname(factionId_t f);
const char* faction_default_ai(factionId_t f);
void faction_clearEnemy(factionId_t f);
void faction_addEnemy(factionId_t f, factionId_t o);
void faction_rmEnemy(factionId_t f, factionId_t o);
void faction_clearAlly(factionId_t f);
void faction_addAlly(factionId_t f, factionId_t o);
void faction_rmAlly(factionId_t f, factionId_t o);
nlua_env faction_getScheduler(factionId_t f);
nlua_env faction_getEquipper(factionId_t f);
glTexture* faction_logoSmall(factionId_t f);
glTexture* faction_logoTiny(factionId_t f);
const glColour* faction_colour(factionId_t f);
factionId_t* faction_getEnemies(factionId_t f);
factionId_t* faction_getAllies(factionId_t f);
factionId_t* faction_getGroup(int which);

/* set stuff */
int faction_setKnown(factionId_t id, int state);

/* player stuff */
void faction_modPlayer(factionId_t f, double mod, const char *source);
void faction_modPlayerSingle(factionId_t f, double mod, const char *source);
void faction_modPlayerRaw(factionId_t f, double mod);
void faction_setPlayer(factionId_t f, double value);
double faction_getPlayer(factionId_t f);
double faction_getPlayerDef(factionId_t f);
int faction_isPlayerFriend(factionId_t f);
int faction_isPlayerEnemy(factionId_t f);
const char *faction_getStandingText(factionId_t f);
const char *faction_getStandingBroad(factionId_t f, int bribed, int override);
const glColour* faction_getColour(factionId_t f);
char faction_getColourChar(factionId_t f);
const char *faction_getSymbol(factionId_t f);

/* works with only factions */
int areEnemies(factionId_t a, factionId_t b);
int areAllies(factionId_t a, factionId_t b);

/* load/free */
int factions_load (void);
void factions_free (void);
void factions_reset (void);
void faction_clearKnown (void);

/* Dynamic factions. */
void factions_clearDynamic (void);
factionId_t faction_dynAdd(factionId_t base, const char* name,
      const char* display, const char* ai);


#endif /* FACTION_H */
