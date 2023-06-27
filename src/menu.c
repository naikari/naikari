/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file menu.h
 *
 * @brief Handles the important game menus.
 */


/** @cond */
#include <time.h>
#include "physfs.h"
#include "SDL.h"

#include "naev.h"
/** @endcond */

#include "menu.h"

#include "array.h"
#include "board.h"
#include "camera.h"
#include "comm.h"
#include "conf.h"
#include "dev_mapedit.h"
#include "dev_uniedit.h"
#include "dialogue.h"
#include "gui.h"
#include "info.h"
#include "intro.h"
#include "land.h"
#include "load.h"
#include "log.h"
#include "map.h"
#include "mission.h"
#include "music.h"
#include "ndata.h"
#include "nstring.h"
#include "ntime.h"
#include "options.h"
#include "pause.h"
#include "pilot.h"
#include "player.h"
#include "rng.h"
#include "save.h"
#include "space.h"
#include "start.h"
#include "tk/toolkit_priv.h" /* Needed for menu_main_resize */
#include "toolkit.h"


#define MENU_WIDTH 240 /**< Window width for all menus. */

#define BUTTON_WIDTH (MENU_WIDTH - 40) /**< Button width for all menus. */
#define BUTTON_HEIGHT 30 /**< Button height, standard across menus. */

#define EDITORS_EXTRA_WIDTH 60 /**< Editors menu extra width. */

int menu_open = 0; /**< Stores the opened/closed menus. */


static glTexture *main_naevLogo = NULL; /**< Naev Logo texture. */
static const char *main_tagline = NULL; /**< Tagline (for events). */


/*
 * prototypes
 */
/* Generic. */
static void menu_exit( unsigned int wid, char* str );
/* main menu */
static int menu_main_bkg_system (void);
static void main_menu_promptClose( unsigned int wid, char *unused );
static void menu_main_load( unsigned int wid, char* str );
static void menu_main_new( unsigned int wid, char* str );
static void menu_main_credits( unsigned int wid, char* str );
static void menu_main_cleanBG( unsigned int wid, char* str );
/* small menu */
static void menu_small_resume(unsigned int wid, char* str);
static void menu_small_info(unsigned int wid, char *str);
static void menu_small_load(unsigned int wid, char *str);
static void menu_small_exit(unsigned int wid, char* str);
static void exit_game (void);
/* death menu */
static void menu_death_continue( unsigned int wid, char* str );
static void menu_death_restart( unsigned int wid, char* str );
static void menu_death_main( unsigned int wid, char* str );
static void menu_death_onclose(unsigned int wid, char* str);
/* editors menu */
/* - Universe Editor */
/* - Back to Main Menu */
static void menu_editors_open( unsigned int wid_unused, char *unused );
static void menu_editors_close( unsigned int wid, char* str );
/* options button. */
static void menu_options_button( unsigned int wid, char *str );


/*
 * Background system for the menu.
 */
static int menu_main_bkg_system (void)
{
   const nsave_t *ns;
   const char *sys;
   Planet *pnt;
   double cx, cy;

   /* Clean pilots. */
   pilots_cleanAll();
   sys = NULL;

   /* Refresh saves. */
   load_refresh();

   /* Load saves. */
   ns = load_getList();

   /* Try to apply unidiff. */
   if (array_size( ns ) > 0) {
      load_gameDiff( ns[0].path );

      /* Get start position. */
      if (planet_exists( ns[0].planet )) {
         pnt = planet_get( ns[0].planet );
         if (pnt != NULL) {
            sys = planet_getSystem( ns[0].planet );
            if (sys != NULL) {
               cx = pnt->pos.x;
               cy = pnt->pos.y;
            }
         }
      }
   }

   /* Fallback if necessary. */
   if (sys == NULL) {
      sys = start_system();
      start_position( &cx, &cy );
   }

   /* Have to normalize values by zoom. */
   cx += SCREEN_W/4. / conf.zoom_far;
   cy += SCREEN_H/8. / conf.zoom_far;

   /* Initialize. */
   space_init( sys );
   cam_setTargetPos( cx, cy, 0 );
   cam_setZoom( conf.zoom_far );
   pause_setSpeed( 1. );
   sound_setSpeed( 1. );

   return 0;
}


/**
 * @brief Opens the main menu (titlescreen).
 */
void menu_main (void)
{
   int offset_logo, offset_wdw, freespace;
   unsigned int bwid, wid;
   glTexture *tex;
   int h, y;
   int th;
   time_t curtime = time(NULL);
   struct tm curlocaltime = *localtime(&curtime);
   int offset;

   if (menu_isOpen(MENU_MAIN)) {
      WARN( _("Menu main is already open.") );
      return;
   }

   /* Close all open windows. */
   toolkit_closeAll();

   /* Clean up GUI - must be done before using SCREEN_W or SCREEN_H. */
   gui_cleanup();
   player_soundStop(); /* Stop sound. */

   /* Play load music. */
   music_choose("load");

   /* Load background and friends. */
   if (curlocaltime.tm_mon == 3) {
      /* Autism Acceptance Month */
      tex = gl_newImage(GFX_PATH"naikari-red.png", 0);
      main_tagline = _("Proudly autistic and lighting up red for Autism"
            " Acceptance Month.");
   }
   else if (curlocaltime.tm_mon == 5) {
      /* Queer Pride Month */
      tex = gl_newImage(GFX_PATH"naikari-rainbow.png", 0);
      main_tagline = _("We're here. We're queer. Get used to it.");
   }
   else {
      tex = gl_newImage(GFX_PATH"naikari.png", 0);
      main_tagline = NULL;

      /* Other events that can't be checked simply. */
      /* Aromantic Spectrum Awareness Week is the first week following
       * Valentine's Day (Feburary 14th). */
      if (curlocaltime.tm_mon == 1) {
         /* Find an offset to see what day the month started on, then
          * use that to find an offset for Valentine's Day. 0 is Sunday,
          * 1 is Monday, etc. Since days of the month are indexed from
          * 0, Valentine's Day is day 13. */
         offset = (curlocaltime.tm_wday-curlocaltime.tm_mday + 13) % 7;
         /* Convert % operator's negative values to positive, ensuring
          * the resulting range is [0,6]. */
         if (offset < 0)
            offset += 7;
         /* Invert the offset; this inverted offset is the number of
          * days remaining in the week after Valentine's Day. Adding 1
          * then gives us an offset for the first day of the following
          * week, thus giving ASAW's offset compared to Valentine's
          * Day. */
         offset = (6-offset) + 1;

         /* Use the offset to check if we're in ASAW. ASAW takes place
          * starting when the current day minus the offset is
          * Valentine's Day, and ending exactly one week after. */
         if ((curlocaltime.tm_mday - offset >= 13)
               && (curlocaltime.tm_mday - offset < 20))
         {
            gl_freeTexture(tex);
            tex = gl_newImage(GFX_PATH"naikari-aro.png", 0);
            main_tagline = _("Love takes many forms. Happy Aromantic Spectrum"
                  " Awareness Week!");
         }
      }
   }
   main_naevLogo = tex;
   menu_main_bkg_system();

   /* Set dimensions */
   y  = 20 + (BUTTON_HEIGHT+20)*4;
   h  = y + 80;
   if (conf.devmode) {
      h += BUTTON_HEIGHT + 20;
      y += BUTTON_HEIGHT + 20;
   }

   /* Calculate Logo and window offset. */
   freespace = SCREEN_H - tex->sh - h;
   th = 0;
   if (main_tagline != NULL) {
      th = gl_printHeightRaw(&gl_defFont, SCREEN_W, main_tagline);
      freespace -= th;
   }
   if (freespace < 0) { /* Not enough freespace, this can get ugly. */
      offset_logo = SCREEN_H - tex->sh;
      offset_wdw  = 0;
   }
   /* Otherwise space evenly. */
   else {
      offset_logo = -freespace/4;
      offset_wdw  = freespace/2;
   }

   /* create background image window */
   bwid = window_create("wdwBG", "", -1, -1, -1, -1);
   window_onClose(bwid, menu_main_cleanBG);
   window_setBorder(bwid, 0);
   window_addImage(bwid, (SCREEN_W-tex->sw) / 2, offset_logo, 0, 0,
         "imgLogo", tex, 0);
   window_addText(bwid, 0, offset_logo - tex->sh, SCREEN_W, th, 1, 
         "txtTagline", NULL, NULL, main_tagline);
   window_addText(bwid, 0, 10, SCREEN_W, 30, 1,
         "txtBG", NULL, NULL, naev_version(1));

   /* create menu window */
   wid = window_create("wdwMainMenu", _("Main Menu"), -1, offset_wdw,
         MENU_WIDTH, h);
   window_setCancel( wid, main_menu_promptClose );

   /* Buttons. */
   window_addButtonKey(wid, 20, y, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnLoad", _("&Load Game"), menu_main_load, SDLK_l);
   y -= BUTTON_HEIGHT+20;
   window_addButtonKey(wid, 20, y, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnNew", _("&New Game"), menu_main_new, SDLK_n);
   y -= BUTTON_HEIGHT+20;
   if (conf.devmode) {
      window_addButtonKey(wid, 20, y, BUTTON_WIDTH, BUTTON_HEIGHT,
            "btnEditor", _("&Editors"), menu_editors_open, SDLK_e);
      y -= BUTTON_HEIGHT+20;
   }
   window_addButtonKey(wid, 20, y, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnOptions", _("&Options"), menu_options_button, SDLK_o);
   y -= BUTTON_HEIGHT+20;
   window_addButtonKey(wid, 20, y, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnCredits", p_("Menu|", "&Credits"), menu_main_credits, SDLK_c);
   y -= BUTTON_HEIGHT+20;
   window_addButtonKey(wid, 20, y, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnExit", _("E&xit Game"), menu_exit, SDLK_x);

   /* Disable load button if there are no saves. */
   if (array_size( load_getList() ) == 0) {
      window_disableButton( wid, "btnLoad" );
      window_setFocus( wid, "btnNew" );
   }
   else
      window_setFocus( wid, "btnLoad" );

   /* Make the background window a child of the menu. */
   window_setParent( bwid, wid );

   unpause_game();
   menu_Open(MENU_MAIN);
}


/**
 * @brief Resizes the main menu and its background.
 *
 * This is a one-off function that ensures the main menu's appearance
 * is consistent regardless of window resizing.
 */
void menu_main_resize (void)
{
   int w, h, bgw, bgh, tw, th;
   int offset_logo, offset_wdw, freespace;
   int menu_id, bg_id;
   Widget *wgt;

   if (!menu_isOpen(MENU_MAIN))
      return;

   menu_id = window_get("wdwMainMenu");
   bg_id   = window_get("wdwBG");

   window_dimWindow( menu_id, &w, &h );
   window_dimWindow( bg_id, &bgw, &bgh );

   freespace = SCREEN_H - main_naevLogo->sh - h;
   th = 0;
   if (main_tagline != NULL) {
      th = gl_printHeightRaw(&gl_defFont, SCREEN_W, main_tagline);
      freespace -= th;
   }
   if (freespace < 0) {
      offset_logo = SCREEN_H - main_naevLogo->sh;
      offset_wdw  = 0;
   }
   else {
      offset_logo = -freespace/4;
      offset_wdw  = freespace/2;
   }

   window_moveWidget(bg_id, "imgLogo",
         (bgw-main_naevLogo->sw) / 2, offset_logo);
   window_resizeWidget(bg_id, "txtTagline", SCREEN_W, th);
   window_moveWidget(bg_id, "txtTagline",
         0, offset_logo - main_naevLogo->sh);

   window_dimWidget(bg_id, "txtBG", &tw, &th);
   if (tw > SCREEN_W) {
      /* RIP abstractions. X must be set manually because window_moveWidget
       * transforms negative coordinates. */
      wgt = window_getwgt( bg_id, "txtBG" );
      if (wgt)
         wgt->x = (SCREEN_W - tw) / 2;
   }
   else
      window_moveWidget( bg_id, "txtBG", (SCREEN_W - tw)/2, 10. );

   window_move( menu_id, -1, offset_wdw );
}


/**
 * @brief Main menu closing prompt.
 */
static void main_menu_promptClose( unsigned int wid, char *unused )
{
   (void) wid;
   (void) unused;
   exit_game();
}


/**
 * @brief Closes the main menu.
 */
void menu_main_close (void)
{
   if (window_exists( "wdwMainMenu" ))
      window_destroy( window_get( "wdwMainMenu" ) );
   else
      WARN( _("Main menu does not exist.") );

   menu_Close(MENU_MAIN);
   pause_game();
}
/**
 * @brief Function to active the load game menu.
 *    @param str Unused.
 */
static void menu_main_load( unsigned int wid, char* str )
{
   (void) str;
   (void) wid;
   load_loadGameMenu();
}
/**
 * @brief Function to active the new game menu.
 *    @param str Unused.
 */
static void menu_main_new( unsigned int wid, char* str )
{
   (void) str;
   (void) wid;

   /* Closes the main menu window. */
   window_destroy( wid );
   menu_Close(MENU_MAIN);
   pause_game();

   /* Start the new player. */
   player_new();
}
/**
 * @brief Function to exit the main menu and game.
 *    @param str Unused.
 */
static void menu_main_credits( unsigned int wid, char* str )
{
   (void) str;
   (void) wid;
   intro_display( "AUTHORS", "credits" );
   /* We'll need to start music again. */
   music_choose("load");
}
/**
 * @brief Function to exit the main menu and game.
 *    @param str Unused.
 */
static void menu_exit( unsigned int wid, char* str )
{
   (void) str;
   (void) wid;

   naev_quit();
}
/**
 * @brief Function to clean up the background window.
 *    @param wid Window to clean.
 *    @param str Unused.
 */
static void menu_main_cleanBG( unsigned int wid, char* str )
{
   (void) wid;
   (void) str;

   gl_freeTexture(main_naevLogo);
   main_naevLogo = NULL;
}


/*
 *
 * in-game menu
 *
 */
/**
 * @brief Opens the small in-game menu.
 */
void menu_small (void)
{
   unsigned int wid;

   /* Check if menu should be openable. */
   if ((player.p == NULL) || player_isFlag(PLAYER_DESTROYED) ||
         pilot_isFlag(player.p,PILOT_DEAD) ||
         comm_isOpen() ||
         dialogue_isOpen() || /* Shouldn't open over dialogues. */
         (menu_isOpen(MENU_MAIN) ||
            menu_isOpen(MENU_SMALL) ||
            menu_isOpen(MENU_DEATH) ))
      return;

   wid = window_create("wdwMenuSmall", _("Menu"), -1, -1, MENU_WIDTH,
         50 + 5*(BUTTON_HEIGHT+20));

   window_setCancel(wid, menu_small_resume);

   window_addButtonKey(wid, 20, 20 + 4*(BUTTON_HEIGHT+20),
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnResume", _("&Resume"), menu_small_resume, SDLK_r);
   window_addButtonKey(wid, 20, 20 + 3*(BUTTON_HEIGHT+20),
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnLoad", _("&Load Game"), menu_small_load, SDLK_l);
   window_addButtonKey(wid, 20, 20 + 2*(BUTTON_HEIGHT+20),
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnInfo", _("Ship &Computer"), menu_small_info, SDLK_c);
   window_addButtonKey(wid, 20, 20 + 1*(BUTTON_HEIGHT+20),
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnOptions", _("&Options"), menu_options_button, SDLK_o);
   window_addButtonKey(wid, 20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnExit", _("E&xit to Title"), menu_small_exit, SDLK_x);

   menu_Open(MENU_SMALL);
}


/**
 * @brief Closes the small menu.
 */
void menu_small_close(void)
{
   if (window_exists("wdwMenuSmall"))
      window_destroy(window_get("wdwMenuSmall"));
   else
      WARN(_("Small menu does not exist."));

   menu_Close(MENU_SMALL);
}


/**
 * @brief Closes the small in-game menu.
 *    @param str Unused.
 */
static void menu_small_resume(unsigned int wid, char* str)
{
   (void)str;
   window_destroy(wid);
   menu_Close(MENU_SMALL);
}


/**
 * @brief Opens the info window.
 *    @param wid Unused.
 *    @param str Unused.
 */
static void menu_small_info( unsigned int wid, char *str )
{
   (void) str;
   (void) wid;

   menu_info( INFO_MAIN );
}


/**
 * @brief Opens the load game window.
 *    @param wid Unused.
 *    @param str Unused.
 */
static void menu_small_load(unsigned int wid, char *str)
{
   (void) str;
   (void) wid;

   /* Save if landed. */
   if (landed && planet_hasService(land_planet, PLANET_SERVICE_REFUEL)) {
      save_all();
   }

   load_loadGameMenu();
}


/**
 * @brief Closes the small in-game menu and goes back to the main menu.
 *    @param str Unused.
 */
static void menu_small_exit( unsigned int wid, char* str )
{
   (void) str;
   unsigned int info_wid, board_wid;

   /* if landed we must save anyways */
   if (landed && planet_hasService(land_planet, PLANET_SERVICE_REFUEL)) {
      save_all();
      land_cleanup();
   }

   /* Close info menu if open. */
   if (menu_isOpen(MENU_INFO)) {
      info_wid = window_get("wdwInfo");
      window_destroy( info_wid );
      menu_Close(MENU_INFO);
   }

   /* Force unboard. */
   if (player_isBoarded()) {
      board_wid = window_get("wdwBoarding");
      board_exit(board_wid, NULL);
   }

   /* Stop player sounds because sometimes they hang. */
   player_restoreControl( 0, _("Exited game.") );
   player_soundStop();

   /* Clean up. */
   window_destroy( wid );
   menu_Close(MENU_SMALL);
   menu_main();
}


/**
 * @brief Exits the game.
 */
static void exit_game (void)
{
   /* if landed we must save */
   if (landed && planet_hasService(land_planet, PLANET_SERVICE_REFUEL))
      save_all();
   naev_quit();
}


/**
 * @brief Reload the current saved game, when player want to continue after death
 */
static void menu_death_continue( unsigned int wid, char* str )
{
   (void) str;

   window_destroy( wid );
   menu_Close(MENU_DEATH);

   save_reload();
}

/**
 * @brief Restart the game, when player want to continue after death but without a saved game
 */
static void menu_death_restart( unsigned int wid, char* str )
{
   (void) str;

   window_destroy( wid );
   menu_Close(MENU_DEATH);

   player_new();
}


/**
 * @brief Opens the load game window.
 *    @param wid Unused.
 *    @param str Unused.
 */
static void menu_death_load(unsigned int wid, char *str)
{
   (void) str;
   (void) wid;

   load_loadGameMenu();
}


/**
 * @brief Player death menu, appears when player got creamed.
 */
void menu_death (void)
{
   unsigned int wid;
   char buf[PATH_MAX];
   char path[PATH_MAX];

   wid = window_create("wdwRIP", _("Death"), -1, -1, MENU_WIDTH,
         50 + 3*(BUTTON_HEIGHT+20));
   window_onClose(wid, menu_death_onclose);

   /* Allow the player to continue if the saved game exists. If not,
    * propose to restart. */
   str2filename(buf, sizeof(buf), player.name);
   if (snprintf(path, sizeof(path), "saves/%s.ns", buf) < 0)
      WARN(_("Save file name was truncated: %s"), path);
   if (PHYSFS_exists(path))
      window_addButtonKey(wid, 20, 20 + 2*(BUTTON_HEIGHT+20),
            BUTTON_WIDTH, BUTTON_HEIGHT,
            "btnContinue", _("&Continue"), menu_death_continue, SDLK_c);
   else
      window_addButtonKey(wid, 20, 20 + 2*(BUTTON_HEIGHT+20),
            BUTTON_WIDTH, BUTTON_HEIGHT,
            "btnRestart", _("&Restart"), menu_death_restart, SDLK_r);

   window_addButtonKey(wid, 20, 20 + 1*(BUTTON_HEIGHT+20),
            BUTTON_WIDTH, BUTTON_HEIGHT,
            "btnLoad", _("&Load Game"), menu_death_load, SDLK_l);
   window_addButtonKey(wid, 20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnMain", _("&Main Menu"), menu_death_main, SDLK_m);
   menu_Open(MENU_DEATH);

   /* Makes it all look cooler since everything still goes on. */
   unpause_game();
}
/**
 * @brief Closes the player death menu.
 *    @param str Unused.
 */
static void menu_death_main( unsigned int wid, char* str )
{
   (void) str;

   window_destroy( wid );
   menu_Close(MENU_DEATH);

   /* Game will repause now since toolkit closes and reopens. */
   menu_main();
}
/**
 * @brief Hack to get around the fact the death menu unpauses the game.
 */
static void menu_death_onclose(unsigned int wid, char* str)
{
   (void) wid;
   (void) str;
   pause_game(); /* Repause the game. */
}


/**
 * @brief Closes the death menu.
 */
void menu_death_close(void)
{
   if (window_exists("wdwRIP"))
      window_destroy(window_get("wdwRIP"));
   else
      WARN(_("Death menu does not exist."));

   menu_Close(MENU_DEATH);
}


/**
 * @brief Opens the menu options from a button.
 */
static void menu_options_button( unsigned int wid, char *str )
{
   (void) wid;
   (void) str;
   opt_menu();
}


/**
 * @brief Menu to ask if player really wants to quit.
 */
int menu_askQuit (void)
{
   /* No need to ask if we're on the main menu. */
   if (menu_isOpen(MENU_MAIN) && !menu_isOpen(MENU_OPTIONS)
         && !menu_isOpen(MENU_LOAD)) {
      exit_game();
      return 1;
   }

   /* Asked twice, quit. */
   if (menu_isOpen(MENU_ASKQUIT)) {
      exit_game();
      return 1;
   }

   /* Ask if should quit. */
   menu_Open(MENU_ASKQUIT);
   if (dialogue_YesNoRaw( _("Quit Naikari"), _("Are you sure you want to quit Naikari?") )) {
      exit_game();
      return 1;
   }
   menu_Close( MENU_ASKQUIT );

   return 0;
}

/**
 * @brief Provisional Menu for when there will be multiple editors
 */
static void menu_editors_open( unsigned int wid, char *unused )
{
   (void) unused;
   int h, y;

   /* Menu already open, quit. */
   if (menu_isOpen( MENU_EDITORS )) {
      return;
   }

   /* Close the Main Menu */
   menu_main_close();
   unpause_game();

   /* Clear known flags - specifically for the SYSTEM_HIDDEN flag. */
   space_clearKnown();

   /* Set dimensions */
   y  = 20 + (BUTTON_HEIGHT+20)*2;
   h  = y + 80;

   wid = window_create( "wdwEditors", _("Editors"), -1, -1, MENU_WIDTH + EDITORS_EXTRA_WIDTH, h );
   window_setCancel( wid, menu_editors_close );

   /* Set buttons for the editors */
   window_addButtonKey(wid, 20, y,
         BUTTON_WIDTH + EDITORS_EXTRA_WIDTH, BUTTON_HEIGHT,
         "btnUniverse", _("&Universe Map"), uniedit_open, SDLK_u);
   y -= BUTTON_HEIGHT+20;
   window_addButtonKey(wid, 20, y,
         BUTTON_WIDTH + EDITORS_EXTRA_WIDTH, BUTTON_HEIGHT,
         "btnMapEdit", _("Map &Outfits"), mapedit_open, SDLK_o);
   y -= BUTTON_HEIGHT+20;
   window_addButtonKey(wid, 20, y,
         BUTTON_WIDTH + EDITORS_EXTRA_WIDTH, BUTTON_HEIGHT,
         "btnMain", _("E&xit to Main Menu"), menu_editors_close, SDLK_x);

    /* Editors menu is open. */
   menu_Open( MENU_EDITORS );

   return;
}

/**
 * @brief Closes the editors menu.
 *    @param str Unused.
 */
static void menu_editors_close( unsigned int wid, char* str )
{
   (void)str;

   /* Close the Editors Menu and mark it as closed */
   window_destroy( wid );
   menu_Close( MENU_EDITORS );

   /* Restores Main Menu */
   menu_main();

   return;
}
