/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file board.c
 *
 * @brief Deals with boarding ships.
 */


/** @cond */
#include "naev.h"
/** @endcond */

#include "board.h"

#include "array.h"
#include "commodity.h"
#include "credits.h"
#include "damagetype.h"
#include "hook.h"
#include "log.h"
#include "nstring.h"
#include "pilot.h"
#include "player.h"
#include "rng.h"
#include "space.h"
#include "toolkit.h"


#define BOARDING_WIDTH  720 /**< Boarding window width. */
#define BOARDING_HEIGHT (40 + 5*(BUTTON_HEIGHT+20)) /**< Boarding window height. */

#define BUTTON_WIDTH    180 /**< Boarding button width. */
#define BUTTON_HEIGHT    40 /**< Boarding button height. */


static int board_stopboard = 0; /**< Whether or not to unboard. */
static int board_boarded = 0;
static unsigned long board_hook_id = 0;
static unsigned int board_pilot_id = 0;


/*
 * prototypes
 */
static void board_stealCreds( unsigned int wdw, char* str );
static void board_stealCargo( unsigned int wdw, char* str );
static void board_stealFuel( unsigned int wdw, char* str );
static void board_stealAll(unsigned int wdw, char *str);
static void board_update( unsigned int wdw );
static int pilot_boardStealCargo(Pilot *p, Pilot *target);
static double pilot_boardStealFuel(Pilot *p, Pilot *target);


/**
 * @brief Gets if the player is boarded.
 */
int player_isBoarded (void)
{
   return board_boarded;
}


static int board_hook(void *data)
{
   (void) data;
   HookParam hparam[2];
   Pilot *p;
   unsigned int wdw;

   /* Remove board hook so it doesn't run again. */
   hook_rm(board_hook_id);
   board_hook_id = 0;

   p = pilot_get(board_pilot_id);
   if (p == NULL)
      return 0;

   /*
    * run hook if needed
    */
   hparam[0].type = HOOK_PARAM_PILOT;
   hparam[0].u.lp = board_pilot_id;
   hparam[1].type = HOOK_PARAM_SENTINEL;
   hooks_runParam("board", hparam);
   pilot_runHookParam(player.p, PILOT_HOOK_BOARDING, hparam, 1);
   hparam[0].u.lp = PLAYER_ID;
   pilot_runHookParam(p, PILOT_HOOK_BOARD, hparam, 1);

   if (board_stopboard) {
      board_boarded = 0;
      return 0;
   }

   /*
    * create the boarding window
    */
   wdw = window_create("wdwBoarding", _("Boarding"), -1, -1, BOARDING_WIDTH,
         BOARDING_HEIGHT);

   window_addButtonKey(wdw, 20, -40, BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnStealCredits", _("Loot &Credits"),
         board_stealCreds, SDLK_c);
   window_addText(wdw, 20+BUTTON_WIDTH+10,
         -40 - (BUTTON_HEIGHT-gl_defFont.h)/2,
         BOARDING_WIDTH - (20+BUTTON_WIDTH+10),
         BUTTON_HEIGHT + 20 - (BUTTON_HEIGHT-gl_defFont.h)/2, 0,
         "txtDataCredits", &gl_defFont, NULL, NULL);

   window_addButtonKey(wdw, 20, -40 - 1*(BUTTON_HEIGHT+20), BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnStealFuel", _("Loot &Fuel"), board_stealFuel,
         SDLK_f);
   window_addText(wdw, 20+BUTTON_WIDTH+10,
         -40 - 1*(BUTTON_HEIGHT+20) - (BUTTON_HEIGHT-gl_defFont.h)/2,
         BOARDING_WIDTH - (20+BUTTON_WIDTH+10),
         BUTTON_HEIGHT + 20 - (BUTTON_HEIGHT-gl_defFont.h)/2, 0,
         "txtDataFuel", &gl_defFont, NULL, NULL);

   window_addButtonKey(wdw, 20, -40 - 2*(BUTTON_HEIGHT+20), BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnStealCargo", _("Loot Car&go"), board_stealCargo,
         SDLK_g);
   window_addText(wdw, 20+BUTTON_WIDTH+10,
         -40 - 2*(BUTTON_HEIGHT+20) - (BUTTON_HEIGHT-gl_defFont.h)/2,
         BOARDING_WIDTH - (20+BUTTON_WIDTH+10),
         3*BUTTON_HEIGHT + 3*20 - (BUTTON_HEIGHT-gl_defFont.h)/2, 0,
         "txtDataCargo", &gl_defFont, NULL, NULL);

   window_addButtonKey(wdw, 20, -40 - 3*(BUTTON_HEIGHT+20), BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnStealAll", _("Loot &All"), board_stealAll,
         SDLK_a);

   window_addButtonKey(wdw, 20, -40 - 4*(BUTTON_HEIGHT+20), BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnBoardingClose", _("Lea&ve"), board_exit,
         SDLK_v);

   window_setFocus(wdw, "btnStealAll");

   board_update(wdw);
   return 0;
}


/**
 * @fn void player_board (void)
 *
 * @brief Attempt to board the player's target.
 *
 * Creates the window on success.
 */
int player_board(void)
{
   Pilot *p;
   Pilot *const *pilots;
   int i;
   pilotId_t target;
   double d, td;
   char c;

   /* Not disabled. */
   if (pilot_isDisabled(player.p))
      return PLAYER_BOARD_IMPOSSIBLE;

   if (player.p->target == PLAYER_ID) {
      /* Attempt to find the nearest boardable pilot. */
      target = PLAYER_ID;
      d = 0;
      pilots = pilot_getAll();
      for (i=0; i<array_size(pilots); i++) {
         if (pilots[i]->id == PLAYER_ID)
            continue;

         if (!pilot_validTarget(player.p, pilots[i]))
            continue;

         if (pilot_isFlag(pilots[i], PILOT_NOBOARD))
            continue;

         if (!pilot_isDisabled(pilots[i])
               && !pilot_isFlag(pilots[i], PILOT_BOARDABLE))
            continue;

         td = vect_dist2(&player.p->solid->pos, &pilots[i]->solid->pos);
         if ((target == PLAYER_ID) || (td < d)) {
            target = pilots[i]->id;
            d = td;
         }
      }

      /* If no suitable target was found, abort the boarding action. */
      if (target == PLAYER_ID) {
         player_messageRaw(_("#rYou need a target to board first."));
         return PLAYER_BOARD_IMPOSSIBLE;
      }

      /* Suitable target found; set as the player's target and
       * proceed with boarding. */
      player_targetSet(target);
      p = pilot_get(target);
   }
   else
      p = pilot_get(player.p->target);
   c = pilot_getFactionColourChar( p );

   /* More checks. */
   if (pilot_isFlag(p, PILOT_NOBOARD)) {
      player_messageRaw(_("#rTarget ship cannot be boarded."));
      return PLAYER_BOARD_IMPOSSIBLE;
   }
   else if (!pilot_isDisabled(p) && !pilot_isFlag(p, PILOT_BOARDABLE)) {
      player_messageRaw(_("#rTarget ship cannot currently be boarded."));
      return PLAYER_BOARD_IMPOSSIBLE;
   }
   else if (vect_dist(&player.p->solid->pos,&p->solid->pos)
         > p->ship->gfx_space->sw * PILOT_SIZE_APPROX) {
      return PLAYER_BOARD_RETRY;
   }
   else if (vect_dist(&player.p->solid->vel, &p->solid->vel)
         > MAX_HYPERSPACE_VEL) {
      return PLAYER_BOARD_RETRY;
   }

   /* Handle fighters. */
   if (pilot_isFlag(p, PILOT_CARRIED) && (p->dockpilot == PLAYER_ID)) {
      if (pilot_dock( p, player.p )) {
         WARN(_("Unable to recover fighter."));
         return PLAYER_BOARD_IMPOSSIBLE;
      }
      player_message(_("#oYou recover your %s fighter."), p->name);
      return PLAYER_BOARD_OK;
   }

   /* Set speed to target's speed. */
   vect_cset(&player.p->solid->vel, VX(p->solid->vel), VY(p->solid->vel));

   /* Is boarded. */
   board_boarded = 1;

   pilot_setFlag(p, PILOT_BOARDED);
   player_message(_("#oBoarding ship #%c%s#0."), c, p->name);

   /* Don't unboard. */
   board_stopboard = 0;

   board_pilot_id = p->id;
   if (board_hook_id == 0)
      board_hook_id = hook_addFunc(board_hook, NULL, "safe");
   return PLAYER_BOARD_OK;
}


/**
 * @brief Forces unboarding of the pilot.
 */
void board_unboard (void)
{
   board_stopboard = 1;
}


/**
 * @brief Closes the boarding window.
 *
 *    @param wdw Window triggering the function.
 *    @param str Unused.
 */
void board_exit( unsigned int wdw, char* str )
{
   (void) str;
   window_destroy( wdw );

   /* Is not boarded. */
   board_boarded = 0;
}


/**
 * @brief Attempt to steal the boarded ship's credits.
 *
 *    @param wdw Window triggering the function.
 *    @param str Unused.
 */
static void board_stealCreds( unsigned int wdw, char* str )
{
   (void)str;
   Pilot* p;
   credits_t credits;
   char buf[STRMAX_SHORT];

   p = pilot_get(player.p->target);

   if (p->credits==0) { /* you can't steal from the poor */
      player_messageRaw(_("#oThe ship has no credits."));
      return;
   }

   credits = p->credits * player.p->stats.loot_mod;
   player_modCredits(credits);
   p->credits = 0;
   board_update(wdw); /* update the lack of credits */

   credits2str(buf, sizeof(buf), credits, 2);
   player_message(p_("loot_credits", "#oYou loot %s from the ship."), buf);
}


/**
 * @brief Attempt to steal the boarded ship's cargo.
 *
 *    @param wdw Window triggering the function.
 *    @param str Unused.
 */
static void board_stealCargo( unsigned int wdw, char* str )
{
   (void) str;
   Pilot* p;

   p = pilot_get(player.p->target);

   if (array_size(p->commodities)==0) { /* no cargo */
      player_messageRaw(_("#oThe ship has no cargo."));
      return;
   }
   else if (pilot_cargoFree(player.p) <= 0) {
      player_messageRaw(_("#rYou have no room for the ship's cargo."));
      return;
   }

   /* TODO: Allow the player control over what cargo to steal. */
   pilot_boardStealCargo(player.p, p);

   board_update( wdw );
   player_messageRaw(_("#oYou loot the ship's cargo."));
}


/**
 * @brief Attempt to steal the boarded ship's fuel.
 *
 *    @param wdw Window triggering the function.
 *    @param str Unused.
 */
static void board_stealFuel( unsigned int wdw, char* str )
{
   (void)str;
   Pilot* p;
   double stolen_fuel;

   p = pilot_get(player.p->target);

   if (p->fuel <= 0) { /* no fuel. */
      player_messageRaw(_("#oThe ship has no fuel."));
      return;
   }
   else if (player.p->fuel >= player.p->fuel_max) {
      player_messageRaw(_("#rYour ship is at maximum fuel capacity."));
      return;
   }

   stolen_fuel = pilot_boardStealFuel(player.p, p);

   board_update(wdw);
   player_message(_("#oYou loot %.0f kL of fuel from the ship."), stolen_fuel);
}


/**
 * @brief Attempt to steal everything.
 *
 *    @param wdw Window triggering the function.
 *    @param str Unused.
 */
static void board_stealAll(unsigned int wdw, char *str)
{
   Pilot *p = pilot_get(player.p->target);

   if (p->credits > 0)
      board_stealCreds(wdw, str);

   if ((p->fuel > 0) && (player.p->fuel < player.p->fuel_max))
      board_stealFuel(wdw, str);

   if ((array_size(p->commodities) > 0)
         && (pilot_cargoFree(player.p) > 0))
      board_stealCargo(wdw, str);

   board_exit(wdw, str);
}


/**
 * @brief Updates the boarding window fields.
 *
 *    @param wdw Window to update.
 */
static void board_update( unsigned int wdw )
{
   int i, l;
   int total_cargo, fuel;
   double c;
   int ic;
   char str[STRMAX_SHORT];
   char str2[STRMAX_SHORT];
   char cred[STRMAX_SHORT];
   Pilot *p;

   p = pilot_get(player.p->target);

   /* Credits. */
   credits2str(cred, sizeof(cred), p->credits * player.p->stats.loot_mod, 2);
   window_modifyText( wdw, "txtDataCredits", cred );

   /* Fuel. */
   fuel = round( player.p->stats.loot_mod * (double)p->fuel );
   if (fuel <= 0)
      snprintf( str, sizeof(str), _("none") );
   else
      snprintf(str, sizeof(str), n_("%d kL", "%d kL", fuel), fuel);
   window_modifyText( wdw, "txtDataFuel", str );

   /* Commodities. */
   if ((array_size(p->commodities)==0))
      snprintf( str, sizeof(str), _("none") );
   else {
      c = 0.;
      l = 0;

      for (i=0; i<array_size(p->commodities); i++) {
         if (p->commodities[i].commodity == NULL)
            continue;

         ic = round(player.p->stats.loot_mod * (double)p->commodities[i].quantity);

         if (ic > 0) {
            c += ic;

            if (l > 0)
               l += scnprintf(&str2[l], sizeof(str2)-l, _(", "));

            l += scnprintf(&str2[l], sizeof(str2)-l,
                  "%s", _(p->commodities[i].commodity->name));
         }
      }

      total_cargo = round(c);
      if (total_cargo > 0)
         snprintf(str, sizeof(str),
               n_("%d kt (%s)", "%d kt (%s)", total_cargo),
               total_cargo, str2);
   }
   window_modifyText( wdw, "txtDataCargo", str );
}


/**
 * @brief Attempt to steal a target's cargo.
 *
 *    @param p The pilot boarding.
 *    @param target The pilot being stolen from.
 *    @return Amount of cargo stolen.
 */
static int pilot_boardStealCargo(Pilot *p, Pilot *target)
{
   int i = 0;
   int q = 1;
   int stolen = 0;
   PilotCommodity commod;

   /* Steal as much as possible until full or until target has no more
    * non-mission cargo, whichever comes first. */
   while ((array_size(target->commodities) > i) && (q > 0)) {
      commod = target->commodities[i];

      /* Don't loot mission cargo since that might break missions. */
      if (commod.id != 0) {
         /* Cargo is not being removed, so increment the index we check
          * so we can steal the next cargo. */
         i++;
         continue;
      }

      q = round(p->stats.loot_mod * (double)commod.quantity);
      if (q > 0) {
         q = pilot_cargoAdd(p, commod.commodity, q, 0);
         q = pilot_cargoRm(target, commod.commodity, q);
         stolen += q;
      }
      else if (commod.quantity > 0) {
         /* Can't loot any more cargo, so break from the loop. */
         break;
      }
      else {
         /* Pilot has phantom cargo. Remove the cargo, but set q to 1 so
          * that we don't stop looting cargo too early. */
         pilot_cargoRm(target, commod.commodity, q);
         q = 1;
      }
   }

   return stolen;
}


/**
 * @brief Attempt to steal a target's fuel.
 *
 *    @param p The pilot boarding.
 *    @param target The pilot being stolen from.
 */
static double pilot_boardStealFuel(Pilot *p, Pilot *target)
{
   double stolen_fuel;
   double fuel_free;

   if (p->fuel < p->fuel_max) {
      fuel_free = p->fuel_max - p->fuel;
      stolen_fuel = MIN(target->fuel, p->fuel_max - p->fuel);
      stolen_fuel *= p->stats.loot_mod;
      p->fuel = MIN(p->fuel + stolen_fuel, p->fuel_max);
      target->fuel = MAX(target->fuel - stolen_fuel, 0);
      return MIN(fuel_free, stolen_fuel);
   }

   return 0.;
}


/**
 * @brief Has a pilot attempt to board another pilot.
 *
 *    @param p Pilot doing the boarding.
 *    @return 1 if target was boarded.
 */
int pilot_board( Pilot *p )
{
   Pilot *target;
   HookParam hparam[2];

   /* Make sure target is valid. */
   target = pilot_get(p->target);
   if (target == NULL) {
      DEBUG("NO TARGET");
      return 0;
   }

   /* Check if can board. */
   if (!pilot_isDisabled(target))
      return 0;
   else if (vect_dist(&p->solid->pos, &target->solid->pos)
         > target->ship->gfx_space->sw * PILOT_SIZE_APPROX)
      return 0;
   else if (vect_dist(&p->solid->vel, &target->solid->vel)
         > MAX_HYPERSPACE_VEL)
      return 0;

   /* Set speed to target's speed. */
   vect_cset(&p->solid->vel, VX(target->solid->vel), VY(target->solid->vel));

   /* Set the boarding flag. */
   pilot_setFlag(target, PILOT_BOARDED);
   pilot_setFlag(p, PILOT_BOARDING);

   /* Set time it takes to board. */
   p->ptimer = 3.;

   /* Run pilot board hook. */
   hparam[0].type = HOOK_PARAM_PILOT;
   hparam[0].u.lp = p->id;
   hparam[1].type = HOOK_PARAM_SENTINEL;
   pilot_runHookParam(target, PILOT_HOOK_BOARD, hparam, 1);
   hparam[0].u.lp = target->id;
   pilot_runHookParam(p, PILOT_HOOK_BOARDING, hparam, 1);

   return 1;
}


/**
 * @brief Finishes the boarding.
 *
 *    @param p Pilot to finish the boarding.
 */
void pilot_boardComplete( Pilot *p )
{
   Pilot *target;
   credits_t worth;
   char creds[STRMAX_SHORT];
   int cargo_stolen;

   /* Make sure target is valid. */
   target = pilot_get(p->target);
   if (target == NULL)
      return;

   if (pilot_isPlayer(target)) {
      /* Steal credits (just a few in the case of the player). */
      worth = MIN(0.05*pilot_worth(target), target->credits);
      p->credits += worth * p->stats.loot_mod;
      target->credits -= worth;
      credits2str(creds, sizeof(creds), worth, 2);
      player_message(_("#%c%s#0 has plundered %s from your ship!"),
            pilot_getFactionColourChar(p), p->name, creds);

      /* Steal cargo. */
      cargo_stolen = pilot_boardStealCargo(p, target);
      if (cargo_stolen > 0) {
         player_message(
            n_("#%c%s#0 has stolen %d kt of cargo from your ship!",
               "#%c%s#0 has stolen %d kt of cargo from your ship!",
               cargo_stolen),
            pilot_getFactionColourChar(p), p->name, cargo_stolen);
      }
   }
   else {
      /* Steal credits. */
      p->credits += target->credits * p->stats.loot_mod;
      target->credits = 0.;

      /* Steal cargo. */
      pilot_boardStealCargo(p, target);

      /* Steal fuel. */
      pilot_boardStealFuel(p, target);
   }

   /* Finish the boarding. */
   pilot_rmFlag(p, PILOT_BOARDING);
}

