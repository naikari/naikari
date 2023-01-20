/*
 * See Licensing and Copyright notice in naev.h
 */


#ifndef FACTION_H
#  define FACTION_H


#include "colour.h"
#include "nlua.h"
#include "opengl.h"


#define FACTION_PLAYER 1 /**< Hardcoded player faction identifier. */


/* get stuff */
int faction_isFaction(unsigned long f);
unsigned long faction_exists(const char* name);
unsigned long faction_get(const char* name);
unsigned long* faction_getAll();
unsigned long* faction_getKnown();
int faction_isInvisible(unsigned long id);
int faction_setInvisible(unsigned long id, int state);
int faction_isKnown(unsigned long id);
int faction_isDynamic(unsigned long id);
const char* faction_name(unsigned long f);
const char* faction_shortname(unsigned long f);
const char* faction_longname(unsigned long f);
const char* faction_default_ai(unsigned long f);
void faction_clearEnemy(unsigned long f);
void faction_addEnemy(unsigned long f, unsigned long o);
void faction_rmEnemy(unsigned long f, unsigned long o);
void faction_clearAlly(unsigned long f);
void faction_addAlly(unsigned long f, unsigned long o);
void faction_rmAlly(unsigned long f, unsigned long o);
nlua_env faction_getScheduler(unsigned long f);
nlua_env faction_getEquipper(unsigned long f);
glTexture* faction_logoSmall(unsigned long f);
glTexture* faction_logoTiny(unsigned long f);
const glColour* faction_colour(unsigned long f);
unsigned long* faction_getEnemies(unsigned long f);
unsigned long* faction_getAllies(unsigned long f);
unsigned long* faction_getGroup(int which);

/* set stuff */
int faction_setKnown(unsigned long id, int state);

/* player stuff */
void faction_modPlayer(unsigned long f, double mod, const char *source);
void faction_modPlayerSingle(unsigned long f, double mod, const char *source);
void faction_modPlayerRaw(unsigned long f, double mod);
void faction_setPlayer(unsigned long f, double value);
double faction_getPlayer(unsigned long f);
double faction_getPlayerDef(unsigned long f);
int faction_isPlayerFriend(unsigned long f);
int faction_isPlayerEnemy(unsigned long f);
const char *faction_getStandingText(unsigned long f);
const char *faction_getStandingBroad(unsigned long f, int bribed, int override);
const glColour* faction_getColour(unsigned long f);
char faction_getColourChar(unsigned long f);
const char *faction_getSymbol(unsigned long f);

/* works with only factions */
int areEnemies(unsigned long a, unsigned long b);
int areAllies(unsigned long a, unsigned long b);

/* load/free */
int factions_load (void);
void factions_free (void);
void factions_reset (void);
void faction_clearKnown (void);

/* Dynamic factions. */
void factions_clearDynamic (void);
unsigned long faction_dynAdd(unsigned long base, const char* name,
      const char* display, const char* ai);


#endif /* FACTION_H */
