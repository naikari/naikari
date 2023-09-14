/*
 * See Licensing and Copyright notice in naev.h
 */


/**
 * @file pilot_outfit.c
 *
 * @brief Handles pilot outfits.
 */



/** @cond */
#include "naev.h"
/** @endcond */

#include "array.h"
#include "escort.h"
#include "gui.h"
#include "log.h"
#include "nstring.h"
#include "nxml.h"
#include "outfit.h"
#include "pause.h"
#include "pilot.h"
#include "player.h"
#include "slots.h"
#include "space.h"
#include "nlua.h"
#include "nlua_pilot.h"


/*
 * Prototypes.
 */
static int pilot_hasOutfitLimit( Pilot *p, const char *limit );


/**
 * @brief Updates the lockons on the pilot's launchers
 *
 *    @param p Pilot being updated.
 *    @param o Slot being updated.
 *    @param t Pilot that is currently the target of p (or NULL if not applicable).
 *    @param a Angle to update if necessary. Should be initialized to -1 before the loop.
 *    @param dt Current delta tick.
 */
void pilot_lockUpdateSlot( Pilot *p, PilotOutfitSlot *o, Pilot *t, double *a, double dt )
{
   double max, old;
   double x,y, ang, arc;
   int locked;

   /* No target. */
   if (t == NULL)
      return;

   /* Nota  seeker. */
   if (!outfit_isSeeker(o->outfit))
      return;

   /* Check arc. */
   arc = o->outfit->u.lau.arc;
   if (p->stats.turret_conversion)
      arc = 0.;

   if (arc > 0.) {
      /* We use an external variable to set and update the angle if necessary. */
      if (*a < 0.) {
         x     = t->solid->pos.x - p->solid->pos.x;
         y     = t->solid->pos.y - p->solid->pos.y;
         ang   = ANGLE( x, y );
         *a    = FABS( angle_diff( ang, p->solid->dir ) );
      }

      /* Decay if not in arc. */
      if (*a > arc) {
         /* Limit decay to the lockon time for this launcher. */
         max = o->outfit->u.lau.lockon;

         /* When a lock is lost, immediately gain half the lock timer.
          * This is meant as an incentive for the aggressor not to lose the lock,
          * and for the target to try and break the lock. */
         old = o->u.ammo.lockon_timer;
         o->u.ammo.lockon_timer += dt;
         if ((old <= 0.) && (o->u.ammo.lockon_timer > 0.))
            o->u.ammo.lockon_timer += o->outfit->u.lau.lockon / 2.;

         /* Cap at max. */
         if (o->u.ammo.lockon_timer > max)
            o->u.ammo.lockon_timer = max;

         /* Out of arc. */
         o->u.ammo.in_arc = 0;
         return;
      }
   }

   /* In arc. */
   o->u.ammo.in_arc = 1;
   locked = (o->u.ammo.lockon_timer < 0.);

   /* Lower timer. When the timer reaches zero, the lock is established. */
   max = -o->outfit->u.lau.lockon/3.;
   if (o->u.ammo.lockon_timer > max) {
      o->u.ammo.lockon_timer -= dt;

      /* Cap at -max/3. */
      if (o->u.ammo.lockon_timer < max)
         o->u.ammo.lockon_timer = max;

      /* Trigger lockon hook. */
      if (!locked && (o->u.ammo.lockon_timer < 0.))
         pilot_runHook( p, PILOT_HOOK_LOCKON );
   }
}


/**
 * @brief Clears pilot's missile lockon timers.
 *
 *    @param p Pilot to clear missile lockon timers.
 */
void pilot_lockClear( Pilot *p )
{
   int i;
   PilotOutfitSlot *o;

   for (i=0; i<array_size(p->outfits); i++) {
      o = p->outfits[i];
      if (o->outfit == NULL)
         continue;
      if (!outfit_isSeeker(o->outfit))
         continue;

      /* Clear timer. */
      o->u.ammo.lockon_timer = o->outfit->u.lau.lockon;

      /* Clear arc. */
      o->u.ammo.in_arc = 0;
   }
}


/**
 * @brief Gets the mount position of a pilot.
 *
 * Position is relative to the pilot.
 *
 *    @param p Pilot to get mount position of.
 *    @param w Slot of the mount.
 *    @param[out] v Position of the mount.
 *    @return 0 on success.
 */
int pilot_getMount( const Pilot *p, const PilotOutfitSlot *w, Vector2d *v )
{
   double a, x, y;
   double cm, sm;
   const ShipMount *m;

   /* Calculate the sprite angle. */
   a  = (double)(p->tsy * p->ship->gfx_space->sx + p->tsx);
   a *= p->ship->mangle;

   /* 2d rotation matrix
    * [ x' ]   [  cos  sin  ]   [ x ]
    * [ y' ] = [ -sin  cos  ] * [ y ]
    *
    * dir is inverted so that rotation is counter-clockwise.
    */
   m = &w->sslot->mount;
   cm = cos(-a);
   sm = sin(-a);
   x = m->x * cm + m->y * sm;
   y = m->x *-sm + m->y * cm;

   /* Correction for ortho perspective. */
   y *= M_SQRT1_2;

   /* Don't forget to add height. */
   y += m->h;

   /* Get the mount and add the player.p offset. */
   vect_cset( v, x, y );

   return 0;
}


/**
 * @brief Docks the pilot on its target pilot.
 *
 *    @param p Pilot that wants to dock.
 *    @param target Pilot to dock on.
 *    @return 0 on successful docking.
 */
int pilot_dock( Pilot *p, Pilot *target )
{
   int i;
   const Outfit *o = NULL;
   PilotOutfitSlot* dockslot;

   /* Must belong to target */
   if (p->dockpilot != target->id)
      return -1;

   /* Must have a dockslot */
   dockslot = pilot_getDockSlot( p );
   if (dockslot == NULL)
      return -1;

   /* Must be close. */
   if (vect_dist(&p->solid->pos, &target->solid->pos) >
         target->ship->gfx_space->sw * PILOT_SIZE_APPROX )
      return -1;

   /* Cannot be going much faster. */
   if ((pow2(VX(p->solid->vel)-VX(target->solid->vel)) +
            pow2(VY(p->solid->vel)-VY(target->solid->vel))) >
         (double)pow2(MAX_HYPERSPACE_VEL))
      return -1;

   /* Grab dock ammo */
   i = p->dockslot;
   if (p->dockslot < array_size(target->outfits))
      o = outfit_ammo(target->outfits[i]->outfit);

   /* Try to add fighter. */
   dockslot->u.ammo.deployed--;
   p->dockpilot = 0;
   p->dockslot = -1;

   if (o == NULL)
      return -1;

   /* Add the pilot's outfit. */
   if (pilot_addAmmo(target, target->outfits[i], o, 1) != 1)
      return -1;

   /* Remove from pilot's escort list. */\
   for (i=0; i<array_size(target->escorts); i++) {
      if ((target->escorts[i].type == ESCORT_TYPE_BAY) &&
            (target->escorts[i].id == p->id))
         break;
   }
   /* Not found as pilot's escorts. */
   if (i >= array_size(target->escorts))
      return -1;
   /* Free if last pilot. */
   if (array_size(target->escorts) == 1)
      escort_freeList(target);
   else
      escort_rmListIndex(target, i);

   /* Destroy the pilot. */
   pilot_delete(p);

   return 0;
}


/**
 * @brief Checks to see if the pilot has deployed ships.
 *
 *    @param p Pilot to see if has deployed ships.
 *    @return 1 if pilot has deployed ships, 0 otherwise.
 */
int pilot_hasDeployed( Pilot *p )
{
   int i;
   for (i=0; i<array_size(p->outfits); i++) {
      if (p->outfits[i]->outfit == NULL)
         continue;
      if (outfit_isFighterBay(p->outfits[i]->outfit))
         if (p->outfits[i]->u.ammo.deployed > 0)
            return 1;
   }
   return 0;
}


/**
 * @brief Instantly deletes all of the pilot's deployed escorts.
 *
 *    @param p Pilot to undeploy ships for.
 */
void pilot_undeployAll( Pilot *p )
{
   int i;
   PilotOutfitSlot* dockslot;
   Pilot *escort;

   for (i=array_size(p->escorts)-1; i>=0; i--) {
      escort = pilot_get(p->escorts[i].id);
      if ((escort == NULL) || pilot_isFlag(escort, PILOT_DEAD)
            || pilot_isFlag(escort, PILOT_DELETE))
         continue;

      dockslot = pilot_getDockSlot(escort);
      if (dockslot == NULL)
         continue;

      pilot_delete(escort);
   }
}


/**
 * @brief Adds an outfit to the pilot, ignoring CPU or other limits.
 *
 * @note Does not call pilot_calcStats().
 *
 *    @param pilot Pilot to add the outfit to.
 *    @param outfit Outfit to add to the pilot.
 *    @param s Slot to add ammo to.
 *    @return 0 on success.
 */
int pilot_addOutfitRaw( Pilot* pilot, const Outfit* outfit, PilotOutfitSlot *s )
{
   const Outfit *o;

   /* Set the outfit. */
   s->outfit   = outfit;

   /* Set some default parameters. */
   s->timer    = 0.;

   /* Some per-case scenarios. */
   if (outfit_isFighterBay(outfit)) {
      s->u.ammo.outfit   = NULL;
      s->u.ammo.quantity = 0;
      s->u.ammo.deployed = 0;
   }
   if (outfit_isTurret(outfit)) /* used to speed up AI */
      pilot->nturrets++;
   else if (outfit_isBolt(outfit))
      pilot->ncannons++;
   else if (outfit_isAfterburner(outfit))
      pilot->nafterburners++;

   if (outfit_isBeam(outfit)) { /* Used to speed up some calculations. */
      s->u.beamid = 0;
      pilot->nbeams++;
   }
   if (outfit_isLauncher(outfit)) {
      s->u.ammo.outfit   = NULL;
      s->u.ammo.quantity = 0;
      s->u.ammo.deployed = 0; /* Just in case. */
   }

   /* Check if active. */
   o = s->outfit;
   s->active = outfit_isActive(o);

   /* Update heat. */
   pilot_heatCalcSlot( s );

   return 0;
}


/**
 * @brief Tests to see if an outfit can be added.
 *
 *    @param pilot Pilot to add outfit to.
 *    @param outfit Outfit to add.
 *    @param s Slot adding outfit to.
 *    @param warn Whether or not should generate a warning.
 *    @return 0 if can add, -1 if can't.
 */
int pilot_addOutfitTest( Pilot* pilot, const Outfit* outfit, PilotOutfitSlot *s, int warn )
{
   const char *str;

   /* See if slot has space. */
   if (s->outfit != NULL) {
      if (warn)
         WARN( _("Pilot '%s': trying to add outfit '%s' to slot that already has an outfit"),
               pilot->name, outfit->name );
      return -1;
   }
   else if (pilot->cpu < outfit_cpu(outfit)) {
      if (warn)
         WARN( _("Pilot '%s': Not enough CPU to add outfit '%s'"),
               pilot->name, outfit->name );
      return -1;
   }
   else if ((str = pilot_canEquip( pilot, s, outfit)) != NULL) {
      if (warn)
         WARN( _("Pilot '%s': Trying to add outfit but %s"),
               pilot->name, str );
      return -1;
   }
   return 0;
}



/**
 * @brief Adds an outfit to the pilot.
 *
 *    @param pilot Pilot to add the outfit to.
 *    @param outfit Outfit to add to the pilot.
 *    @param s Slot to add ammo to.
 *    @return 0 on success.
 */
int pilot_addOutfit( Pilot* pilot, const Outfit* outfit, PilotOutfitSlot *s )
{
   int ret;

   /* Test to see if outfit can be added. */
   ret = pilot_addOutfitTest( pilot, outfit, s, 1 );
   if (ret != 0)
      return -1;

   /* Add outfit. */
   ret = pilot_addOutfitRaw( pilot, outfit, s );

   /* Recalculate the stats */
   pilot_calcStats(pilot);

   return ret;
}


/**
 * @brief Removes an outfit from the pilot without doing any checks.
 *
 * @note Does not run pilot_calcStats().
 *
 *    @param pilot Pilot to remove the outfit from.
 *    @param s Slot to remove.
 *    @return 0 on success.
 */
int pilot_rmOutfitRaw( Pilot* pilot, PilotOutfitSlot *s )
{
   int ret;

   /* Force turn off if necessary. */
   if (s->state==PILOT_OUTFIT_ON)
      pilot_outfitOff( pilot, s );

   /* Decrement counters if necessary. */
   if (s->outfit != NULL) {
      if (outfit_isTurret(s->outfit))
         pilot->nturrets--;
      else if (outfit_isBolt(s->outfit))
         pilot->ncannons--;
      if (outfit_isBeam(s->outfit))
         pilot->nbeams--;
   }

   /* Remove the outfit. */
   ret         = (s->outfit==NULL);
   s->outfit   = NULL;

   /* Remove secondary and such if necessary. */
   if (pilot->afterburner == s)
      pilot->afterburner = NULL;

   return ret;
}


/**
 * @brief Removes an outfit from the pilot.
 *
 *    @param pilot Pilot to remove the outfit from.
 *    @param s Slot to remove.
 *    @return 0 on success.
 */
int pilot_rmOutfit( Pilot* pilot, PilotOutfitSlot *s )
{
   const char *str;
   int ret;

   str = pilot_canEquip( pilot, s, NULL );
   if (str != NULL) {
      WARN(_("Pilot '%s': Trying to remove outfit but %s"),
            pilot->name, str );
      return -1;
   }

   ret = pilot_rmOutfitRaw( pilot, s );

   /* recalculate the stats */
   pilot_calcStats(pilot);

   return ret;
}
//TODO: fix comment to conform to Naev's style and represent changes
/**
 * @brief Pilot slot safety check - makes sure stats are safe.
 *
 *    @param p Pilot to check.
 *    @return 0 if a slot doesn't fit, !0 otherwise.
 */
int pilot_slotsCheckSafety( Pilot *p )
{
   int i;
   for (i=0; i<array_size(p->outfits); i++)
      if ((p->outfits[i]->outfit != NULL) &&
            !outfit_fitsSlot( p->outfits[i]->outfit, &p->outfits[i]->sslot->slot ))
         return 0;
   return 1;
}
//TODO: fix comment to conform to Naev's style and represent changes
/**
 * @brief Pilot required (core) slot filled check - makes sure they are filled.
 *
 *    @param p Pilot to check.
 *    @return 0 if a slot is missing, !0 otherwise.
 */
int pilot_slotsCheckRequired( Pilot *p )
{
   int i;

   for (i=0; i < array_size(p->outfit_structure); i++)
      if (p->outfit_structure[i].sslot->required && p->outfit_structure[i].outfit == NULL)
         return 0;

   for (i=0; i < array_size(p->outfit_utility); i++)
      if (p->outfit_utility[i].sslot->required && p->outfit_utility[i].outfit == NULL)
         return 0;

   for (i=0; i < array_size(p->outfit_weapon); i++)
      if (p->outfit_weapon[i].sslot->required && p->outfit_weapon[i].outfit == NULL)
         return 0;

   return 1;
}


#define SPACEWORTHY_CHECK(cond, msg) \
   if (cond) { \
      ret++; \
      if (buf != NULL) { \
         pos += scnprintf(&buf[pos], bufSize-pos, ("!! ")); \
         pos += scnprintf(&buf[pos], bufSize-pos, (msg)); \
         pos += scnprintf(&buf[pos], bufSize-pos, ("\n")); \
      } \
   }
/**
 * @brief Pilot safety report - makes sure stats are safe.
 *
 *    @param p Pilot to check.
 *    @param buf Buffer to fill. Set to NULL if uninterested.
 *    @param bufSize Size of the buffer.
 *    @return Number of issues encountered.
 */
int pilot_reportSpaceworthy( Pilot *p, char *buf, int bufSize )
{
   int pos = 0;
   int ret = 0;

   /* Slot size validity */
   SPACEWORTHY_CHECK(!pilot_slotsCheckSafety(p),
         _("Some outfits are in incompatible slots"));

   /* Core Slots */
   SPACEWORTHY_CHECK(!pilot_slotsCheckRequired(p),
         _("Not All Core Slots are equipped"));
   /* CPU. */
   SPACEWORTHY_CHECK(p->cpu < 0, _("Insufficient CPU"));

   /* Movement. */
   SPACEWORTHY_CHECK(p->thrust < 0., _("Insufficient Thrust"));
   SPACEWORTHY_CHECK(p->speed < 0., _("Insufficient Speed"));
   SPACEWORTHY_CHECK(p->turn < 0., _("Insufficient Turn"));

   /* Health. */
   SPACEWORTHY_CHECK(p->armour <= 0., _("Insufficient Armor"));
   SPACEWORTHY_CHECK(p->armour_regen < 0.,
         _("Insufficient Armor Regeneration\n"));
   SPACEWORTHY_CHECK(p->shield < 0., _("Insufficient Shield"));
   SPACEWORTHY_CHECK(p->shield_regen < 0.,
         _("Insufficient Shield Regeneration"));
   SPACEWORTHY_CHECK(p->energy_max < 0., _("Insufficient Energy"));
   SPACEWORTHY_CHECK(p->energy_regen < 0.,
         _("Insufficient Energy Regeneration"));

   /* Misc. */
   SPACEWORTHY_CHECK(p->fuel_max < 0., _("Insufficient Fuel Maximum"));
   SPACEWORTHY_CHECK(p->fuel_consumption < 0.,
         _("Insufficient Fuel Consumption"));
   SPACEWORTHY_CHECK(p->fuel_regen < 0., _("Insufficient Fuel Regeneration"));
   SPACEWORTHY_CHECK(p->cargo_free < 0, _("Insufficient Cargo Space"));

   if (buf != NULL) {
      /* buffer is full, lets write that there is more then what's copied */
      if (pos > bufSize-1) {
         buf[bufSize-4] = '.';
         buf[bufSize-3] = '.';
         buf[bufSize-2] = '.';
         /* buf[bufSize-1]='\0'; already done for us */
      }
      else {
         if (pos == 0)
            /*string is empty so no errors encountered */
            snprintf(buf, bufSize, _("Spaceworthy"));
      }
   }

   return ret;
}
#undef SPACEWORTHY_CHECK


/**
 * @brief Checks to see if a pilot has an outfit with a specific outfit type.
 *
 *    @param p Pilot to check.
 *    @param limit Outfit (limiting) type to check.
 *    @return the amount of outfits of this type the pilot has.
 */
static int pilot_hasOutfitLimit( Pilot *p, const char *limit )
{
   int i;
   const Outfit *o;
   for (i = 0; i<array_size(p->outfits); i++) {
      o = p->outfits[i]->outfit;
      if (o == NULL)
         continue;
      if ((o->limit != NULL) && (strcmp(o->limit,limit)==0))
         return 1;
   }
   return 0;
}

/**
 * @brief Checks to see if can equip/remove an outfit from a slot.
 *
 *    @param p Pilot to check if can equip.
 *    @param s Slot being checked to see if it can equip/remove an outfit.
 *    @param o Outfit to check (NULL if being removed).
 *    @return NULL if can swap, or error message if can't.
 */
const char* pilot_canEquip( Pilot *p, PilotOutfitSlot *s, const Outfit *o )
{
   /* Just in case. */
   if ((p==NULL) || (s==NULL))
      return _("Nothing selected.");

   if (o!=NULL) {
      /* Check slot type. */
      if (!outfit_fitsSlot( o, &s->sslot->slot ))
         return _("Does not fit slot.");
      /* Check outfit limit. */
      if ((o->limit != NULL) && pilot_hasOutfitLimit( p, o->limit ))
         return _("Already have an outfit of this type installed");
      /* Check to see if already equipped unique. */
      if (outfit_isProp(o,OUTFIT_PROP_UNIQUE) && (pilot_numOutfit(p,o)>0))
         return _("Can only install unique outfit once.");
   }

   return NULL;
}


/**
 * @brief Adds some ammo to the pilot stock.
 *
 *    @param pilot Pilot to add ammo to.
 *    @param s Slot to add ammo to.
 *    @param ammo Ammo to add.
 *    @param quantity Amount to add.
 *    @return Amount actually added.
 */
int pilot_addAmmo( Pilot* pilot, PilotOutfitSlot *s, const Outfit* ammo, int quantity )
{
   int q, max;
   (void) pilot;

   /* Failure cases. */
   if (s->outfit == NULL) {
      WARN(_("Pilot '%s': Trying to add ammo to unequipped slot."), pilot->name );
      return 0;
   }
   else if (!outfit_isLauncher(s->outfit) && !outfit_isFighterBay(s->outfit)) {
      WARN(_("Pilot '%s': Trying to add ammo to non-launcher/fighterbay type outfit '%s'"),
            pilot->name, s->outfit->name);
      return 0;
   }
   else if (!outfit_isAmmo(ammo) && !outfit_isFighter(ammo)) {
      WARN( _("Pilot '%s': Trying to add non-ammo/fighter type outfit '%s' as ammo."),
            pilot->name, ammo->name );
      return 0;
   }
   else if (outfit_isLauncher(s->outfit) && outfit_isFighter(ammo)) {
      WARN(_("Pilot '%s': Trying to add fighter '%s' as launcher '%s' ammo"),
            pilot->name, ammo->name, s->outfit->name );
      return 0;
   }
   else if (outfit_isFighterBay(s->outfit) && outfit_isAmmo(ammo)) {
      WARN(_("Pilot '%s': Trying to add ammo '%s' as fighter bay '%s' ammo"),
            pilot->name, ammo->name, s->outfit->name );
      return 0;
   }
   else if ((s->u.ammo.outfit != NULL) && (s->u.ammo.quantity > 0) &&
         (s->u.ammo.outfit != ammo)) {
      WARN(_("Pilot '%s': Trying to add ammo to outfit that already has ammo."),
            pilot->name );
      return 0;
   }

   /* Set the ammo type. */
   s->u.ammo.outfit = ammo;

   /* Add the ammo. */
   max = pilot_maxAmmoO(pilot,s->outfit) - s->u.ammo.deployed;
   q = s->u.ammo.quantity; /* Amount have. */
   s->u.ammo.quantity += quantity;
   s->u.ammo.quantity = MIN(max, s->u.ammo.quantity);
   q = s->u.ammo.quantity - q; /* Amount actually added. */
   pilot->mass_outfit += q * s->u.ammo.outfit->mass;
   pilot_updateMass(pilot);
   pilot_calcStats(pilot);

   return q;
}


/**
 * @brief Removes some ammo from the pilot stock.
 *
 *    @param pilot Pilot to remove ammo from.
 *    @param s Slot to remove ammo from.
 *    @param quantity Amount to remove.
 *    @return Amount actually removed.
 */
int pilot_rmAmmo( Pilot* pilot, PilotOutfitSlot *s, int quantity )
{
   (void) pilot;
   int q;

   /* Failure cases. */
   if (s->outfit == NULL) {
      WARN(_("Pilot '%s': Trying to remove ammo from unequipped slot."), pilot->name );
      return 0;
   }
   else if (!outfit_isLauncher(s->outfit) && !outfit_isFighterBay(s->outfit)) {
      WARN(_("Pilot '%s': Trying to remove ammo from non-launcher/fighter bay type outfit '%s'"),
            pilot->name, s->outfit->name);
      return 0;
   }

   /* No ammo already. */
   if (s->u.ammo.outfit == NULL)
      return 0;

   /* Remove ammo. */
   q = MIN(quantity, s->u.ammo.quantity);
   s->u.ammo.quantity -= q;
   pilot->mass_outfit -= q * s->u.ammo.outfit->mass;
   pilot_updateMass(pilot);
   pilot_calcStats(pilot);
   /* We don't set the outfit to null so it "remembers" old ammo. */

   return q;
}


/**
 * @brief Gets the number of ammo units on the ship
 *
 *    @param pilot Pilot to count the ammo on
 *    @@return The integer count of ammo units on pilot
 */
int pilot_countAmmo( const Pilot* pilot )
{
   int nammo = 0, i;
   PilotOutfitSlot* po;
   const Outfit* outfit;
   for (i=0; i<array_size(pilot->outfits); i++) {
     po = pilot->outfits[i];
     if (po == NULL)
        continue;
     outfit = po->outfit;
     if (outfit == NULL)
        continue;
     if (!outfit_isLauncher(po->outfit))
        continue;
     nammo += po->u.ammo.quantity;
   }
   return nammo;
}


/**
 * @brief The maximum amount of ammo the pilot's current ship can hold.
 *
 *    @param pilot Pilot to get the count from
 *    @@return An integer, the max amount of ammo that can be held.
 */
int pilot_maxAmmo( const Pilot* pilot )
{
  int max = 0, i;
  PilotOutfitSlot* po;
  const Outfit* outfit;
  for (i=0; i<array_size(pilot->outfits); i++) {
     po = pilot->outfits[i];
     if (po == NULL)
        continue;
     outfit = po->outfit;
     if (outfit == NULL)
        continue;
     if (!outfit_isLauncher(outfit))
        continue;
     max += outfit->u.lau.amount;
  }
  max = round( (double)max * pilot->stats.ammo_capacity );
  return max;
}


/**
 * @brief Gets the maximum available ammo for a pilot for a specific outfit.
 */
int pilot_maxAmmoO( const Pilot* p, const Outfit *o )
{
   int max;
   if (o==NULL)
      return 0;
   else if (outfit_isLauncher(o))
      max = round( (double)o->u.lau.amount * p->stats.ammo_capacity );
   else if (outfit_isFighterBay(o))
      max = round( (double)o->u.bay.amount * p->stats.fbay_capacity );
   else
      max = 0;
   return max;
}


/**
 * @brief Fills pilot's ammo completely.
 *
 *    @param pilot Pilot to add ammo to.
 */
void pilot_fillAmmo( Pilot* pilot )
{
   int i, ammo_threshold;
   const Outfit *o, *ammo;

   for (i=0; i<array_size(pilot->outfits); i++) {
      o = pilot->outfits[i]->outfit;

      /* Must be valid outfit. */
      if (o == NULL)
         continue;

      /* Add ammo if able to. */
      ammo = outfit_ammo(o);
      if (ammo == NULL)
         continue;

      /* Initial (raw) ammo threshold */
      ammo_threshold = pilot_maxAmmoO( pilot, o );

      /* Adjust for deployed fighters if needed */
      if (outfit_isFighterBay( o ))
         ammo_threshold -= pilot->outfits[i]->u.ammo.deployed;

      /* Add ammo. */
      pilot_addAmmo( pilot, pilot->outfits[i], ammo,
         ammo_threshold - pilot->outfits[i]->u.ammo.quantity );
   }
}


/**
 * @brief Gets all the outfits in nice (localized) text form.
 *
 *    @param pilot Pilot to get the outfits from.
 *    @return A list of all the outfits in a nice form (in the currently set language).
 */
char* pilot_getOutfits( const Pilot* pilot )
{
   int i;
   char *buf;
   int p, len;

   len = 1024;

   buf = malloc(len);
   buf[0] = '\0';
   p = 0;
   for (i=1; i<array_size(pilot->outfits); i++) {
      if (pilot->outfits[i]->outfit == NULL)
         continue;
      p += scnprintf( &buf[p], len-p, (p==0) ? "%s" : ", %s",
            _(pilot->outfits[i]->outfit->name) );
   }

   if (p==0)
      p += scnprintf( &buf[p], len-p, _("None") );

   (void)p;

   return buf;
}


/**
 * @brief Recalculates the pilot's stats based on his outfits.
 *
 *    @param pilot Pilot to recalculate his stats.
 */
void pilot_calcStats( Pilot* pilot )
{
   int i;
   const Outfit* o;
   PilotOutfitSlot *slot;
   double ac, sc, ec, tm; /* temporary health coefficients to set */
   ShipStats *s;

   /*
    * set up the basic stuff
    */
   /* mass */
   pilot->solid->mass   = pilot->ship->mass;
   pilot->base_mass     = pilot->solid->mass;
   /* cpu */
   pilot->cpu           = 0.;
   /* movement */
   pilot->thrust_base   = pilot->ship->thrust;
   pilot->turn_base     = pilot->ship->turn;
   pilot->speed_base    = pilot->ship->speed;
   /* cargo */
   pilot->cap_cargo     = pilot->ship->cap_cargo;
   /* fuel_consumption. */
   pilot->fuel_consumption = pilot->ship->fuel_consumption;
   /* health */
   ac = (pilot->armour_max > 0.) ? pilot->armour / pilot->armour_max : 0.;
   sc = (pilot->shield_max > 0.) ? pilot->shield / pilot->shield_max : 0.;
   ec = (pilot->energy_max > 0.) ? pilot->energy / pilot->energy_max : 0.;
   pilot->armour_max = pilot->ship->armour;
   pilot->shield_max = pilot->ship->shield;
   pilot->fuel_max = pilot->ship->fuel;
   pilot->armour_regen = pilot->ship->armour_regen;
   pilot->shield_regen = pilot->ship->shield_regen;
   pilot->fuel_regen = pilot->ship->fuel_regen;
   /* Absorption. */
   pilot->dmg_absorb    = pilot->ship->dmg_absorb;
   /* Energy. */
   pilot->energy_max    = pilot->ship->energy;
   pilot->energy_regen  = pilot->ship->energy_regen;
   pilot->energy_loss   = 0.; /* Initially no net loss. */
   /* Radar. */
   pilot->rdr_range     = pilot->ship->rdr_range;
   pilot->rdr_jump_range = pilot->ship->rdr_jump_range;
   /* Stats. */
   s = &pilot->stats;
   tm = s->time_mod;
   *s = pilot->ship->stats_array;

   /*
    * Now add outfit changes
    */
   pilot->mass_outfit   = 0.;
   for (i=0; i<array_size(pilot->outfits); i++) {
      slot = pilot->outfits[i];
      o    = slot->outfit;

      /* Outfit must exist. */
      if (o==NULL)
         continue;

      /* Modify CPU. */
      pilot->cpu -= outfit_cpu(o);

      /* Add mass. */
      pilot->mass_outfit += o->mass;

      /* Keep a separate counter for required (core) outfits. */
      if (sp_required( o->slot.spid ))
         pilot->base_mass += o->mass;

      /* Add ammo mass. */
      if (outfit_ammo(o) != NULL)
         if (slot->u.ammo.outfit != NULL)
            pilot->mass_outfit += slot->u.ammo.quantity * slot->u.ammo.outfit->mass;

      if (outfit_isAfterburner(o)) /* Afterburner */
         pilot->afterburner = pilot->outfits[i]; /* Set afterburner */

      /* Apply modifications. */
      if (outfit_isMod(o)) { /* Modification */
         /* Active outfits must be on to affect stuff. */
         if (slot->active && !(slot->state==PILOT_OUTFIT_ON))
            continue;
         /* Add stats. */
         ss_statsModFromList( s, o->stats );

      }
      else if (outfit_isAfterburner(o)) { /* Afterburner */
         /* Active outfits must be on to affect stuff. */
         if (slot->active && !(slot->state==PILOT_OUTFIT_ON))
            continue;
         /* Add stats. */
         ss_statsModFromList( s, o->stats );
         pilot_setFlag( pilot, PILOT_AFTERBURNER ); /* We use old school flags for this still... */
         pilot->energy_loss += pilot->afterburner->outfit->u.afb.energy; /* energy loss */
      }
      else {
         /* Always add stats for non mod/afterburners. */
         ss_statsModFromList( s, o->stats );
      }
   }

   /* Merge stats. */
   ss_statsMerge( &pilot->stats, &pilot->intrinsic_stats );

   /* Slot voodoo. */
   s = &pilot->stats;

   /*
    * Absolute increases.
    */
   /* Movement. */
   pilot->thrust_base += s->thrust;
   pilot->turn_base += s->turn * M_PI / 180.;
   pilot->speed_base += s->speed;
   /* Health. */
   pilot->armour_max += s->armour;
   pilot->armour_regen += s->armour_regen;
   pilot->shield_max += s->shield;
   pilot->shield_regen += s->shield_regen;
   pilot->energy_max += s->energy;
   pilot->energy_regen += s->energy_regen;
   pilot->fuel_regen += s->fuel_regen;
   /* Radar. */
   pilot->rdr_range += s->rdr_range;
   pilot->rdr_jump_range += s->rdr_jump_range;
   /* Misc. */
   pilot->fuel_max += s->fuel;
   pilot->cap_cargo += s->cargo;

   /*
    * Relative increases.
    */
   /* Movement. */
   pilot->thrust_base *= s->thrust_mod;
   pilot->turn_base *= s->turn_mod;
   pilot->speed_base *= s->speed_mod;
   /* Health. */
   pilot->armour_max *= s->armour_mod;
   pilot->armour_regen *= s->armour_regen_mod;
   pilot->shield_max *= s->shield_mod;
   pilot->shield_regen *= s->shield_regen_mod;
   pilot->energy_max *= s->energy_mod;
   pilot->energy_regen *= s->energy_regen_mod;
   /* Radar. */
   pilot->rdr_range *= s->rdr_range_mod;
   pilot->rdr_jump_range *= s->rdr_jump_range_mod;
   /* cpu */
   pilot->cpu_max = (int)floor((float)(pilot->ship->cpu+s->cpu_max) * s->cpu_mod);
   pilot->cpu += pilot->cpu_max; /* CPU is negative, this just sets it so it's based off of cpu_max. */
   /* Misc. */
   pilot->cap_cargo *= s->cargo_mod;
   s->engine_limit *= s->engine_limit_rel;

   /* Make sure none of the speed variables are zero or lower, as this
    * can cause disastrous and unpredictable results. */
   pilot->thrust_base = MAX(pilot->thrust_base, 0.0001);
   pilot->turn_base = MAX(pilot->turn_base, 0.0001);
   pilot->speed_base = MAX(pilot->speed_base, 0.0001);

   /* Set maximum speed. */
   if (!pilot_isFlag( pilot, PILOT_AFTERBURNER ))
      pilot->solid->speed_max = pilot->speed_base;

   /*
    * Flat increases.
    */
   pilot->armour_regen -= s->armour_regen_malus;
   pilot->shield_regen -= s->shield_regen_malus;
   pilot->energy_regen -= s->energy_regen_malus;
   pilot->energy_loss += s->energy_loss;
   pilot->dmg_absorb = CLAMP(0., 1., pilot->dmg_absorb + s->absorb);

   /* Give the pilot his health proportion back */
   pilot->armour = ac * pilot->armour_max;
   pilot->shield = sc * pilot->shield_max;
   pilot->energy = ec * pilot->energy_max;

   /* Dump excess fuel */
   pilot->fuel = (pilot->fuel_max >= pilot->fuel) ? pilot->fuel : pilot->fuel_max;

   /* Set final energy tau. */
   pilot->energy_tau = pilot->energy_max / pilot->energy_regen;

   /* Cargo has to be reset. */
   pilot_cargoCalc(pilot);

   /* Calculate mass. */
   pilot->solid->mass = s->mass_mod*pilot->ship->mass + pilot->stats.cargo_inertia*pilot->mass_cargo + pilot->mass_outfit;

   /* Calculate the heat. */
   pilot_heatCalc( pilot );

   /* Modulate by mass. */
   pilot_updateMass( pilot );

   /* Update GUI as necessary. */
   gui_setGeneric( pilot );

   /* Update weapon set range. */
   pilot_weapSetUpdateStats( pilot );

   /* In case the time_mod has changed. */
   if (pilot_isPlayer(pilot) && (tm != s->time_mod))
      player_resetSpeed();
}


/**
 * @brief Cures the pilot as if he was landed.
 */
void pilot_healLanded( Pilot *pilot )
{
   pilot->armour = pilot->armour_max;
   pilot->shield = pilot->shield_max;
   pilot->energy = pilot->energy_max;

   pilot->stress = 0.;
   pilot->stimer = 0.;
   pilot->sbonus = 0.;
}


/**
 * @brief Updates the pilot stats after mass change.
 *
 *    @param pilot Pilot to update his mass.
 */
void pilot_updateMass( Pilot *pilot )
{
   double mass, factor;

   /* Set limit. */
   mass = pilot->solid->mass;
   if ((pilot->stats.engine_limit > 0.) && (mass > pilot->stats.engine_limit))
      factor = pilot->stats.engine_limit / mass;
   else
      factor = 1.;

   pilot->thrust = factor * pilot->thrust_base * mass;
   pilot->turn = factor * pilot->turn_base;
   pilot->speed = factor * pilot->speed_base;

   /* limit the maximum speed if limiter is active */
   if (pilot_isFlag(pilot, PILOT_HASSPEEDLIMIT)) {
      pilot->speed = pilot->speed_limit - pilot->thrust / (mass * 3.);
      /* Speed must never go negative or zero. */
      if (pilot->speed <= 0.) {
         /* If speed DOES go ≤ 0, we have to lower thrust. */
         pilot->thrust = 3 * pilot->speed_limit * mass;
         pilot->speed = pilot->speed_limit;
      }
   }

   /* Just to be absolutely safe, never let any of the speed variables
    * be zero. Never. */
   pilot->thrust = MAX(pilot->thrust, 0.0001);
   pilot->turn = MAX(pilot->turn, 0.0001);
   pilot->speed = MAX(pilot->speed, 0.0001);
}


/**
 * @brief Checks to see if a slot has an active outfit that can be toggleable.
 *
 * "Active" in this case refers to any outfit which can be toggled in a
 * weapon set (weapons, afterburners, etc).
 *
 *    @param o Outfit slot to check.
 *    @return 1 if can toggle, 0 otherwise.
 */
int pilot_slotIsActive( const PilotOutfitSlot *o )
{
   const Outfit *oo;
   if (!o->active)
      return 0;

   oo = o->outfit;
   if (oo == NULL)
      return 0;

   /* If it's a modifier, it doesn't count unless it's an activated
    * outfit. */
   if (outfit_isMod(oo) && !oo->u.mod.active)
      return 0;

   return 1;
}
