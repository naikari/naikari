/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file land_shipyard.c
 *
 * @brief Handles the shipyard at land.
 */


/** @cond */
#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "land_shipyard.h"

#include "array.h"
#include "credits.h"
#include "dialogue.h"
#include "hook.h"
#include "land.h"
#include "land_outfits.h"
#include "log.h"
#include "map_find.h"
#include "ndata.h"
#include "nstring.h"
#include "player.h"
#include "slots.h"
#include "space.h"
#include "tk/toolkit_priv.h"
#include "toolkit.h"


/*
 * Vars.
 */
static Ship **shipyard_list = NULL; /**< Array (array.h): Available ships, valid when the shipyard image-array widget is. */
static Ship* shipyard_selected = NULL; /**< Currently selected shipyard ship. */
static ShipOutfitSlot* shipyard_mouseover = NULL;
static double shipyard_altx = 0;
static double shipyard_alty = 0;


/*
 * Helper functions.
 */
static void shipyard_buy( unsigned int wid, char* str );
static void shipyard_trade( unsigned int wid, char* str );
static void shipyard_rmouse( unsigned int wid, char* widget_name );
static void shipyard_renderSlots( double bx, double by, double bw, double bh, void *data );
static void shipyard_renderSlotsRow(double bx, double by, double bw,
      const char *str, ShipOutfitSlot *s);
static void shipyard_renderOverlaySlots(double bx, double by,
      double bw, double bh, void *data);
static int shipyard_mouseSlots(unsigned int wid, SDL_Event* event,
      double mx, double my, double bw, double bh,
      double rx, double ry, void *data);
static void shipyard_mouseSlotsRow(double bx, double by, double bw,
      double mx, double my, ShipOutfitSlot *s);
static void shipyard_find( unsigned int wid, char* str );


/**
 * @brief Opens the shipyard window.
 */
void shipyard_open( unsigned int wid )
{
   int i;
   ImageArrayCell *cships;
   int nships;
   int w, h;
   int iw, ih;
   int bw, bh, padding, off;
   glTexture *t;
   int iconsize;

   /* Mark as generated. */
   land_tabGenerate(LAND_WINDOW_SHIPYARD);

   /* Init vars. */
   shipyard_cleanup();

   /* Get window dimensions. */
   window_dimWindow(wid, &w, &h);

   /* Calculate image array dimensions. */
   iw = 428 + (w - LAND_WIDTH);
   ih = h - 60;

   /* Left padding + per-button padding * nbuttons */
   padding = 20 + 10*5;

   /* Calculate button dimensions. */
   bw = (w - iw - padding) / 4;
   bh = LAND_BUTTON_HEIGHT;

   /* buttons */
   window_addButtonKey(wid, off = -10, 20,
         bw, bh, "btnCloseShipyard",
         _("&Take Off"), land_buttonTakeoff, SDLK_t);
   window_addButtonKey(wid, off -= 10+bw, 20,
         bw, bh, "btnTradeShip",
         _("T&rade-In"), shipyard_trade, SDLK_r);
   window_addButtonKey(wid, off -= 10+bw, 20,
         bw, bh, "btnBuyShip",
         _("&Buy"), shipyard_buy, SDLK_b);
   window_addButtonKey(wid, off -= 10+bw, 20,
         bw, bh, "btnFindShips",
         _("&Find Ships"), shipyard_find, SDLK_f);
   (void)off;

   /* slot types */
   window_addCust(wid, -100, -30, 224, 80, "cstSlots", 0.,
         shipyard_renderSlots, shipyard_mouseSlots, NULL);
   window_custSetClipping(wid, "cstSlots", 0);
   window_custSetOverlay(wid, "cstSlots", shipyard_renderOverlaySlots);

   /* stat text */
   window_addText( wid, -4, -30-80-20, 320, -30-80-20+h-bh, 0, "txtStats",
         &gl_defFont, NULL, NULL );

   /* text */
   window_addText(wid, 20+iw+20, -35,
         w - (20+iw+20) - 20 - MAX(320, SHIP_TARGET_W) - 20, 160, 0,
         "txtDDesc", &gl_defFont, NULL, NULL);
   window_addText(wid, 20+iw+20, 0,
         w - (20+iw+20) - 20 - MAX(320, SHIP_TARGET_W) - 20, 160, 0,
         "txtDescription", &gl_smallFont, NULL, NULL);

   /* set up the ships to buy/sell */
   shipyard_list = tech_getShip( land_planet->tech );
   nships = array_size( shipyard_list );
   cships = calloc( MAX(1,nships), sizeof(ImageArrayCell) );
   if (nships <= 0) {
      cships[0].image = NULL;
      cships[0].caption = strdup(_("None"));
      nships    = 1;
   }
   else {
      for (i=0; i<nships; i++) {
         cships[i].caption = strdup( _(shipyard_list[i]->name) );
         cships[i].image = gl_dupTexture(shipyard_list[i]->gfx_store);
         cships[i].layers = gl_copyTexArray( shipyard_list[i]->gfx_overlays, &cships[i].nlayers );
         if (shipyard_list[i]->rarity > 0) {
            t = rarity_texture( shipyard_list[i]->rarity );
            cships[i].layers = gl_addTexArray( cships[i].layers, &cships[i].nlayers, t );
         }
      }
   }


   iconsize = 128;
   window_addImageArray( wid, 20, 20,
         iw, ih, "iarShipyard", iconsize, iconsize,
         cships, nships, shipyard_update, shipyard_rmouse, NULL );

   /* write the shipyard stuff */
   shipyard_update(wid, NULL);
   /* Set default keyboard focuse to the list */
   window_setFocus( wid , "iarShipyard" );
}
/**
 * @brief Updates the ships in the shipyard window.
 *    @param wid Window to update the ships in.
 *    @param str Unused.
 */
void shipyard_update( unsigned int wid, char* str )
{
   (void)str;
   int i;
   size_t l;
   int w, h, iw, bh, tw, th;
   int y;
   Ship* ship;
   char buf[STRMAX];
   char buf_price[STRMAX_SHORT];
   char buf_credits[STRMAX_SHORT];
   char buf_license[STRMAX_SHORT];

   /* Get dimensions. */
   window_dimWindow(wid, &w, &h);
   iw = 428 + (w - LAND_WIDTH);
   bh = LAND_BUTTON_HEIGHT;

   i = toolkit_getImageArrayPos( wid, "iarShipyard" );

   /* No ships */
   if (i < 0 || array_size(shipyard_list) == 0) {
      window_disableButton(wid, "btnBuyShip");
      window_disableButton(wid, "btnTradeShip");
      snprintf(buf, sizeof(buf), _("#nModel:#0 None"));
      window_modifyText(wid, "txtStats", NULL);
      window_modifyText(wid, "txtDescription", NULL);
      window_modifyText(wid, "txtDDesc", buf);
      return;
   }

   ship = shipyard_list[i];
   shipyard_selected = ship;
   shipyard_mouseover = NULL;

   /* update text */
   window_modifyText( wid, "txtStats", ship->desc_stats );
   price2str(buf_price, sizeof(buf_price), ship_buyPrice(ship),
         player.p->credits, 2);
   credits2str(buf_credits, sizeof(buf_credits), player.p->credits, 2);

   if (ship->license == NULL)
      strncpy(buf_license, _("None"), sizeof(buf_license) - 1);
   else if (player_hasLicense(ship->license)
         || ((land_planet != NULL)
            && planet_hasService(land_planet, PLANET_SERVICE_BLACKMARKET)))
      strncpy(buf_license, _(ship->license), sizeof(buf_license) - 1);
   else
      snprintf(buf_license, sizeof(buf_license), "#X* %s#0", _(ship->license));

   l = scnprintf(buf, sizeof(buf),
         _("#nModel:#0 %s\n"
            "#nClass:#0 %s\n"
            "#nFabricator:#0 %s\n"
            "#nPrice:#0 %s\n"
            "#nMoney:#0 %s\n"
            "#nLicense:#0 %s\n"),
         _(ship->name),
         _(ship->class),
         _(ship->fabricator),
         buf_price,
         buf_credits,
         buf_license);

   if (ship->cpu != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_cpu", "\n#nCPU:#0 %.0f TFLOPS"), ship->cpu);

   l += scnprintf(&buf[l], sizeof(buf) - l,
         p_("ship_mass", "\n#nMass:#0 %G kt"), ship->mass);

   if (ship->thrust != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_acceleration", "\n#nAcceleration:#0 %G mAU/s²"),
            ship->thrust);

   if (ship->speed != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_speed", "\n#nSpeed:#0 %G mAU/s"), ship->speed);

   if (ship->turn != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_turn", "\n#nTurn:#0 %.0f deg/s"), ship->turn*180./M_PI);

   l += scnprintf(&buf[l], sizeof(buf) - l,
         p_("ship_time_constant", "\n#nTime Constant:#0 %.0f%%\n"),
         ship->dt_default * 100.);

   if (ship->dmg_absorb != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_absorb", "\n#nAbsorption:#0 %.0f%%"),
            ship->dmg_absorb * 100.);

   if (ship->shield != 0.) {
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_shield", "\n#nShield:#0 %G GJ"), ship->shield);
      if (ship->shield_regen != 0.)
         l += scnprintf(&buf[l], sizeof(buf) - l,
               p_("ship_shield_regen", "; #nRegeneration:#0 %G GW"),
               ship->shield_regen);
   }
   else if (ship->shield_regen != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_shield_regen", "\n#nShield Regeneration:#0 %G GW"),
            ship->shield_regen);

   if (ship->armour != 0.) {
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_armor", "\n#nArmor:#0 %G GJ"), ship->armour);
      if (ship->armour_regen != 0.)
         l += scnprintf(&buf[l], sizeof(buf) - l,
               p_("ship_armor_regen", "; #nRegeneration:#0 %G GW"),
               ship->armour_regen);
   }
   else if (ship->armour_regen != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_armor_regen", "\n#nArmor Regeneration:#0 %G GW"),
            ship->armour_regen);

   if ((ship->energy != 0.) || (ship->energy_regen != 0.)) {
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_energy", "\n#nEnergy:#0 %G GJ"), ship->energy);
      if (ship->energy_regen != 0.)
         l += scnprintf(&buf[l], sizeof(buf) - l,
               p_("ship_energy_regen", "; #nRegeneration:#0 %G GW"),
               ship->energy_regen);
   }
   else if (ship->energy_regen != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_energy_regen", "\n#nEnergy Regeneration:#0 %G GW"),
            ship->energy_regen);

   if (ship->cap_cargo != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_cargo", "\n#nCargo Space:#0 %.0f kt"), ship->cap_cargo);

   if (ship->fuel != 0.) {
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_fuel", "\n#nFuel:#0 %G kL"), ship->fuel);
      if (ship->fuel_regen != 0.)
         l += scnprintf(&buf[l], sizeof(buf) - l,
               p_("ship_fuel_regen", "; #nRegeneration:#0 %G kL/s"),
               ship->fuel_regen);
   }
   else if (ship->fuel_regen != 0.)
      l += scnprintf(&buf[l], sizeof(buf) - l,
            p_("ship_fuel_regen", "\n#nFuel Regeneration:#0 %G kL/s"),
            ship->fuel_regen);

   l += scnprintf(&buf[l], sizeof(buf) - l,
         p_("ship_fuel_use", "\n#nFuel Use:#0 %G kL"), ship->fuel_consumption);

   l += scnprintf(&buf[l], sizeof(buf) - l,
         p_("ship_radar_range", "\n#nRadar Range:#0 %G mAU"), ship->rdr_range);

   l += scnprintf(&buf[l], sizeof(buf) - l,
         p_("ship_jump_detect_range", "\n#nJump Detect Range:#0 %G mAU"),
         ship->rdr_jump_range);

   y = -35;
   window_modifyText(wid,  "txtDDesc", buf);
   window_dimWidget(wid, "txtDDesc", &tw, &th);
   th = gl_printHeightRaw(&gl_defFont, tw, buf);
   window_resizeWidget(wid, "txtDDesc", tw, th);
   window_moveWidget(wid, "txtDDesc", 20+iw+20, y);

   y -= th + 40;

   window_modifyText(wid, "txtDescription", _(ship->description));
   window_dimWidget(wid, "txtDescription", &tw, &th);
   th = h + y - bh - 20;
   window_resizeWidget(wid, "txtDescription", tw, th);
   window_moveWidget(wid, "txtDescription", 20+iw+20, y);

   if (!shipyard_canBuy( ship->name, land_planet ))
      window_disableButtonSoft( wid, "btnBuyShip");
   else
      window_enableButton( wid, "btnBuyShip");

   if (!shipyard_canTrade( ship->name ))
      window_disableButtonSoft( wid, "btnTradeShip");
   else
      window_enableButton( wid, "btnTradeShip");
}


/**
 * @brief Cleans up shipyard data.
 */
void shipyard_cleanup (void)
{
   array_free( shipyard_list );
   shipyard_list = NULL;
   shipyard_selected = NULL;
}


/**
 * @brief Starts the map find with ship search selected.
 *    @param wid Window buying outfit from.
 *    @param str Unused.
 */
static void shipyard_find( unsigned int wid, char* str )
{
   (void) str;
   map_inputFindType(wid, "ship");
}


/**
 * @brief Player right-clicks on a ship.
 *    @param wid Window player is buying ship from.
 *    @param widget_name Name of the window. (unused)
 */
static void shipyard_rmouse( unsigned int wid, char* widget_name )
{
    return shipyard_buy(wid, widget_name);
}


/**
 * @brief Player attempts to buy a ship.
 *    @param wid Window player is buying ship from.
 *    @param str Unused.
 */
static void shipyard_buy( unsigned int wid, char* str )
{
   (void)str;
   int i;
   char buf[STRMAX_SHORT];
   Ship* ship;
   HookParam hparam[2];

   i = toolkit_getImageArrayPos( wid, "iarShipyard" );
   if (i < 0 || array_size(shipyard_list) == 0)
      return;

   ship = shipyard_list[i];

   credits_t targetprice = ship_buyPrice(ship);

   if (land_errDialogue( ship->name, "buyShip" ))
      return;

   credits2str(buf, sizeof(buf), targetprice, 2);
   if (dialogue_YesNo(_("Are you sure?"), /* confirm */
         _("Do you really want to spend %s on a new ship?"), buf )==0)
      return;

   /* player just got a new ship */
   if (player_newShip( ship, NULL, 0, 0 ) == NULL) {
      /* Player actually aborted naming process. */
      return;
   }
   player_modCredits( -targetprice ); /* ouch, paying is hard */

   /* Update shipyard. */
   shipyard_update(wid, NULL);

   /* Run hook. */
   hparam[0].type    = HOOK_PARAM_STRING;
   hparam[0].u.str   = ship->name;
   hparam[1].type    = HOOK_PARAM_SENTINEL;
   hooks_runParam( "ship_buy", hparam );
   if (land_takeoff)
      takeoff(1);
}

/**
 * @brief Makes sure it's valid to buy a ship.
 *    @param shipname Ship being bought.
 *    @param planet Where the player is shopping.
 */
int shipyard_canBuy( const char *shipname, Planet *planet )
{
   Ship* ship;
   ship = ship_get( shipname );
   int failure = 0;
   credits_t price;
   char buf[STRMAX_SHORT];

   price = ship_buyPrice(ship);

   /* Must have enough credits and the necessary license. */
   if (!player_hasLicense(ship->license)
         && ((planet == NULL)
            || !planet_hasService(planet, PLANET_SERVICE_BLACKMARKET))) {
      land_errDialogueBuild(_("License needed: %s."), _(ship->license));
      failure = 1;
   }
   if (!player_hasCredits(price)) {
      credits2str(buf, sizeof(buf), price - player.p->credits, 2);
      land_errDialogueBuild( _("You need %s more."), buf);
      failure = 1;
   }
   return !failure;
}

/**
 * @brief Makes sure it's valid to sell a ship.
 *    @param shipname Ship being sold.
 */
int can_sell( const char *shipname )
{
   int failure = 0;
   if (strcmp( shipname, player.p->name )==0) { /* Already on-board. */
      land_errDialogueBuild( _("You can't sell the ship you're piloting!") );
      failure = 1;
   }

   return !failure;
}

/**
 * @brief Makes sure it's valid to change ships.
 *    @param shipname Ship being changed to.
 */
int can_swap( const char *shipname )
{
   int failure = 0;
   Ship* ship;
   ship = ship_get( shipname );
   double diff;

   if (pilot_cargoUsed(player.p) > ship->cap_cargo) { /* Current ship has too much cargo. */
      diff = pilot_cargoUsed(player.p) - ship->cap_cargo;
      land_errDialogueBuild( n_(
               "You have %G t more cargo than the new ship can hold.",
               "You have %G t more cargo than the new ship can hold.",
               diff ),
            diff );
      failure = 1;
   }
   return !failure;
}


/**
 * @brief Makes sure it's valid to buy a ship, trading the old one in simultaneously.
 *    @param shipname Ship being bought.
 */
int shipyard_canTrade( const char *shipname )
{
   int failure = 0;
   Ship* ship;
   ship = ship_get( shipname );
   credits_t price;
   credits_t creditdifference;
   char buf[STRMAX_SHORT];

   price = ship_buyPrice( ship );

   /* Must have the necessary license, enough credits, and be able to swap ships. */
   if ((!player_hasLicense(ship->license)) &&
         ((land_planet == NULL) || (!planet_hasService( land_planet, PLANET_SERVICE_BLACKMARKET )))) {
      land_errDialogueBuild( _("You lack the %s."), _(ship->license) );
      failure = 1;
   }
   if (!player_hasCredits( price - player_shipPrice(player.p->name))) {
      creditdifference = price - (player_shipPrice(player.p->name)+player.p->credits);
      credits2str(buf, sizeof(buf), creditdifference, 2);
      land_errDialogueBuild( _("You need %s more."), buf);
      failure = 1;
   }
   if (!can_swap(shipname))
      failure = 1;
   return !failure;
}


/**
 * @brief Player attempts to buy a ship, trading the current ship in.
 *    @param wid Window player is buying ship from.
 *    @param str Unused.
 */
static void shipyard_trade( unsigned int wid, char* str )
{
   (void)str;
   int i;
   char buf_oldprice[STRMAX_SHORT];
   char buf_exchange[STRMAX_SHORT];
   Ship* ship;

   i = toolkit_getImageArrayPos( wid, "iarShipyard" );
   if (i < 0 || shipyard_list == NULL)
      return;

   ship = shipyard_list[i];

   credits_t targetprice = ship_buyPrice(ship);
   credits_t playerprice = player_shipPrice(player.p->name);

   if (land_errDialogue( ship->name, "tradeShip" ))
      return;

   credits2str(buf_oldprice, sizeof(buf_oldprice), playerprice, 2);

   /* Display the correct dialogue depending on the new ship's price versus the player's. */
   if ( targetprice == playerprice ) {
      if (!dialogue_YesNo(_("Trade-In Confirmation"),
            _("Your %s is worth %s, exactly as much as the new ship, so no"
               " credits need be exchanged. Are you sure you want to trade"
               " your ship in?"),
            _(player.p->ship->name), buf_oldprice))
         return;
   }
   else if ( targetprice < playerprice ) {
      credits2str(buf_exchange, sizeof(buf_exchange),
            playerprice - targetprice, 2);
      if (!dialogue_YesNo(_("Trade-In Confirmation"),
            _("Your %s is worth %s, more than the new ship. For your ship, you"
               " will get the new %s and %s. Are you sure you want to trade"
               " your ship in?"),
            _(player.p->ship->name), buf_oldprice, _(ship->name),
            buf_exchange))
         return;
   }
   else if ( targetprice > playerprice ) {
      credits2str(buf_exchange, sizeof(buf_exchange),
            targetprice - playerprice, 2);
      if (!dialogue_YesNo(_("Trade-In Confirmation"),
            _("Your %s is worth %s, so the new ship will cost %s. Are you sure"
               " you want to trade your ship in?"),
            _(player.p->ship->name), buf_oldprice, buf_exchange))
         return;
   }

   /* player just got a new ship */
   if (player_newShip( ship, NULL, 1, 0 ) == NULL)
      return; /* Player aborted the naming process. */

   player_modCredits( playerprice - targetprice ); /* Modify credits by the difference between ship values. */

   land_refuel();

   /* The newShip call will trigger a loadGUI that will recreate the land windows. Therefore the land ID will
    * be void. We must reload in in order to properly update it again.*/
   wid = land_getWid(LAND_WINDOW_SHIPYARD);

   /* Update shipyard. */
   shipyard_update(wid, NULL);
}


/**
 * @brief Custom widget render function for the slot widget.
 */
static void shipyard_renderSlots( double bx, double by, double bw, double bh, void *data )
{
   (void) data;
   double x, y, w;
   Ship *ship;

   /* Make sure a valid ship is selected. */
   ship = shipyard_selected;
   if (ship == NULL)
      return;

   y = by + bh - 15;

   /* Draw rotated text. */
   gl_print( &gl_defFont, bx, y, &cFontWhite, _("Slots:") );

   x = bx + 10.;
   w = bw - 10.;

   /* Weapon slots. */
   y -= 20;
   shipyard_renderSlotsRow(x, y, w, OUTFIT_LABEL_WEAPON, ship->outfit_weapon);

   /* Utility slots. */
   y -= 20;
   shipyard_renderSlotsRow(x, y, w, OUTFIT_LABEL_UTILITY, ship->outfit_utility);

   /* Structure slots. */
   y -= 20;
   shipyard_renderSlotsRow(x, y, w, OUTFIT_LABEL_STRUCTURE,
         ship->outfit_structure);
}


/**
 * @brief Renders a row of ship slots.
 */
static void shipyard_renderSlotsRow(double bx, double by, double bw,
      const char *str, ShipOutfitSlot *s)
{
   (void) bw;
   int i;
   double x;
   const glColour *c;

   x = bx;

   /* Print text. */
   gl_printMidRaw(&gl_smallFont, 30, bx-15, by-2, &cFontWhite, -1, str);

   /* Draw squares. */
   for (i=0; i<array_size(s); i++) {
      c = outfit_slotSizeColour(&s[i].slot);
      if (c == NULL)
         c = &cBlack;

      x += 17.;
      toolkit_drawRect(x, by, 10, 10, c, NULL);

      /* Draw outer color. */
      if (s[i].required)
         toolkit_drawOutlineThick(x, by, 10, 10, 1, 2, &cSlotRequired, NULL);
      else if (s[i].slot.exclusive)
         toolkit_drawOutlineThick(x, by, 10, 10, 1, 2,
               &cSlotExclusive, &cSlotExclusiveLight);
      else if (s[i].slot.spid != 0)
         toolkit_drawOutlineThick(x, by, 10, 10, 1, 2,
               &cSlotTypedLight, &cSlotTyped);
      else
         toolkit_drawOutlineThick(x, by, 10, 10, 1, 2, c, NULL);

      toolkit_drawOutlineThick(x, by, 10, 10, 2, 1, &cBlack, NULL);
   }
}


/**
 * @brief Renders the slots overlay.
 *
 *    @param bx Base X position of the widget.
 *    @param by Base Y position of the widget.
 *    @param bw Width of the widget.
 *    @param bh Height of the widget.
 *    @param data Custom widget data.
 */
static void shipyard_renderOverlaySlots(double bx, double by,
      double bw, double bh, void *data)
{
   (void) bw;
   (void) bh;
   (void) data;
   ShipOutfitSlot *slot;
   const Outfit *o;
   char slot_alt[STRMAX];
   char outfit_alt[STRMAX];
   char *alt;
   size_t l;

   if (shipyard_mouseover == NULL)
      return;

   slot = shipyard_mouseover;
   o = slot->data;

   if (slot->slot.spid)
      l = scnprintf(slot_alt, sizeof(slot_alt), _("%s slot (%s)"),
            _(sp_display(slot->slot.spid)),
            slotSize(slot->slot.size));
   else {
      l = scnprintf(slot_alt, sizeof(slot_alt), _("%s slot (%s)"),
            _(slotName(slot->slot.type)),
            _(slotSize(slot->slot.size)));
   }
   if (slot->slot.exclusive && (l < (int)sizeof(slot_alt)))
      l += scnprintf(&slot_alt[l], sizeof(slot_alt) - l,
            _(" #y[Exclusive]#0"));

   /* Slot is empty. */
   if ((o == NULL) || (o->desc_short == NULL)) {
      if (slot->slot.spid)
         scnprintf(&slot_alt[l], sizeof(slot_alt) - l,
               "\n\n%s", _(sp_description(slot->slot.spid)));
      toolkit_drawAltText(bx + shipyard_altx, by + shipyard_alty, slot_alt);
      return;
   }

   /* Get text. */
   outfit_altText(outfit_alt, sizeof(outfit_alt), o);

   asprintf(&alt, _("#n%s\n\n#nEquipped outfit:#0\n%s"),
         slot_alt, outfit_alt);

   /* Draw the text. */
   toolkit_drawAltText(bx + shipyard_altx, by + shipyard_alty, alt);
   free(alt);
}


/**
 * @brief Does mouse input for the custom slots widget.
 *
 *    @param wid Parent window id.
 *    @param event Mouse input event.
 *    @param mx Mouse X event position.
 *    @param my Mouse Y event position.
 *    @param bw Base window width.
 *    @param bh Base window height.
 *    @param rx Relative X movement (only valid for motion).
 *    @param ry Relative Y movement (only valid for motion).
 *    @param data Custom widget data.
 */
static int shipyard_mouseSlots(unsigned int wid, SDL_Event* event,
      double mx, double my, double bw, double bh,
      double rx, double ry, void *data)
{
   (void) wid;
   (void) bh;
   (void) rx;
   (void) ry;
   (void) data;
   Ship *ship;
   double x, y, w;

   /* Make sure a valid ship is selected. */
   ship = shipyard_selected;
   if (ship == NULL)
      return 0;

   if (event->type != SDL_MOUSEMOTION)
      return 0;

   shipyard_mouseover = NULL;

   x = 10.;
   y = bh - 15.;
   w = bw - 10.;

   /* Weapon slots. */
   y -= 20;
   shipyard_mouseSlotsRow(x, y, w, mx, my, ship->outfit_weapon);

   /* Utility slots. */
   y -= 20;
   shipyard_mouseSlotsRow(x, y, w, mx, my, ship->outfit_utility);

   /* Structure slots. */
   y -= 20;
   shipyard_mouseSlotsRow(x, y, w, mx, my, ship->outfit_structure);

   return 0;
}


static void shipyard_mouseSlotsRow(double bx, double by, double bw,
      double mx, double my, ShipOutfitSlot *s)
{
   (void) bw;
   int i;
   double x;

   if (shipyard_mouseover != NULL)
      return;

   x = bx;

   /* Draw squares. */
   for (i=0; i<array_size(s); i++) {
      x += 17.;
      if ((mx > x - 2) && (mx < x + 12) && (my > by - 2) && (my < by + 12)) {
         shipyard_mouseover = &s[i];
         shipyard_altx = mx;
         shipyard_alty = my;
         return;
      }
   }
}
