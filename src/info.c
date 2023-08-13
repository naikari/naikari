/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file info.h
 *
 * @brief Handles the info menu.
 */


/** @cond */
#include "naev.h"
/** @endcond */

#include "info.h"

#include "array.h"
#include "dialogue.h"
#include "equipment.h"
#include "gui.h"
#include "gui_osd.h"
#include "land.h"
#include "log.h"
#include "map.h"
#include "menu.h"
#include "mission.h"
#include "nstring.h"
#include "ntime.h"
#include "pilot.h"
#include "player.h"
#include "player_gui.h"
#include "shiplog.h"
#include "space.h"
#include "tk/toolkit_priv.h"
#include "toolkit.h"

#define BUTTON_WIDTH    180 /**< Button width, standard across menus. */
#define BUTTON_HEIGHT   30 /**< Button height, standard across menus. */

#define SETGUI_WIDTH    400 /**< GUI selection window width. */
#define SETGUI_HEIGHT   300 /**< GUI selection window height. */

#define menu_Open(f)    (menu_open |= (f)) /**< Marks a menu as opened. */
#define menu_Close(f)   (menu_open &= ~(f)) /**< Marks a menu as closed. */

#define INFO_WINDOWS      7 /**< Amount of windows in the tab. */

#define INFO_WIN_MAIN      0
#define INFO_WIN_SHIP      1
#define INFO_WIN_WEAP      2
#define INFO_WIN_CARGO     3
#define INFO_WIN_MISN      4
#define INFO_WIN_STAND     5
#define INFO_WIN_SHIPLOG   6
static const char *info_names[INFO_WINDOWS] = {
   N_("Overview"),
   N_("Ship"),
   N_("Weapons"),
   N_("Cargo"),
   N_("Missions"),
   N_("Standings"),
   N_("Ship log"),
}; /**< Name of the tab windows. */


static unsigned int info_wid = 0;
static unsigned int *info_windows = NULL;

static CstSlotWidget info_eq_weaps;
static factionId_t *info_factions;

static int map_clicked = 0; /**< Whether the map was just clicked. */

static int selectedLog = 0;
static int nlogs = 0;
static char **logs = NULL;
static int *logIDs = NULL;
static int logWidgetsReady = 0;

/*
 * prototypes
 */
/* information menu */
static void info_close( unsigned int wid, char* str );
static void info_openMain( unsigned int wid );
static void info_setGui( unsigned int wid, char* str );
static void setgui_load( unsigned int wdw, char *str );
static void info_toggleGuiOverride( unsigned int wid, char *name );
static void info_openShip( unsigned int wid );
static void info_openWeapons( unsigned int wid );
static void info_openCargo( unsigned int wid );
static void info_openMissions( unsigned int wid );
static void info_getDim( unsigned int wid, int *w, int *h, int *lw );
static void standings_close( unsigned int wid, char *str );
static void ship_update( unsigned int wid );
static void weapons_genList( unsigned int wid );
static void weapons_update( unsigned int wid, char *str );
static void weapons_autoweap( unsigned int wid, char *str );
static void weapons_fire( unsigned int wid, char *str );
static void weapons_inrange( unsigned int wid, char *str );
static void aim_lines( unsigned int wid, char *str );
static void weapons_renderLegend( double bx, double by, double bw, double bh, void* data );
static void info_openStandings( unsigned int wid );
static void info_shiplogView( unsigned int wid, char *str );
static void standings_update( unsigned int wid, char* str );
static void cargo_genList( unsigned int wid );
static void cargo_update( unsigned int wid, char* str );
static void cargo_jettison( unsigned int wid, char* str );
static void mission_menu_abort( unsigned int wid, char* str );
static void mission_menu_genList( unsigned int wid, int first );
static void mission_menu_update( unsigned int wid, char* str );
static void info_openShipLog( unsigned int wid );


/**
 * @brief Opens the information menu.
 */
void menu_info( int window )
{
   int w, h;
   size_t i;
   const char *names[INFO_WINDOWS];

   /* Open closes when previously opened. */
   if (menu_isOpen(MENU_INFO) || dialogue_isOpen()) {
      if ((info_wid > 0) && !window_isTop(info_wid))
         return;
      info_close( 0, NULL );
      return;
   }

   /* Close map if open, since we need it to be reset for the Missions
    * tab. */
   map_close();

   /* Dimensions. */
   w = 920;
   h = 600;

   /* Create the window. */
   info_wid = window_create("wdwInfo", _("Ship Computer"), -1, -1, w, h);
   window_setCancel( info_wid, info_close );

   /* Create tabbed window. */
   for (i=0; i<INFO_WINDOWS; i++)
      names[i] = _(info_names[i]);
   info_windows = window_addTabbedWindow( info_wid, -1, -1, -1, -1, "tabInfo",
         INFO_WINDOWS, names, 0 );

   /* Open the subwindows. */
   info_openMain(info_windows[INFO_WIN_MAIN]);
   info_openShip(info_windows[INFO_WIN_SHIP]);
   info_openWeapons(info_windows[INFO_WIN_WEAP]);
   info_openCargo(info_windows[INFO_WIN_CARGO]);
   info_openMissions(info_windows[INFO_WIN_MISN]);
   info_openStandings(info_windows[INFO_WIN_STAND]);
   info_openShipLog(info_windows[INFO_WIN_SHIPLOG]);

   menu_Open(MENU_INFO);

   /* Set active window. */
   window_tabWinSetActive( info_wid, "tabInfo", CLAMP( 0, 6, window ) );

   /* Update the window. */
   info_update();
}
/**
 * @brief Closes the information menu.
 *    @param str Unused.
 */
static void info_close( unsigned int wid, char* str )
{
   (void) wid;
   if (info_wid > 0) {
      window_close( info_wid, str );
      info_wid = 0;
      info_windows = NULL;
      logs = NULL;
      menu_Close(MENU_INFO);

      /* Give the land window a chance to update. */
      land_updateTabs();
   }
}


/**
 * @brief Updates the info windows.
 */
void info_update (void)
{
   /* Info window must be open. */
   if (info_windows == NULL)
      return;

   weapons_genList(info_windows[INFO_WIN_WEAP]);

   mission_menu_genList(info_windows[INFO_WIN_MISN], 0);
   mission_menu_update(info_windows[INFO_WIN_MISN], NULL);
}


/**
 * @brief Responds to a system being targeted.
 */
void info_mapTargetSystem(void)
{
   map_clicked = 1;
   info_update();
   map_clicked = 0;
}


/**
 * @brief Opens the main info window.
 */
static void info_openMain( unsigned int wid )
{
   char str[STRMAX_SHORT], **buf, creds[ECON_CRED_STRLEN];
   char str2[STRMAX_SHORT];
   char buf_worth[ECON_CRED_STRLEN];
   credits_t networth;
   const PlayerShip_t *ships;
   const PlayerOutfit_t *outfits;
   char **licenses;
   int jumps;
   int nlicenses;
   int i;
   char *nt;
   int w, h;
   time_t t = time(NULL);

   jumps = pilot_getJumps(player.p);
   if (jumps != -1)
      snprintf(str2, sizeof(str2), n_("%d jump", "%d jumps", jumps), jumps);
   else
      strcpy(str2, _("∞ jumps"));

   /* Compute elapsed time. */
   player.time_played += difftime(t, player.time_since_save);
   player.time_since_save = t;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* Calculate net worth. */
   networth = player.p->credits + player_shipPrice(player.p->name);
   ships = player_getShipStack();
   outfits = player_getOutfits();
   for (i=0; i<array_size(ships); i++) {
      networth += player_shipPrice(ships[i].p->name);
   }
   for (i=0; i<array_size(outfits); i++) {
      networth += outfits[i].o->price * outfits[i].q;
   }

   /* pilot generics */
   nt = ntime_pretty(ntime_get(), 2);
   credits2str(creds, player.p->credits, 2);
   credits2str(buf_worth, networth, 2);
   snprintf(str, sizeof(str),
         _("#nPilot:#0 %s\n"
         "#nDate:#0 %s\n"
         "\n"
         "#nMoney:#0 %s\n"
         "#nShip:#0 %s\n"
         "#nFuel:#0 %.0f (%s)\n"
         "\n"
         "#nTime played (D:HH:MM):#0 %lld:%02lld:%02lld\n"
         "#nNet Worth:#0 %s\n"
         "#nDamage done:#0 %.0f GJ\n"
         "#nDamage taken:#0 %.0f GJ\n"
         "#nShips destroyed:#0 %u"),
         player.name,
         nt,
         creds,
         player.p->name,
         player.p->fuel, str2,
         (long long)player.time_played / 86400,
         ((long long)player.time_played%86400) / 3600,
         ((long long)player.time_played%3600) / 60,
         buf_worth,
         player.dmg_done_shield + player.dmg_done_armour,
         player.dmg_taken_shield + player.dmg_taken_armour,
         player.ships_destroyed );
   window_addText( wid, 40, 20,
         w-40-20-2*BUTTON_WIDTH-20-20, h-80,
         0, "txtPilot", &gl_defFont, NULL, str);
   free(nt);

   /* menu */
   window_addButton( wid, -20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnClose", _("Close"), info_close );
   window_addButton( wid, -20 - (20+BUTTON_WIDTH), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnSetGUI", _("Set GUI"), info_setGui );

   buf = player_getLicenses();
   nlicenses = array_size( buf );
   /* List. */
   if (nlicenses == 0) {
     licenses = malloc(sizeof(char*));
     licenses[0] = strdup(_("None"));
   } else {
     licenses = malloc(sizeof(char*) * nlicenses);
     for (i=0; i<nlicenses; i++)
        licenses[i] = strdup( _(buf[i]) );
      qsort( licenses, nlicenses, sizeof(char*), strsort );
   }
   window_addText( wid, -20, -40, 2*BUTTON_WIDTH+20, 20, 1, "txtList",
         NULL, NULL, _("Licenses") );
   window_addList( wid, -20, -70, 2*BUTTON_WIDTH+20, h-110-BUTTON_HEIGHT,
         "lstLicenses", licenses, MAX(nlicenses, 1), 0, NULL, NULL );
}


/**
 * @brief Closes the GUI selection menu.
 *
 *    @param wdw Window triggering function.
 *    @param str Unused.
 */
static void setgui_close( unsigned int wdw, char *str )
{
   (void) str;

   window_destroy(wdw);

   /* Load the GUI. */
   gui_load(gui_pick());
}


/**
 * @brief Allows the player to set a different GUI.
 *
 *    @param wid Window id.
 *    @param name of widget.
 */
static void info_setGui( unsigned int wid, char* str )
{
   (void)str;
   int i;
   char **guis;
   int nguis;
   char **gui_copy;

   /* Get the available GUIs. */
   guis = player_guiList();
   nguis = array_size( guis );

   /* In case there are none. */
   if (guis == NULL) {
      WARN(_("No GUI available."));
      dialogue_alert(
         _("There are no GUI available, this means something went wrong"
            " somewhere. Inform the Naikari maintainer.") );
      return;
   }

   /* window */
   wid = window_create( "wdwSetGUI", _("Select GUI"), -1, -1, SETGUI_WIDTH, SETGUI_HEIGHT );
   window_setCancel( wid, setgui_close );

   /* Copy GUI. */
   gui_copy = malloc( sizeof(char*) * nguis );
   for (i=0; i<nguis; i++)
      gui_copy[i] = strdup( guis[i] );

   /* List */
   window_addList( wid, 20, -50,
         SETGUI_WIDTH-BUTTON_WIDTH/2 - 60, SETGUI_HEIGHT-110,
         "lstGUI", gui_copy, nguis, 0, NULL, NULL );
   toolkit_setList( wid, "lstGUI", gui_pick() );

   /* buttons */
   window_addButton( wid, -20, 20, BUTTON_WIDTH/2, BUTTON_HEIGHT,
         "btnBack", _("Close"), setgui_close );
   window_addButton( wid, -20, 30 + BUTTON_HEIGHT, BUTTON_WIDTH/2, BUTTON_HEIGHT,
         "btnLoad", _("Load"), setgui_load );

   /* Checkboxes */
   window_addCheckbox( wid, 20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT, "chkOverride", _("Override GUI"),
         info_toggleGuiOverride, player.guiOverride );
   info_toggleGuiOverride( wid, "chkOverride" );

   /* default action */
   window_setAccept( wid, setgui_load );
}


/**
 * @brief Loads a GUI.
 *
 *    @param wdw Window triggering function.
 *    @param str Unused.
 */
static void setgui_load( unsigned int wdw, char *str )
{
   (void)str;
   char *gui;
   int wid;

   wid = window_get( "wdwSetGUI" );
   gui = toolkit_getList( wid, "lstGUI" );
   if (strcmp(gui,_("None")) == 0)
      return;

   if (player.guiOverride == 0) {
      if (dialogue_YesNo( _("GUI Override is not set."),
               _("Enable GUI Override and change GUI to '%s'?"), gui )) {
         player.guiOverride = 1;
         window_checkboxSet( wid, "chkOverride", player.guiOverride );
      }
      else {
         return;
      }
   }

   /* Set the GUI. */
   free( player.gui );
   player.gui = strdup( gui );

   /* Close menus before loading for proper rendering. */
   setgui_close(wdw, NULL);
}


/**
 * @brief GUI override was toggled.
 *
 *    @param wid Window id.
 *    @param name of widget.
 */
static void info_toggleGuiOverride( unsigned int wid, char *name )
{
   player.guiOverride = window_checkboxState(wid, name);
   /* Go back to the default one. */
   if (player.guiOverride == 0)
      toolkit_setList(wid, "lstGUI", gui_pick());
}


/**
 * @brief Shows the player what outfits he has.
 *
 *    @param str Unused.
 */
static void info_openShip( unsigned int wid )
{
   int w, h;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* Buttons */
   window_addButton( wid, -20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "closeOutfits", _("Close"), info_close );

   /* Text. */
   window_addText( wid, 40, -40, w*2/3 - 40 - 10, h-40, 0,
         "txtDDesc", &gl_defFont, NULL, NULL );

   /* Stats. */
   window_addText( wid, w*2/3 + 10, -40, w*2/3 - 10 - 40,
         h-40-BUTTON_HEIGHT-20, 0, "txtStats", &gl_defFont, NULL, NULL );

   /* Update ship. */
   ship_update( wid );
}


/**
 * @brief Updates the ship stuff.
 */
static void ship_update( unsigned int wid )
{
   char *hyp_delay, *land_delay;
   char buf[STRMAX], buf2[STRMAX_SHORT];
   char buf_price[ECON_CRED_STRLEN];
   int cargo;
   int jumps;

   cargo = pilot_cargoUsed(player.p) + pilot_cargoFree(player.p);
   hyp_delay = ntime_pretty(pilot_hyperspaceDelay(player.p), 1);
   land_delay = ntime_pretty(
      ntime_create(0, 0, (int)(NT_DAY_SECONDS * player.p->stats.land_delay)),
      1);

   jumps = pilot_getJumps(player.p);
   if (jumps != -1)
      snprintf(buf2, sizeof(buf2), n_("%d jump", "%d jumps", jumps), jumps);
   else
      strcpy(buf2, _("∞ jumps"));
   credits2str(buf_price, player_shipPrice(player.p->name), 2);

   snprintf(buf, sizeof(buf),
         _("#nName:#0 %s\n"
         "#nModel:#0 %s (%s class)\n"
         "#nValue:#0 %s\n"
         "\n"
         "#nMass:#0 %.0f kt\n"
         "#nMass Limit Left:#0 %.0f / %.0f kt\n"
         "#nSpeed Penalty:#0 %.0f%%\n"
         "#nJump Time:#0 %s\n"
         "#nTakeoff Time:#0 %s\n"
         "#nAcceleration:#0 %.0f mAU/s²\n"
         "#nSpeed:#0 %.0f mAU/s (max %.0f mAU/s)\n"
         "#nTurn:#0 %.0f deg/s\n"
         "#nTime Constant:#0 %.0f%%\n"
         "\n"
         "#nAbsorption:#0 %.0f%%\n"
         "#nShield:#0 %.0f / %.0f GJ; #nRegeneration:#0 %.1f GW\n"
         "#nArmor:#0 %.0f / %.0f GJ; #nRegeneration:#0 %.1f GW\n"
         "#nEnergy:#0 %.0f / %.0f GJ; #nRegeneration:#0 %.1f GW\n"
         "#nCargo:#0 %d / %d kt\n"
         "#nFuel:#0 %.0f / %.0f kL (%s); #nRegeneration:#0 %.2f kL/s\n"
         "#nRadar Range:#0 %.0f mAU\n"
         "#nJump Detect Range:#0 %.0f mAU\n"
         "\n"),
         /* Generic */
         player.p->name,
         _(player.p->ship->name),
         _(player.p->ship->class),
         buf_price,
         /* Movement. */
         player.p->solid->mass,
         player.p->stats.engine_limit - player.p->solid->mass,
         player.p->stats.engine_limit,
         (1. - player.p->speed/player.p->speed_base) * 100.,
         hyp_delay,
         land_delay,
         player.p->thrust / player.p->solid->mass,
         player.p->speed, solid_maxspeed( player.p->solid, player.p->speed, player.p->thrust ),
         player.p->turn*180./M_PI,
         player.p->stats.time_mod * player.p->ship->dt_default * 100.,
         /* Health. */
         player.p->dmg_absorb * 100.,
         player.p->shield, player.p->shield_max, player.p->shield_regen,
         player.p->armour, player.p->armour_max, player.p->armour_regen,
         player.p->energy, player.p->energy_max, player.p->energy_regen,
         pilot_cargoUsed( player.p ), cargo,
         player.p->fuel, player.p->fuel_max, buf2, player.p->fuel_regen,
         player.p->rdr_range, player.p->rdr_jump_range);
   window_modifyText(wid, "txtDDesc", buf);

   equipment_shipStats(buf, sizeof(buf), player.p, 1);
   window_modifyText(wid, "txtStats", buf);

   free(hyp_delay);
   free(land_delay);
}


/**
 * @brief Opens the weapons window.
 */
static void info_openWeapons( unsigned int wid )
{
   int w, h, y, wlen;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* Custom widget. */
   equipment_slotWidget( wid, 20, -40, 180, h-60, &info_eq_weaps );
   info_eq_weaps.selected  = player.p;
   info_eq_weaps.weapons = 0;
   info_eq_weaps.canmodify = 0;

   /* Custom widget for legend. */
   y = -240;
   window_addCust( wid, 220, y, w-200-60, 100, "cstLegend", 0,
         weapons_renderLegend, NULL, NULL );

   /* Checkboxes. */
   wlen = w - 220 - 20;
   y -= 100;
   window_addText( wid, 220, y, wlen, 20, 0, "txtLocal", NULL, NULL,
         _("Current Set Settings"));
   y -= 30;
   window_addCheckbox(wid, 220, y, wlen, 20, "chkFire",
         _("Instantly fire with weapon set key (only for weapons)"),
         weapons_fire,
         (pilot_weapSetTypeCheck(player.p, info_eq_weaps.weapons)
            == WEAPSET_TYPE_WEAPON));
   y -= 25;
   window_addCheckbox( wid, 220, y, wlen, 20,
         "chkInrange", _("Only shoot weapons that are in range"), weapons_inrange,
         pilot_weapSetInrangeCheck( player.p, info_eq_weaps.weapons ) );
   y -= 40;
   window_addText( wid, 220, y, wlen, 20, 0, "txtGlobal", NULL, NULL,
         _("Global Settings"));
   y -= 30;
   window_addCheckbox( wid, 220, y, wlen, 20,
         "chkAutoweap", _("Automatically handle weapons"), weapons_autoweap, player.p->autoweap );
   y -= 25;
   window_addCheckbox( wid, 220, y, wlen, 20,
         "chkHelper", _("Aiming helper"), aim_lines, player.p->aimLines );

   /* List. Has to be generated after checkboxes. */
   weapons_genList( wid );

   /* Buttons */
   window_addButton( wid, -20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "closeCargo", _("Close"), info_close );
}


/**
 * @brief Generates the weapons list.
 */
static void weapons_genList( unsigned int wid )
{
   const char *str;
   char **buf, tbuf[STRMAX_SHORT];
   int i, n;
   int w, h;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* Destroy widget if needed. */
   if (widget_exists( wid, "lstWeapSets" )) {
      window_destroyWidget( wid, "lstWeapSets" );
      n = toolkit_getListPos( wid, "lstWeapSets" );
   }
   else
      n = -1;

   /* List */
   buf = malloc( sizeof(char*) * PLAYER_WEAPON_SETS );
   for (i=0; i<PLAYER_WEAPON_SETS; i++) {
      str = pilot_weapSetName( info_eq_weaps.selected, i );
      if (str == NULL)
         snprintf( tbuf, sizeof(tbuf), "%d - ??", (i+1)%10 );
      else
         snprintf( tbuf, sizeof(tbuf), "%d - %s", (i+1)%10, str );
      buf[i] = strdup( tbuf );
   }
   window_addList( wid, 20+180+20, -40,
         w - (20+180+20+20), 200,
         "lstWeapSets", buf, PLAYER_WEAPON_SETS,
         0, weapons_update, NULL );

   /* Restore position. */
   if (n >= 0)
      toolkit_setListPos( wid, "lstWeapSets", n );
}


/**
 * @brief Updates the weapon sets.
 */
static void weapons_update( unsigned int wid, char *str )
{
   (void) str;
   int pos;

   /* Update the position. */
   pos = toolkit_getListPos( wid, "lstWeapSets" );
   if (pos < 0)
      return;
   info_eq_weaps.weapons = pos;

   /* Update fire mode. */
   window_checkboxSet(wid, "chkFire",
         (pilot_weapSetTypeCheck(player.p, pos) == WEAPSET_TYPE_WEAPON));

   /* Update inrange. */
   window_checkboxSet( wid, "chkInrange",
         pilot_weapSetInrangeCheck( player.p, pos ) );

   /* Update autoweap. */
   window_checkboxSet( wid, "chkAutoweap", player.p->autoweap );
}


/**
 * @brief Toggles autoweap for the ship.
 */
static void weapons_autoweap( unsigned int wid, char *str )
{
   int state, sure;

   /* Set state. */
   state = window_checkboxState( wid, str );

   /* Run autoweapons if needed. */
   if (state) {
      sure = dialogue_YesNoRaw( _("Enable autoweapons?"),
            _("Are you sure you want to enable automatic weapon groups for the "
            "ship?\n\nThis will overwrite all manually-tweaked weapons groups.") );
      if (!sure) {
         window_checkboxSet( wid, str, 0 );
         return;
      }
      player.p->autoweap = 1;
      pilot_weaponAuto( player.p );
      weapons_genList( wid );
      gui_setShip();
   }
   else
      player.p->autoweap = 0;
}


/**
 * @brief Sets the fire mode.
 */
static void weapons_fire( unsigned int wid, char *str )
{
   int state, t, c;
   int *levels;
   int change_exists;
   int i, j;

   /* Set state. */
   state = window_checkboxState( wid, str );

   /* See how to handle. */
   t = pilot_weapSetTypeCheck( player.p, info_eq_weaps.weapons );
   if (t == WEAPSET_TYPE_ACTIVE) {
      window_checkboxSet(wid, "chkFire", 0);
      dialogue_alert(
         _("Instant mode is unavailable for activated outfit weapon sets."));
      return;
   }

   /* Store primary/secondary settings in case we have to revert. */
   levels = array_create_size(int, array_size(player.p->outfit_weapon));
   for (i=0; i<array_size(player.p->outfit_weapon); i++) {
      array_push_back(&levels,
            pilot_weapSetCheck(player.p, info_eq_weaps.weapons,
               &player.p->outfit_weapon[i]));
   }

   if (state)
      c = WEAPSET_TYPE_WEAPON;
   else
      c = WEAPSET_TYPE_CHANGE;
   pilot_weapSetType(player.p, info_eq_weaps.weapons, c);

   /* Check to see if any change groups exist and have weapons. */
   change_exists = 0;
   for (i=0; i<PLAYER_WEAPON_SETS; i++) {
      if (pilot_weapSetTypeCheck(player.p, i) == WEAPSET_TYPE_CHANGE) {
         for (j=0; j<array_size(player.p->outfit_weapon); j++) {
            if (pilot_weapSetCheck(player.p, i, &player.p->outfit_weapon[j]) >= 0) {
               change_exists = 1;
               break;
            }
         }
      }
      if (change_exists)
         break;
   }

   /* Not able to set them all to fire groups. */
   if (!change_exists) {
      pilot_weapSetType(player.p, info_eq_weaps.weapons, WEAPSET_TYPE_CHANGE);

      /* Reset primary/secondary settings. */
      for (i=0; i<array_size(levels); i++) {
         if (levels[i] >= 0)
            pilot_weapSetAdd(player.p, info_eq_weaps.weapons,
               &player.p->outfit_weapon[i], levels[i]);
      }

      dialogue_alert(
         _("You cannot set all your weapon sets to instant fire."));
      window_checkboxSet(wid, str, 0);

      goto err;
   }

   /* Disable automatic handling of weapons */
   player.p->autoweap = 0;

   /* Notify GUI of modification. */
   gui_setShip();

err:

   array_free(levels);

   /* Set default if needs updating. */
   pilot_weaponSetDefault(player.p);

   /* Notify GUI of modification. */
   gui_setShip();

   /* Must regen. */
   weapons_genList(wid);
}


/**
 * @brief Sets the inrange property.
 */
static void weapons_inrange( unsigned int wid, char *str )
{
   int state;

   /* Set state. */
   state = window_checkboxState( wid, str );
   pilot_weapSetInrange( player.p, info_eq_weaps.weapons, state );
}


/**
 * @brief Sets the aim lines property.
 */
static void aim_lines( unsigned int wid, char *str )
{
   int state;

   /* Set state. */
   state = window_checkboxState( wid, str );
   player.p->aimLines = state;
}


/**
 * @brief Renders the legend.
 */
static void weapons_renderLegend( double bx, double by, double bw, double bh, void* data )
{
   (void) data;
   (void) bw;
   (void) bh;
   double x, y;

   x = bx+1;
   y = by+bh-20;
   gl_print( &gl_defFont, bx, y, &cFontWhite, _("Legend") );

   y -= 30.;
   toolkit_drawTriangle( x-1, y-2, x+12, y+5, x-1, y+12, &cGrey50 );
   toolkit_drawTriangle( x, y, x+10, y+5, x, y+10, &cWhite );
   gl_print(&gl_smallFont, x+20, y, &cFontWhite,
         _("Primary Weapon / Activated Outfit (Left-click slot to toggle)"));

   y -= 25.;
   toolkit_drawTriangle( x-1, y-2, x+12, y+5, x-1, y+12, &cGrey50 );
   toolkit_drawTriangle( x, y, x+10, y+5, x, y+10, &cBlack );
   gl_print(&gl_smallFont, x+20, y, &cFontWhite,
         _("Secondary Weapon (Right-click slot to toggle)"));
}


/**
 * @brief Shows the player their cargo.
 *
 *    @param str Unused.
 */
static void info_openCargo( unsigned int wid )
{
   int w, h;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* Buttons */
   window_addButton( wid, -20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "closeCargo", _("Close"), info_close );
   window_addButton( wid, -40 - BUTTON_WIDTH, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT, "btnJettisonCargo", _("Jettison"),
         cargo_jettison );
   window_disableButton( wid, "btnJettisonCargo" );

   /* Description. */
   window_addText(wid, 20+350+20, -20,
         w - (20+350+20) - 20, 60, 1, "txtCargoName", NULL, NULL, NULL);
   window_addText(wid, 20+350+20, -20 - 60,
         w - (20+350+20) - 20, h - BUTTON_HEIGHT - 20 - 60, 0,
         "txtCargoDesc", &gl_smallFont, NULL, NULL );

   /* Generate the list. */
   cargo_genList( wid );
}
/**
 * @brief Generates the cargo list.
 */
static void cargo_genList( unsigned int wid )
{
   char **buf;
   int nbuf;
   int i;
   int w, h;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* Destroy widget if needed. */
   if (widget_exists( wid, "lstCargo" ))
      window_destroyWidget( wid, "lstCargo" );

   /* List */
   if (array_size(player.p->commodities)==0) {
      /* No cargo */
      buf = malloc(sizeof(char*));
      buf[0] = strdup(_("None"));
      nbuf = 1;
   }
   else {
      /* List the player's cargo */
      buf = malloc( sizeof(char*) * array_size(player.p->commodities) );
      for (i=0; i<array_size(player.p->commodities); i++) {
         asprintf(&buf[i], "%s%s (%d kt)",
               _(player.p->commodities[i].commodity->name),
               (player.p->commodities[i].id != 0) ? "*" : "",
               player.p->commodities[i].quantity);
      }
      nbuf = array_size(player.p->commodities);
   }
   window_addList( wid, 20, -40,
         350, h - BUTTON_HEIGHT - 80,
         "lstCargo", buf, nbuf, 0, cargo_update, NULL );
}
/**
 * @brief Updates the player's cargo in the cargo menu.
 *    @param str Unused.
 */
static void cargo_update( unsigned int wid, char* str )
{
   (void) str;
   char buf[STRMAX];
   int pos;
   const Commodity *com;

   /* Clear text fields */
   window_modifyText(wid, "txtCargoName", "");
   window_modifyText(wid, "txtCargoDesc", "");

   if (array_size(player.p->commodities) == 0) {
      window_disableButton(wid, "btnJettisonCargo");
      return; /* No cargo */
   }

   /* Don't allow jettisoning cargo if under manual control, since this
    * can abort a mission and aborting a mission can leave the player
    * stuck under said manual control. */
   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL))
      window_disableButtonSoft(wid, "btnJettisonCargo");
   else
      window_enableButton(wid, "btnJettisonCargo");

   if (array_size(player.p->commodities)==0)
      return; /* No cargo, redundant check */

   pos = toolkit_getListPos(wid, "lstCargo");
   com = player.p->commodities[pos].commodity;

   snprintf(buf, sizeof(buf), "%s%s (%d kt)", _(com->name),
         (player.p->commodities[pos].id != 0) ? "*" : "",
         player.p->commodities[pos].quantity);
   window_modifyText(wid, "txtCargoName", buf);

   if (com->description)
      window_modifyText(wid, "txtCargoDesc", _(com->description));
}
/**
 * @brief Makes the player jettison the currently selected cargo.
 *    @param str Unused.
 */
static void cargo_jettison( unsigned int wid, char* str )
{
   (void)str;
   int i, j, f, pos, ret;
   Mission *misn;

   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL)) {
      dialogue_alert(_("You cannot jettison cargo right now as your ship is"
            " being controlled by a mission or event."));
      return;
   }

   if (array_size(player.p->commodities)==0)
      return; /* No cargo, redundant check */

   pos = toolkit_getListPos( wid, "lstCargo" );

   /* Special case mission cargo. */
   if (player.p->commodities[pos].id != 0) {
      if (!dialogue_YesNo( _("Abort Mission"),
               _("Are you sure you want to abort this mission?") ))
         return;

      /* Get the mission. */
      f = 0;
      for (i=0; i<MISSION_MAX; i++) {
         for (j=0; j<array_size(player_missions[i]->cargo); j++) {
            if (player_missions[i]->cargo[j] == player.p->commodities[pos].id) {
               f = 1;
               break;
            }
         }
         if (f==1)
            break;
      }
      if (!f) {
         WARN(_("Cargo '%d' does not belong to any active mission."),
               player.p->commodities[pos].id);
         return;
      }
      misn = player_missions[i];

      /* We run the "abort" function if it's found. */
      ret = misn_tryRun( misn, "abort" );

      /* Now clean up mission. */
      if (ret != 2) {
         mission_cleanup( misn );
         mission_shift(pos);
      }

      /* Reset markers. */
      mission_sysMark();

      /* Reset claims. */
      claim_activateAll();

      /* Regenerate list. */
      mission_menu_genList( info_windows[ INFO_WIN_MISN ], 0 );
   }
   else {
      /* Remove the cargo */
      if (!landed)
         commodity_Jettison(player.p->id, player.p->commodities[pos].commodity,
               player.p->commodities[pos].quantity);
      pilot_cargoRm(player.p, player.p->commodities[pos].commodity,
            player.p->commodities[pos].quantity);
   }

   /* We reopen the menu to recreate the list now. */
   ship_update( info_windows[ INFO_WIN_SHIP ] );
   cargo_genList( wid );
}


/**
 * @brief Gets the window standings window dimensions.
 */
static void info_getDim( unsigned int wid, int *w, int *h, int *lw )
{
   /* Get the dimensions. */
   window_dimWindow( wid, w, h );
   *lw = *w-60-BUTTON_WIDTH-120;
}


/**
 * @brief Closes the faction stuff.
 */
static void standings_close( unsigned int wid, char *str )
{
   (void) wid;
   (void) str;
   array_free(info_factions);
   info_factions = NULL;
}


/**
 * @brief Displays the player's standings.
 */
static void info_openStandings( unsigned int wid )
{
   int i;
   int m;
   char **str;
   int w, h, lw;

   /* Get dimensions. */
   info_getDim( wid, &w, &h, &lw );

   /* On close. */
   window_onClose( wid, standings_close );

   /* Buttons */
   window_addButton( wid, -20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "closeMissions", _("Close"), info_close );

   /* Graphics. */
   window_addImage( wid, 0, 0, 0, 0, "imgLogo", NULL, 0 );

   /* Text. */
   window_addText( wid, lw+40, 0, (w-(lw+60)), 20, 1, "txtName",
         &gl_defFont, NULL, NULL );
   window_addText( wid, lw+40, 0, (w-(lw+60)), 20, 1, "txtStanding",
         &gl_smallFont, NULL, NULL );

   /* Gets the faction standings. */
   info_factions  = faction_getKnown();
   str            = malloc( sizeof(char*) * array_size(info_factions) );

   /* Create list. */
   for (i=0; i<array_size(info_factions); i++) {
      m = round( faction_getPlayer( info_factions[i] ) );
      asprintf( &str[i], "%s   [ %+d%% ]",
            _(faction_name( info_factions[i] )), m );
   }

   /* Display list. */
   window_addList( wid, 20, -40, lw, h-60, "lstStandings",
         str, array_size(info_factions), 0, standings_update, NULL );
}


/**
 * @brief Updates the standings menu.
 */
static void standings_update( unsigned int wid, char* str )
{
   (void) str;
   int p, y;
   glTexture *t;
   int w, h, lw;
   char buf[128];
   int m;

   /* Get dimensions. */
   info_getDim( wid, &w, &h, &lw );

   /* Get faction. */
   p = toolkit_getListPos( wid, "lstStandings" );

   /* Render logo. */
   t = faction_logoSmall( info_factions[p] );
   if (t != NULL) {
      window_modifyImage( wid, "imgLogo", t, 0, 0 );
      y  = -40;
      window_moveWidget( wid, "imgLogo", lw+40 + (w-(lw+60)-t->w)/2, y );
      y -= t->h;
   }
   else {
      window_modifyImage( wid, "imgLogo", NULL, 0, 0 );
      y = -20;
   }

   /* Modify text. */
   y -= 20;
   window_modifyText( wid, "txtName", faction_longname( info_factions[p] ) );
   window_moveWidget( wid, "txtName", lw+40, y );
   y -= 40;
   m = round( faction_getPlayer( info_factions[p] ) );
   snprintf( buf, sizeof(buf), "%+d%%   [ %s ]", m,
      faction_getStandingText( info_factions[p] ) );
   window_modifyText( wid, "txtStanding", buf );
   window_moveWidget( wid, "txtStanding", lw+40, y );
}


/**
 * @brief Shows the player's active missions.
 *
 *    @param parent Unused.
 *    @param str Unused.
 */
static void info_openMissions( unsigned int wid )
{
   int w, h;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* buttons */
   window_addButton( wid, -20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "closeMissions", _("Close"), info_close );
   window_addButtonKey(wid, -40 - BUTTON_WIDTH, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT, "btnAbortMission",
         _("&Abort"), mission_menu_abort, SDLK_a);

   /* If player is under manual control, we must prevent missions from
    * being aborted. Otherwise the player could prevent a mission which
    * is controlling them from executing the hook that would free
    * them. */
   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL))
      window_disableButton(wid, "btnAbortMission");

   /* text */
   window_addText(wid, 300+40, -60,
         w - (300+40+40), 40, 0, "txtReward", &gl_defFont, NULL, NULL);
   window_addText(wid, 300+40, -100,
         w - (300+40+40), 40, 0, "txtActiveOSD", &gl_defFont, NULL, NULL);
   window_addText(wid, 300+40, -140,
         w - (300+40+40), h - BUTTON_HEIGHT - 120 - 20, 0,
         "txtDesc", &gl_defFont, NULL, NULL);

   /* Put a map. */
   map_show( wid, 20, 20, 300, 260, 0.75 );

   /* list */
   mission_menu_genList(wid ,1);
}


/**
 * @brief Creates the current mission list for the mission menu.
 *    @param first 1 if it's the first time run.
 */
static void mission_menu_genList( unsigned int wid, int first )
{
   int i, j, m;
   char **misn_names;
   int w, h;
   char *focused;
   const StarSystem *selected_sys;
   Mission *misn;
   int list_pos;
   int list_offset;
   int first_hilight;
   int prev_pos;
   int hilight;
   int nmissions;

   /* Save focus. */
   focused = window_getFocus(wid);
   list_pos = 0;
   list_offset = 0;

   if (!first) {
      list_pos = toolkit_getListPos(wid, "lstMission");
      list_offset = toolkit_getListOffset(wid, "lstMission");
      window_destroyWidget(wid, "lstMission");
   }

   prev_pos = list_pos;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* list */
   misn_names = malloc(sizeof(char*) * MISSION_MAX);
   first_hilight = -1;
   selected_sys = map_getSelected();
   nmissions = 0;
   for (i=0; i<MISSION_MAX; i++) {
      if (player_missions[i]->id == 0)
         continue;

      misn = player_missions[i];

      if (selected_sys != NULL) {
         hilight = 0;
         for (j=0; j<array_size(misn->markers); j++) {
            if (misn->markers[j].sys == selected_sys->id) {
               hilight = 1;
               break;
            }
         }
      }
      else {
         hilight = 1;
      }

      /* Store list index of this mission. */
      m = nmissions++;

      if (hilight && (first || map_clicked)) {
         /* Store the first hilighted index so we can wraparound. */
         if (first_hilight < 0)
            first_hilight = m;

         /* Select this mission if it's the next one. */
         if ((list_pos == prev_pos) && (m > list_pos))
            list_pos = m;
      }

      if (misn->title != NULL)
         asprintf(&misn_names[m], "#%c%s#0", hilight ? 'w' : 'n', misn->title);
      else
         misn_names[m] = strdup("NULL");
   }

   /* If selected mission hasn't changed, select the first hilighted
    * mission. */
   if ((first_hilight >= 0) && (list_pos == prev_pos))
      list_pos = first_hilight;

   if (nmissions == 0) {
      misn_names[0] = strdup(_("No Missions"));
      nmissions = 1;
   }

   window_addList(wid, 20, -40, 300, h - 340,
         "lstMission", misn_names, nmissions, 0, mission_menu_update, NULL);

   /* Restore focus. */
   window_setFocus(wid, focused);
   free(focused);
   toolkit_setListOffset(wid, "lstMission", list_offset);
   toolkit_setListPos(wid, "lstMission", list_pos);
}


/**
 * @brief Updates the mission menu mission information based on what's selected.
 *    @param str Unused.
 */
static void mission_menu_update( unsigned int wid, char* str )
{
   (void)str;
   char *active_misn;
   Mission *misn;
   char **osd_items;
   int osd_active;
   char buf[STRMAX];
   int w, h;
   int x, y, tw, th;

   window_dimWindow(wid, &w, &h);

   x = 300+40;
   y = -60;

   active_misn = toolkit_getList(wid, "lstMission");
   if ((active_misn==NULL) || (strcmp(active_misn,_("No Missions"))==0)) {
      strcpy(buf, _("#nReward:#0 None"));
      window_modifyText(wid, "txtReward", _("#nReward:#0 None"));
      window_dimWidget(wid, "txtReward", &tw, &th);
      th = gl_printHeightRaw(&gl_defFont, tw, buf);
      window_resizeWidget(wid, "txtReward", tw, th);
      window_moveWidget(wid, "txtReward", x, y);

      y -= th + 20;

      window_modifyText(wid, "txtActiveOSD", NULL);

      strcpy(buf, _("You currently have no active missions."));
      window_modifyText(wid, "txtDesc", buf);
      window_dimWidget(wid, "txtDesc", &tw, &th);
      th = gl_printHeightRaw(&gl_defFont, tw, buf);
      window_resizeWidget(wid, "txtDesc", tw, th);
      window_moveWidget(wid, "txtDesc", x, y);

      window_disableButton(wid, "btnAbortMission");
      return;
   }

   misn = player_missions[toolkit_getListPos(wid, "lstMission")];
   if (misn->reward != NULL)
      snprintf(buf, sizeof(buf), _("#nReward:#0 %s"), misn->reward);
   else
      strcpy(buf, _("#nReward:#0 None"));
   window_modifyText(wid, "txtReward", buf);
   window_dimWidget(wid, "txtReward", &tw, &th);
   th = gl_printHeightRaw(&gl_defFont, tw, buf);
   window_resizeWidget(wid, "txtReward", tw, th);
   window_moveWidget(wid, "txtReward", x, y);

   y -= th + 20;

   window_modifyText(wid, "txtActiveOSD", NULL);
   if (misn->osd > 0) {
      osd_items = osd_getItems(misn->osd);
      osd_active = osd_getActive(misn->osd);
      if ((osd_items != NULL) && (osd_active != -1)) {
         snprintf(buf, sizeof(buf), _("#nCurrent Objective:#0 %s"),
               osd_items[osd_active]);
         window_modifyText(wid, "txtActiveOSD", buf);
         window_dimWidget(wid, "txtActiveOSD", &tw, &th);
         th = gl_printHeightRaw(&gl_defFont, tw, buf);
         window_resizeWidget(wid, "txtActiveOSD", tw, th);
         window_moveWidget(wid, "txtActiveOSD", x, y);

         y -= th + 20;
      }
   }

   window_modifyText(wid, "txtDesc", misn->desc);
   window_dimWidget(wid, "txtDesc", &tw, &th);
   th = h - y - BUTTON_HEIGHT - 20 - 10;
   window_resizeWidget(wid, "txtDesc", tw, th);
   window_moveWidget(wid, "txtDesc", x, y);

   if (!pilot_isFlag(player.p, PILOT_MANUAL_CONTROL))
      window_enableButton(wid, "btnAbortMission");
   else
      window_disableButtonSoft(wid, "btnAbortMission");

   /* Make sure the map is in the proper mode. */
   map_setMode(MAPMODE_TRAVEL);
   map_setMinimal(1);

   /* Center map on the selected mission. */
   if ((misn->markers != NULL) && !map_clicked)
      map_center(system_getIndex(misn->markers[0].sys)->name);
}


/**
 * @brief Aborts a mission in the mission menu.
 *    @param str Unused.
 */
static void mission_menu_abort( unsigned int wid, char* str )
{
   (void)str;
   int pos;
   Mission *misn;
   int ret;

   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL)) {
      dialogue_alert(_("You cannot abort missions right now as your ship is"
            " being controlled by a mission or event."));
      return;
   }

   if (dialogue_YesNo( _("Abort Mission"),
            _("Are you sure you want to abort this mission?") )) {

      /* Get the mission. */
      pos = toolkit_getListPos(wid, "lstMission" );
      misn = player_missions[pos];

      /* We run the "abort" function if it's found. */
      ret = misn_tryRun( misn, "abort" );

      /* Now clean up mission. */
      if (ret != 2) {
         mission_cleanup( misn );
         mission_shift(pos);
      }

      /* Reset markers. */
      mission_sysMark();

      /* Reset claims. */
      claim_activateAll();

      /* Regenerate list. */
      mission_menu_genList(wid ,0);

      /* Regenerate cargo list as well since the mission might have had
       * mission cargo. */
      cargo_genList(info_windows[INFO_WIN_CARGO]);

      /* Regenerate bar if landed. */
      bar_regen();
   }
}


/**
 * @brief Updates the mission menu mission information based on what's selected.
 *    @param str Unused.
 */
static void shiplog_menu_update( unsigned int wid, char* str )
{
   int w, h;
   int log;
   int nentries;
   char **newlogentries;
   int entry;
   int i;
   char **logentries;

   if (!logWidgetsReady)
      return;

   /* If a new log has been selected, need to regenerate the entries. */
   if ((str != NULL) && (strcmp(str, "lstLogs") == 0)) {
      /* has selected a log */
      window_dimWindow( wid, &w, &h );
      logWidgetsReady = 0;

      log = toolkit_getListPos( wid, "lstLogs" );

      if (selectedLog != log) {
         selectedLog = CLAMP( 0, nlogs-1, log );
         /* list log entries of selected log */
         window_destroyWidget( wid, "lstLogEntries" );
         shiplog_listLogEntries(logIDs[selectedLog], &nentries,
               &newlogentries, 1);
         window_addList(wid, 20, -40 - (140+10), w/2 - 20 - 10,
               h - 40 - (140+10) - (10+BUTTON_HEIGHT+20),
               "lstLogEntries", newlogentries, nentries, 0,
               shiplog_menu_update, info_shiplogView);
         toolkit_setListPos(wid, "lstLogEntries", 0);
      }

      logWidgetsReady = 1;
   }

   entry = toolkit_getListPos(wid, "lstLogEntries");
   if (entry < 0) {
      window_modifyText(wid, "txtLogEntry", NULL);
      return;
   }

   shiplog_listLogEntries(logIDs[selectedLog], &nentries, &logentries, 1);
   if (entry < nentries)
      window_modifyText(wid, "txtLogEntry", logentries[entry]);

   for (i=0; i<nentries; i++)
      free(logentries[i]);
   free(logentries);
}


/**
 * @brief Generates the ship log information
 *    @param first 1 if it's the first time run.
 */
static void shiplog_menu_genList( unsigned int wid, int first )
{
   int w, h;
   int nentries;
   char **logentries;

   /* Needs 3 lists:
    * 1. List of log types (and All)
    * 2. List of logs of the selected type (and All)
    * 3. Listing of the selected log
    */
   if (!first) {
      window_destroyWidget( wid, "lstLogs" );
      logs = NULL;
      window_destroyWidget( wid, "lstLogEntries" );
   }
   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );

   /* list logs */
   shiplog_listLogs(&nlogs, &logs, &logIDs, 1);
   if ( selectedLog >= nlogs )
      selectedLog = 0;
   /* list log entries of selected log */
   shiplog_listLogEntries(logIDs[selectedLog], &nentries, &logentries, 1);
   logWidgetsReady = 0;
   /* XXX: This ordering is illogical for tab selection, but can't be
    * avoided because this is the order it'll end up in anyway when
    * lstLogEntries is destroyed and recreated due to selecting a log.
    */
   window_addList(wid, 20, -40, w/2 - 20 - 10, 140,
         "lstLogs", logs, nlogs, 0, shiplog_menu_update, NULL);
   window_addList(wid, 20, -40 - (140+10), w/2 - 20 - 10,
         h - 40 - (140+10) - (10+BUTTON_HEIGHT+20),
         "lstLogEntries", logentries, nentries, 0, shiplog_menu_update,
         info_shiplogView);

   logWidgetsReady = 1;

   /* Update text. */
   shiplog_menu_update(wid, NULL);
}

static void info_shiplogView( unsigned int wid, char *str )
{
   char **logentries;
   int nentries;
   int i;
   (void) str;

   i = toolkit_getListPos( wid, "lstLogEntries" );
   if ( i < 0 )
      return;
   shiplog_listLogEntries(logIDs[selectedLog], &nentries, &logentries, 1);

   if ( i < nentries )
      dialogue_msgRaw( _("Log message"), logentries[i] );

   for (i=0; i<nentries; i++)
      free( logentries[i] );
   free( logentries );
}

/**
 * @brief Asks the player for an entry to add to the log
 *
 * @param wid Window widget
 * @param str Button widget name
 */
static void info_shiplogAdd( unsigned int wid, char *str )
{
   char *tmp;
   int log;
   int logid;
   (void) str;

   log = toolkit_getListPos( wid, "lstLogs" );
   if ( log < 0 || logIDs[log] == LOG_ID_ALL ) {
      tmp = dialogue_inputRaw(_("Add Log Entry"), 0, 4096,
            _("Add an entry to your journal:"));
      if ( ( tmp != NULL ) && ( strlen(tmp) > 0 ) ) {
         if (shiplog_getID( "Diary") == -1)
              shiplog_create("Diary", p_("log", "Journal"), 0, 0 );
         shiplog_append("Diary", tmp);
         free( tmp );
      }
   } else {
      tmp = dialogue_input(_("Add Log Entry"), 0, 4096,
            _("Add an entry to the log titled '%s':"), logs[log]);
      if ( ( tmp != NULL ) && ( strlen(tmp) > 0 ) ) {
         logid = shiplog_getLogID(log-1);
         if ( logid >= 0 )
            shiplog_appendByID( logid, tmp );
         else
            dialogue_msgRaw( _("Cannot add log"), _("Cannot find this log!  Something went wrong here!") );
         free( tmp );
      }
   }
   shiplog_menu_genList( wid, 0 );

}


/**
 * @brief Shows the player's ship log.
 *
 *    @param wid Window widget
 */
static void info_openShipLog( unsigned int wid )
{
   int w, h;
   int x;
   /* re-initialise the statics */
   selectedLog = 0;

   /* Get the dimensions. */
   window_dimWindow( wid, &w, &h );
   /* buttons */
   window_addButton( wid, -20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "closeShipLog", _("Close"), info_close );
   window_addButton( wid, -20 - 1*(20+BUTTON_WIDTH), 20, BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnViewLog", _("View Entry"),
         info_shiplogView );
   window_addButton( wid, -20 - 2*(20+BUTTON_WIDTH), 20, BUTTON_WIDTH,
         BUTTON_HEIGHT, "btnAddLog", _("Add Entry"),
         info_shiplogAdd );

   x = w/2 + 10;
   window_addText(wid, x, -40, w - x - 20, h - 40 - (10+BUTTON_HEIGHT+20), 0,
         "txtLogEntry", NULL, NULL, NULL);

   /* list */
   shiplog_menu_genList(wid ,1);
}
