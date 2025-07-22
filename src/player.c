/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file player.c
 *
 * @brief Contains all the player related stuff.
 */


/** @cond */
#include <stdlib.h>
#include "physfs.h"

#include "naev.h"
/** @endcond */

#include "player.h"

#include "ai.h"
#include "camera.h"
#include "claim.h"
#include "comm.h"
#include "conf.h"
#include "credits.h"
#include "dialogue.h"
#include "economy.h"
#include "equipment.h"
#include "escort.h"
#include "event.h"
#include "font.h"
#include "gui.h"
#include "gui_omsg.h"
#include "hook.h"
#include "input.h"
#include "intro.h"
#include "land.h"
#include "land_outfits.h"
#include "log.h"
#include "map.h"
#include "map_overlay.h"
#include "menu.h"
#include "mission.h"
#include "music.h"
#include "ndata.h"
#include "news.h"
#include "nfile.h"
#include "nlua.h"
#include "nlua_misn.h"
#include "nlua_outfit.h"
#include "nlua_ship.h"
#include "nlua_var.h"
#include "nstring.h"
#include "ntime.h"
#include "nxml.h"
#include "opengl.h"
#include "pause.h"
#include "perlin.h"
#include "pilot.h"
#include "player_gui.h"
#include "rng.h"
#include "shiplog.h"
#include "sound.h"
#include "space.h"
#include "spfx.h"
#include "start.h"
#include "toolkit.h"
#include "unidiff.h"


/*
 * player stuff
 */
Player_t player; /**< Local player. */
static const Ship* player_ship      = NULL; /**< Temporary ship to hold when naming it */
static credits_t player_creds = 0; /**< Temporary, for when creating. */
static credits_t player_payback = 0; /**< Temporary, for when creating. */
static int player_ran_updater = 0; /**< Temporary, for when creating. */
static char *player_message_noland = NULL; /**< No landing message (when PLAYER_NOLAND is set). */

/*
 * Licenses.
 */
static char **player_licenses = NULL; /**< Licenses player has. */

/*
 * Default radar resolution.
 */
#define RADAR_RES_DEFAULT 100. /**< Default radar resolution. */


/*
 * player sounds.
 */
static int player_engine_group = -1; /**< Player engine sound group. */
static int player_hyper_group = -1; /**< Player hyperspace sound group. */
static int player_gui_group  = -1; /**< Player GUI sound group. */
int snd_target = -1; /**< Sound when targeting. */
int snd_jump = -1; /**< Sound when can jump. */
int snd_nav = -1; /**< Sound when changing nav computer. */
int snd_hail = -1; /**< Sound when being hailed. */
int snd_comm = -1; /**< Sound when player recieves a comm. */
int snd_broadcast = -1; /**< Sound when player recieves a broadcast. */
/* Hyperspace sounds. */
int snd_hypPowUp              = -1; /**< Hyperspace power up sound. */
int snd_hypEng                = -1; /**< Hyperspace engine sound. */
int snd_hypPowDown            = -1; /**< Hyperspace power down sound. */
int snd_hypPowUpJump          = -1; /**< Hyperspace Power up to jump sound. */
int snd_hypJump               = -1; /**< Hyperspace jump sound. */
static int player_lastEngineSound = -1; /**< Last engine sound. */
static int player_hailCounter = 0; /**< Number of times to play the hail. */
static double player_hailTimer = 0.; /**< Timer for hailing. */


/*
 * player pilot stack - ships he has
 */
static PlayerShip_t* player_stack   = NULL;  /**< Stack of ships player has. */


/*
 * player outfit stack - outfits he has
 */
static PlayerOutfit_t *player_outfits  = NULL;  /**< Outfits player has. */


/*
 * player global properties
 */
/* used in input.c */
double player_left         = 0.; /**< Player left turn velocity from input. */
double player_right        = 0.; /**< Player right turn velocity from input. */
double player_acc          = 0.; /**< Accel velocity from input. */
/* for death and such */
static double player_timer = 0.; /**< For death and such. */


/*
 * unique mission stack.
 */
static int* missions_done  = NULL; /**< Array (array.h): Saves position of completed missions. */


/*
 * unique event stack.
 */
static int* events_done  = NULL; /**< Array (array.h): Saves position of completed events. */


/*
 * prototypes
 */
/*
 * internal
 */
static void player_checkHail (void);
/* creation */
static void player_newSetup();
static int player_newMake (void);
static Pilot* player_newShipMake( const char* name );
/* sound */
static void player_initSound (void);
/* save/load */
static int player_saveEscorts( xmlTextWriterPtr writer );
static int player_saveShipSlot( xmlTextWriterPtr writer, PilotOutfitSlot *slot, int i );
static int player_saveShip( xmlTextWriterPtr writer, Pilot* ship );
static int player_saveMetadata( xmlTextWriterPtr writer );
static Planet* player_parse( xmlNodePtr parent );
static int player_parseDoneMissions( xmlNodePtr parent );
static int player_parseDoneEvents( xmlNodePtr parent );
static int player_parseLicenses( xmlNodePtr parent );
static void player_parseShipSlot( xmlNodePtr node, Pilot *ship, PilotOutfitSlot *slot );
static int player_parseShip( xmlNodePtr parent, int is_player );
static int player_parseEscorts( xmlNodePtr parent );
static int player_parseMetadata( xmlNodePtr parent );
static void player_addOutfitToPilot(Pilot* pilot, const Outfit* outfit,
      PilotOutfitSlot *s);
static int player_runUpdaterScript(const char *type, const char *name, int q);
static const Outfit* player_tryGetOutfit(const char *name, int q);
static const Ship* player_tryGetShip(const char *name);
/* Misc. */
static int player_filterSuitablePlanet( Planet *p );
static void player_planetOutOfRangeMsg (void);
static int player_outfitCompare( const void *arg1, const void *arg2 );
static int player_thinkMouseFly(void);
static int preemption = 0; /* Hyperspace target/untarget preemption. */
/*
 * externed
 */
int player_save( xmlTextWriterPtr writer ); /* save.c */
Planet* player_load( xmlNodePtr parent ); /* save.c */


/**
 * @brief Initializes player stuff.
 */
int player_init (void)
{
   if (player_stack==NULL)
      player_stack = array_create( PlayerShip_t );
   if (player_outfits==NULL)
      player_outfits = array_create( PlayerOutfit_t );
   player_initSound();
   return 0;
}

/**
 * @brief Sets up a new player.
 */
static void player_newSetup()
{
   double x, y;

   /* Setup sound */
   player_initSound();

   /* Clean up player stuff if we'll be recreating. */
   player_cleanup();

   /* Set up GUI. */
   player.radar_res = RADAR_RES_DEFAULT;
   gui_setDefaults();

   /* Reasonable time defaults. */
   player.last_played = time(NULL);
   player.date_created = player.last_played;
   player.time_since_save = player.last_played;

   /* For pretty background. */
   pilots_cleanAll();
   space_init( start_system() );
   start_position( &x, &y );

   cam_setTargetPos( x, y, 0 );
   cam_setZoom( conf.zoom_far );

   /* Clear the init message for new game. */
   gui_clearMessages();
}


/**
 * @brief Creates a new player.
 *
 *   - Cleans up after old players.
 *   - Prompts for name.
 *
 * @sa player_newMake
 */
void player_new (void)
{
   int r;
   char buf[PATH_MAX], buf2[PATH_MAX];
   int written;

   /* Set up new player. */
   player_newSetup();

   /* Some meta-data. */
   player.date_created = time(NULL);

   /* Get the name. */
   player.name = dialogue_input( _("Player Name"), 1, 60,
         _("Please write your name:") );

   /* Player cancelled dialogue. */
   if (player.name == NULL) {
      menu_main();
      return;
   }

   str2filename(buf2, sizeof(buf2), player.name);
   written = snprintf(buf, sizeof(buf), "saves/%s.ns", buf2);
   if (written < 0) {
      WARN(_("Error writing save file name."));
      return;
   }
   else if (written >= (int)sizeof(buf))
      WARN(_("Save file name was truncated: %s"), buf);
   if (PHYSFS_exists( buf )) {
      r = dialogue_YesNo(_("Overwrite"),
            _("You already have a pilot named %s. Overwrite?"), player.name);
      if (r==0) { /* no */
         player_new();
         return;
      }
   }

   if (player_newMake())
      return;

   /* Play music. */
   music_choose( "ambient" );

   /* Add the mission if found. */
   if (start_mission() != NULL) {
      if (mission_start(start_mission(), NULL) < 0)
         WARN(_("Failed to run start mission '%s'."), start_mission());
   }

   /* Add the event if found. */
   if (start_event() != NULL) {
      if (event_start( start_event(), NULL ))
         WARN(_("Failed to run start event '%s'."), start_event());
   }

   /* Run the load event trigger. */
   events_trigger( EVENT_TRIGGER_LOAD );

   /* Load the GUI. */
   gui_load( gui_pick() );
}


/**
 * @brief Actually creates a new player.
 *
 *    @return 0 on success.
 */
static int player_newMake (void)
{
   Ship *ship;
   const char *shipname;
   double x,y;

   if (player_stack==NULL)
      player_stack = array_create( PlayerShip_t );
   if (player_outfits==NULL)
      player_outfits = array_create( PlayerOutfit_t );

   /* Time. */
   ntime_set(start_date());
   /* Welcome message - must be before space_init. */
   player_message(_("Welcome to %s!"), APPNAME);
   player_message("v%s", naev_version(0));

   /* Try to create the pilot, if fails reask for player name. */
   ship = ship_get( start_ship() );
   shipname = start_shipname();
   if (ship==NULL) {
      WARN(_("Ship not properly set by module."));
      return -1;
   }
   /* Setting a default name in the XML prevents naming prompt. */
   if (player_newShip( ship, shipname, 0, (shipname==NULL) ? 0 : 1 ) == NULL) {
      return -1;
   }
   start_position( &x, &y );
   vect_cset( &player.p->solid->pos, x, y );
   vectnull( &player.p->solid->vel );
   player.p->solid->dir = RNGF() * 2.*M_PI;
   space_init( start_system() );

   /* Set player speed to default 1 */
   player.speed = 1.;

   /* Reset speed (to make sure conf.dt_mod is accounted for). */
   player_autonavResetSpeed();

   /* Monies. */
   player.p->credits = start_credits();

   /* Update player weapon sets (in case a weapon or activated outfit
    * is a default outfit). */
   pilot_weaponAuto(player.p);

   /* clear the map */
   map_cleanup();
   map_clear();

   /* Start the economy. */
   economy_init();

   /* clear the shiplog*/
   shiplog_clear();

   /* Start the news */
   news_init();

   return 0;
}


/**
 * @brief Creates a new ship for player.
 *
 *    @param ship New ship to get.
 *    @param def_name Default name to give it if cancelled.
 *    @param trade Whether or not to trade player's current ship with the new ship.
 *    @param noname Whether or not to let the player name it.
 *    @return Newly created pilot on success or NULL if dialogue was cancelled.
 *
 * @sa player_newShipMake
 */
Pilot* player_newShip( const Ship* ship, const char *def_name,
      int trade, int noname )
{
   char *ship_name, *temp_name;
   const char *old_name;
   int i, len, w;
   int n, failed;
   Pilot *new_ship;

   /* temporary values while player doesn't exist */
   player_creds = (player.p != NULL) ? player.p->credits : 0;
   player_ship = ship;
   if (!noname)
      ship_name = dialogue_input( _("Ship Name"), 1, 60,
            _("Please name your new ship:") );
   else
      ship_name = NULL;

   /* Dialogue cancelled. */
   if (ship_name == NULL) {
      /* No default name, fail. */
      if (def_name == NULL)
         return NULL;

      /* Add default name. */
      i = 2;
      len = strlen(def_name) + 10;
      ship_name = malloc(len * sizeof(ship_name));
      strcpy( ship_name, def_name );
      while (player_hasShip(ship_name)) {
         snprintf( ship_name, len, "%s %d", def_name, i );
         i++;
      }
   }

   /* Player is trading ship in. */
   if (trade) {
      if (player.p == NULL)
         ERR(_("Player ship isn't valid... This shouldn't happen!"));
      old_name = player.p->name;
   }
   else
      old_name = NULL;

   /* Must not have same name. */
   if (player_hasShip(ship_name)) {
      if ((old_name != NULL) && (strcmp(ship_name, old_name) == 0)) {
         /* Add temporary name. */
         failed = 0;
         i = 2;
         len = strlen("temp") + 10;
         temp_name = malloc(len * sizeof(temp_name));
         strcpy(temp_name, "temp");

         while (player_hasShip(temp_name)) {
            n = snprintf(temp_name, len, "temp-%d", i);
            i++;

            /* If the whole temp name wasn't written, count as failure
             * and break from the loop. Silences a warning about an
             * unlikely, but possible, event that would cause an
             * infinite loop. */
            if ((n < 0) || (n >= len)) {
               failed = 1;
               break;
            }
         }

         if (!failed) {
            free(player.p->name);
            player.p->name = temp_name;
            old_name = player.p->name;
         }
      }
      else {
         dialogue_msg(_("Name collision"),
               _("Please do not give the ship the same name as another of your"
                  " ships."));
         free(ship_name);
         return NULL;
      }
   }

   new_ship = player_newShipMake( ship_name );

   if (old_name != NULL) {
      /* Undeploy any deployed escorts. */
      pilot_undeployAll(player.p);

      player_swapShip(ship_name, 1); /* Move to the new ship. */
      player_rmShip(old_name);
   }

   free(ship_name);

   /* Update ship list if landed. */
   if (landed) {
      w = land_getWid( LAND_WINDOW_EQUIPMENT );
      equipment_regenLists( w, 0, 1 );
   }

   return new_ship;
}

/**
 * @brief Actually creates the new ship.
 */
static Pilot* player_newShipMake( const char* name )
{
   Vector2d vp, vv;
   PilotFlags flags;
   PlayerShip_t *ship;
   Pilot *new_pilot;
   double px, py, dir;
   pilotId_t id;

   /* store the current ship if it exists */
   pilot_clearFlagsRaw( flags );
   pilot_setFlagRaw( flags, PILOT_PLAYER );

   /* in case we're respawning */
   player_rmFlag( PLAYER_CREATING );

   /* create the player */
   if (player.p == NULL) {
      /* Set position to defaults. */
      if (player.p != NULL) {
         px    = player.p->solid->pos.x;
         py    = player.p->solid->pos.y;
         dir   = player.p->solid->dir;
      }
      else {
         px    = 0.;
         py    = 0.;
         dir   = 0.;
      }
      vect_cset( &vp, px, py );
      vect_cset( &vv, 0., 0. );

      /* Create the player. */
      id = pilot_create( player_ship, name, faction_get("Player"), "player",
            dir, &vp, &vv, flags, 0, 0 );
      cam_setTargetPilot( id, 0 );
      new_pilot = pilot_get( id );
   }
   else {
      /* Grow memory. */
      ship        = &array_grow( &player_stack );
      /* Create the ship. */
      ship->p     = pilot_createEmpty( player_ship, name, faction_get("Player"), "player", flags );
      new_pilot   = ship->p;
   }

   if (player.p == NULL)
      ERR(_("Something seriously wonky went on, newly created player does not exist, bailing!"));

   /* Add GUI. */
   player_guiAdd(player_ship->gui);

   /* money. */
   player.p->credits = player_creds;
   player_creds = 0;

   return new_pilot;
}


/**
 * @brief Swaps player's current ship with their ship named shipname.
 *
 *    @param shipname Ship to change to.
 *    @param move_cargo Whether or not to move the cargo over or ignore it.
 */
void player_swapShip( const char *shipname, int move_cargo )
{
   int i;
   Pilot* ship;
   Vector2d v;
   double dir;

   for (i=0; i<array_size(player_stack); i++) {
      if (strcmp(shipname,player_stack[i].p->name)!=0)
         continue;

      /* Undeploy any escorts. */
      pilot_undeployAll(player.p);

      /* swap player and ship */
      ship = player_stack[i].p;

      /* move credits over */
      ship->credits = player.p->credits;

      /* move cargo over */
      if (move_cargo)
         pilot_cargoMove( ship, player.p );

      /* Copy target info */
      ship->target = player.p->target;
      ship->nav_planet = player.p->nav_planet;
      ship->nav_hyperspace = player.p->nav_hyperspace;
      ship->nav_anchor = player.p->nav_anchor;
      ship->nav_asteroid = player.p->nav_asteroid;

      /* Store position. */
      v = player.p->solid->pos;
      dir = player.p->solid->dir;

      /* extra pass to calculate stats */
      pilot_calcStats( ship );
      pilot_calcStats( player.p );

      /* now swap the players */
      player_stack[i].p = player.p;
      player.p          = pilot_replacePlayer( ship );

      /* Copy position back. */
      player.p->solid->pos = v;
      player.p->solid->dir = dir;

      /* Fill the tank. */
      if (landed)
         land_refuel();

      /* Set some gui stuff. */
      gui_load( gui_pick() );

      /* Bind camera. */
      cam_setTargetPilot( player.p->id, 0 );
      return;
   }
   WARN( _("Unable to swap player.p with ship '%s': ship does not exist!"), shipname );
}


/**
 * @brief Calculates the price of one of the player's ships.
 *
 *    @param shipname Name of the ship.
 *    @return The price of the ship in credits.
 */
credits_t player_shipPrice( const char *shipname )
{
   int i;
   Pilot *ship = NULL;

   if (strcmp(shipname,player.p->name)==0)
      ship = player.p;
   else {
      /* Find the ship. */
      for (i=0; i<array_size(player_stack); i++) {
         if (strcmp(shipname,player_stack[i].p->name)==0) {
            ship = player_stack[i].p;
            break;
         }
      }
   }

   /* Not found. */
   if (ship == NULL) {
      WARN( _("Unable to find price for player's ship '%s': ship does not exist!"), shipname );
      return -1;
   }

   return pilot_worth( ship );
}


/**
 * @brief Removes one of the player's ships.
 *
 *    @param shipname Name of the ship to remove.
 */
void player_rmShip( const char *shipname )
{
   int i, w;

   for (i=0; i<array_size(player_stack); i++) {
      /* Not the ship we are looking for. */
      if (strcmp(shipname, player_stack[i].p->name) != 0)
         continue;

      /* Free player ship. */
      pilot_free(player_stack[i].p);
      array_erase(&player_stack, &player_stack[i], &player_stack[i+1]);
      break;
   }

   /* Update ship list if landed. */
   if (landed) {
      w = land_getWid( LAND_WINDOW_EQUIPMENT );
      equipment_regenLists( w, 0, 1 );
   }
}


/**
 * @brief Cleans up player stuff like player_stack.
 */
void player_cleanup (void)
{
   int i;

   /* Enable all input. */
   input_enableAll();

   /* Clean up other stuff. */
   diff_clear();
   var_cleanup();
   missions_cleanup();
   events_cleanup();
   space_clearKnown();
   land_cleanup();
   map_cleanup();
   factions_clearDynamic();

   /* Reset controls. */
   player_accelOver();
   player_left = 0.;
   player_right = 0.;

   /* Clear player. */
   player_clear();

   /* Clear hail timer. */
   player_hailCounter = 0;
   player_hailTimer = 0.;

   /* Clear messages. */
   gui_clearMessages();

   /* Reset factions. */
   factions_reset();

   free(player.name);
   player.name = NULL;

   free(player_message_noland);
   player_message_noland = NULL;

   /* Clean up gui. */
   gui_cleanup();
   ovr_setOpen(0);

   /* clean up the stack */
   for (i=0; i<array_size(player_stack); i++)
      pilot_free(player_stack[i].p);
   array_free(player_stack);
   player_stack = NULL;
   /* nothing left */

   array_free(player_outfits);
   player_outfits  = NULL;

   array_free(missions_done);
   missions_done = NULL;

   array_free(events_done);
   events_done = NULL;

   /* Clean up licenses. */
   for (i=0; i<array_size(player_licenses); i++)
      free(player_licenses[i]);
   array_free(player_licenses);
   player_licenses = NULL;

   /* Clear claims. */
   claim_clear();

   /* just in case purge the pilot stack */
   pilots_cleanAll();

   /* Reset some player stuff. */
   player_creds = 0;
   player_payback = 0;
   free( player.gui );
   player.gui = NULL;

   /* Clear omsg. */
   omsg_cleanup();

   /* Clear autonav message. */
   free(player.autonavmsg);
   player.autonavmsg = NULL;

   /* Stop the sounds. */
   sound_stopAll();

   /* Reset time compression. */
   pause_setSpeed(1.);
   sound_setSpeed(1.);

   free( player.loaded_version );
   player.loaded_version = NULL;

   /* Clean up. */
   memset(&player, 0, sizeof(Player_t));
   player_setFlag(PLAYER_CREATING);
}


static int player_soundReserved = 0; /**< Has the player already reserved sound? */
/**
 * @brief Initializes the player sounds.
 */
static void player_initSound (void)
{
   if (player_soundReserved)
      return;

   /* Allocate channels. */
   player_engine_group  = sound_createGroup(1); /* Channel for engine noises. */
   player_gui_group     = sound_createGroup(4);
   player_hyper_group   = sound_createGroup(4);
   sound_speedGroup( player_gui_group, 0 ); /* Disable pitch shift. */
   player_soundReserved = 1;

   /* Get sounds. */
   snd_target = sound_get("target");
   snd_jump = sound_get("jump");
   snd_nav = sound_get("nav");
   snd_hail = sound_get("hail");
   snd_comm = sound_get("comm");
   snd_broadcast = sound_get("broadcast");
   snd_hypPowUp = sound_get("hyperspace_powerup");
   snd_hypEng = sound_get("hyperspace_engine");
   snd_hypPowDown = sound_get("hyperspace_powerdown");
   snd_hypPowUpJump = sound_get("hyperspace_powerupjump");
   snd_hypJump = sound_get("hyperspace_jump");
}


/**
 * @brief Plays a GUI sound (unaffected by time accel).
 *
 *    @param sound ID of the sound to play.
 *    @param once Play only once?
 */
void player_soundPlayGUI( int sound, int once )
{
   sound_playGroup( player_gui_group, sound, once );
}


/**
 * @brief Plays a sound at the player.
 *
 *    @param sound ID of the sound to play.
 *    @param once Play only once?
 */
void player_soundPlay( int sound, int once )
{
   sound_playGroup( player_hyper_group, sound, once );
}


/**
 * @brief Stops playing player sounds.
 */
void player_soundStop (void)
{
   if (player_gui_group >= 0)
      sound_stopGroup( player_gui_group );
   if (player_engine_group >= 0)
      sound_stopGroup( player_engine_group );
   if (player_hyper_group >= 0)
      sound_stopGroup( player_hyper_group );

   /* No last engine sound. */
   player_lastEngineSound = -1;
}


/**
 * @brief Pauses the ship's sounds.
 */
void player_soundPause (void)
{
   if (player_engine_group >= 0)
      sound_pauseGroup(player_engine_group);
   if (player_hyper_group >= 0)
      sound_pauseGroup(player_hyper_group);
}


/**
 * @brief Resumes the ship's sounds.
 */
void player_soundResume (void)
{
   if (player_engine_group >= 0)
      sound_resumeGroup(player_engine_group);
   if (player_hyper_group >= 0)
      sound_resumeGroup(player_hyper_group);
}


/**
 * @brief Warps the player to the new position
 *
 *    @param x X value of the position to warp to.
 *    @param y Y value of the position to warp to.
 */
void player_warp( const double x, const double y )
{
   vect_cset( &player.p->solid->pos, x, y );
}


/**
 * @brief Clears the targets.
 */
void player_clear (void)
{
   if (player.p != NULL) {
      pilot_setTarget( player.p, player.p->id );
      gui_setTarget();
   }

   /* Clear the noland flag. */
   player_rmFlag( PLAYER_NOLAND );
}


/**
 * @brief Checks to see if the player has enough credits.
 *
 *    @param amount Amount of credits to check to see if the player has.
 *    @return 1 if the player has enough credits.
 */
int player_hasCredits( credits_t amount )
{
   return pilot_hasCredits( player.p, amount );
}


/**
 * @brief Modifies the amount of credits the player has.
 *
 *    @param amount Quantity to modify player's credits by.
 *    @return Amount of credits the player has.
 */
credits_t player_modCredits( credits_t amount )
{
   return pilot_modCredits( player.p, amount );
}


/**
 * @brief Renders the player
 */
void player_render( double dt )
{
   double a, b, d, x1, y1, x2, y2, r, theta;
   int zero_swivel;
   double time;
   int i;
   int inrange;
   const Outfit *o;
   glColour c;
   Pilot *target;

   /*
    * Check to see if the death menu should pop up.
    */
   if (player_isFlag(PLAYER_DESTROYED)) {
      player_timer -= dt;
      if (!toolkit_isOpen() && !player_isFlag(PLAYER_CREATING) &&
            (player_timer < 0.))
         menu_death();
   }

   /*
    * Render the player.
    */
   if ((player.p != NULL) && !player_isFlag(PLAYER_CREATING) &&
         !pilot_isFlag( player.p, PILOT_HIDE)) {

      /* Render the aiming lines. */
      if ((player.p->target != PLAYER_ID) && player.p->aimLines
            && !pilot_isFlag(player.p, PILOT_HYPERSPACE)
            && !pilot_isFlag(player.p, PILOT_DISABLED)
            && !pilot_isFlag(player.p, PILOT_LANDING)
            && !pilot_isFlag(player.p, PILOT_TAKEOFF)
            && !player_isFlag(PLAYER_CINEMATICS_GUI)) {
         target = pilot_get(player.p->target);
         if (target != NULL) {
            r = 200.;
            gl_gameToScreenCoords( &x1, &y1, player.p->solid->pos.x, player.p->solid->pos.y );

            b = pilot_aimAngle( player.p, target );
            a = b;

            inrange = 0;

            theta = 2*M_PI;
            zero_swivel = 0;

            for (i=0; i<array_size(player.p->outfit_weapon); i++) {
               o = player.p->outfit_weapon[i].outfit;

               if (o == NULL)
                  continue;
               
               /* Ignore fighter bays as they don't need aim lines. */
               if (outfit_isFighterBay(o))
                  continue;

               time = pilot_weapFlyTime(o, player.p, &target->solid->pos,
                     &target->solid->vel);
               if (outfit_duration(o) < time)
                  continue;

               inrange = 1;

               if (outfit_isTurret(o))
                  continue;

               if (outfit_isBolt(o)) {
                  if (o->u.blt.swivel > 0)
                     theta = MIN(theta, o->u.blt.swivel);
                  else
                     zero_swivel = 1;
               }
               else if (outfit_isBeam(o)) {
                  if (o->u.bem.swivel > 0)
                     theta = MIN(theta, o->u.bem.swivel);
                  else
                     zero_swivel = 1;
               }
               else if (outfit_isLauncher(o)) {
                  if ((o->u.lau.arc > 0) || (o->u.lau.swivel > 0))
                     theta = MIN(theta, MAX(o->u.lau.swivel, o->u.lau.arc));
                  else
                     zero_swivel = 1;
               }
            }

            /* Reasonable defaults. */
            d = 0.;
            c.r = 0.;
            c.g = 0.;
            c.b = 0.;
            c.a = 1.;

            if ((theta < 2*M_PI) && (theta != 0)) {
               a = player.p->solid->dir;

               /* The angular error will give the exact colour that is used. */
               d = ABS(angle_diff(a,b) / (2*theta));
               d = MIN(1, d);

               c = cInert;
               c.a = 0.3;
               gl_gameToScreenCoords(&x2, &y2,
                     player.p->solid->pos.x + r*cos(a+theta),
                     player.p->solid->pos.y + r*sin(a+theta));
               gl_drawLine(x1, y1, x2, y2, &c);
               gl_gameToScreenCoords(&x2, &y2,
                     player.p->solid->pos.x + r*cos(a-theta),
                     player.p->solid->pos.y + r*sin(a-theta));
               gl_drawLine(x1, y1, x2, y2, &c);
            }
            else if (zero_swivel) {
               a = player.p->solid->dir;

               /* A swivel of zero means that only exactly perfect
                * aiming is sufficient, within a margin of error. We'll
                * treat that margin of error as pi/360, or 0.5°. */
               d = (ABS(angle_diff(a, b)) < M_PI / 360.) ? 0. : 1.;

               c = cInert;
               c.a = 0.3;
            }

            if (inrange) {
               c.r = d*.9;
               c.g = d*.2 + (1-d)*.8;
               c.b = (1-d)*.2;
               c.a = 0.9;
               gl_gameToScreenCoords( &x2, &y2, player.p->solid->pos.x + r*cos( a ),
                                      player.p->solid->pos.y + r*sin( a ) );

               gl_drawLine( x1, y1, x2, y2, &c );

               glUseProgram(shaders.crosshairs.program);
               glUniform1f(shaders.crosshairs.paramf, 2.);
               gl_renderShader(x2, y2, 7, 7, 0., &shaders.crosshairs,
                     &cWhite, 1);
            }

            gl_gameToScreenCoords( &x2, &y2, player.p->solid->pos.x + r*cos( b ),
                                   player.p->solid->pos.y + r*sin( b ) );

            c.a = .4;
            gl_drawLine( x1, y1, x2, y2, &c );

            gl_drawCircle( x2, y2, 8., &cBlack, 0 );
            gl_drawCircle( x2, y2, 10., &cBlack, 0 );
            gl_drawCircle( x2, y2, 9., &cWhite, 0 );
         }
      }

      /* Render the player's pilot. */
      pilot_render(player.p, dt);
   }
}


/**
 * @brief Basically uses keyboard input instead of AI input. Used in pilot.c.
 *
 *    @param pplayer Player to think.
 *    @param dt Current delta tick.
 */
void player_think( Pilot* pplayer, const double dt )
{
   Pilot *target;
   AsteroidAnchor *field;
   Asteroid *ast;
   double turn;
   int facing, fired;

   /* last i heard, the dead don't think */
   if (pilot_isFlag(pplayer,PILOT_DEAD)) {
      /* no sense in accelerating or turning */
      pilot_setThrust( pplayer, 0. );
      pilot_setTurn( pplayer, 0. );
      return;
   }

   /* We always have to run ai_think in the case the player has escorts so that
    * they properly form formations. */
   ai_think( pplayer, dt );

   /* Under manual control is special. */
   if (pilot_isFlag( pplayer, PILOT_MANUAL_CONTROL )) {
      return;
   }

   /* Not facing anything yet. */
   facing = 0;

   /* Autonav takes over normal controls. */
   if (player_isFlag(PLAYER_AUTONAV)) {
      player_thinkAutonav( pplayer, dt );

      /* Disable turning. */
      facing = 1;
   }

   /* Mouse-flying is enabled. */
   if (!facing && player_isFlag(PLAYER_MFLY))
      facing = player_thinkMouseFly();

   /* turning taken over by PLAYER_FACE */
   if (!facing && player_isFlag(PLAYER_FACE)) {
      /* Try to face pilot target. */
      if (player.p->target != PLAYER_ID) {
         target = pilot_get(player.p->target);
         if (target != NULL) {
            pilot_face( pplayer,
                  vect_angle( &player.p->solid->pos, &target->solid->pos ));

            /* Disable turning. */
            facing = 1;
         }
      }
      /* Try to face asteroid. */
      else if (player.p->nav_asteroid != -1) {
         field = &cur_system->asteroids[player.p->nav_anchor];
         ast = &field->asteroids[player.p->nav_asteroid];
         pilot_face( pplayer,
               vect_angle( &player.p->solid->pos, &ast->pos ));
         /* Disable turning. */
         facing = 1;
      }
      /* If not try to face planet target. */
      else if ((player.p->nav_planet != -1) && ((preemption == 0) || (player.p->nav_hyperspace == -1))) {
         pilot_face( pplayer,
               vect_angle( &player.p->solid->pos,
                  &cur_system->planets[ player.p->nav_planet ]->pos ));
         /* Disable turning. */
         facing = 1;
      }
      else if (player.p->nav_hyperspace != -1) {
         pilot_face( pplayer,
               vect_angle( &player.p->solid->pos,
                  &cur_system->jumps[ player.p->nav_hyperspace ].pos ));
         /* Disable turning. */
         facing = 1;
      }
   }

   /* turning taken over by PLAYER_REVERSE */
   if (player_isFlag(PLAYER_REVERSE)) {

      /* Check to see if already stopped. */
      /*
      if (VMOD(pplayer->solid->vel) < MIN_VEL_ERR)
         player_accel( 0. );

      else {
         d = pilot_face( pplayer, VANGLE(player.p->solid->vel) + M_PI );
         if ((player_acc < 1.) && (d < MAX_DIR_ERR))
            player_accel( 1. );
      }
      */

      /*
       * If the player has reverse thrusters, fire those.
       */
      if (player.p->stats.reverse_thrust > 0.)
         player_accel(-player.p->stats.reverse_thrust);
      else if (!facing) {
         pilot_face(pplayer, VANGLE(player.p->solid->vel) + M_PI);
         /* Disable turning. */
         facing = 1;
      }
   }

   /* normal turning scheme */
   if (!facing) {
      turn = 0;
      if (player_isFlag(PLAYER_TURN_LEFT))
         turn -= player_left;
      if (player_isFlag(PLAYER_TURN_RIGHT))
         turn += player_right;
      turn = CLAMP( -1., 1., turn );
      pilot_setTurn( pplayer, -turn );
   }

   /*
    * Weapon shooting stuff
    */
   fired = 0;

   /* Primary weapon. */
   if (player_isFlag(PLAYER_PRIMARY)) {
      fired |= pilot_shoot( pplayer, 0 );
      player_setFlag(PLAYER_PRIMARY_L);
   }
   else if (player_isFlag(PLAYER_PRIMARY_L)) {
      pilot_shootStop( pplayer, 0 );
      player_rmFlag(PLAYER_PRIMARY_L);
   }
   /* Secondary weapon - we use PLAYER_SECONDARY_L to track last frame. */
   if (player_isFlag(PLAYER_SECONDARY)) { /* needs target */
      fired |= pilot_shoot( pplayer, 1 );
      player_setFlag(PLAYER_SECONDARY_L);
   }
   else if (player_isFlag(PLAYER_SECONDARY_L)) {
      pilot_shootStop( pplayer, 1 );
      player_rmFlag(PLAYER_SECONDARY_L);
   }

   if (fired) {
      player.autonav_timer = MAX( player.autonav_timer, 1. );
      player_autonavResetSpeed();
   }

   pilot_setThrust( pplayer, player_acc );
}


/**
 * @brief Player update function.
 *
 *    @param pplayer Player to update.
 *    @param dt Current delta tick.
 */
void player_update( Pilot *pplayer, const double dt )
{
   /* Update normally. */
   pilot_update( pplayer, dt );

   /* Update player.p specific stuff. */
   if (!player_isFlag(PLAYER_DESTROYED))
      player_updateSpecific( pplayer, dt );
}


/**
 * @brief Does a player specific update.
 *
 *    @param pplayer Player to update.
 *    @param dt Current delta tick.
 */
void player_updateSpecific( Pilot *pplayer, const double dt )
{
   int engsound;

   /* Calculate engine sound to use. */
   if (pilot_isFlag(pplayer, PILOT_AFTERBURNER))
      engsound = pplayer->afterburner->outfit->u.afb.sound;
   else if ((pplayer->solid->thrust > 1e-3) || (pplayer->solid->thrust < -1e-3)) {
      /* See if is in hyperspace. */
      if (pilot_isFlag(pplayer, PILOT_HYPERSPACE))
         engsound = snd_hypEng;
      else
         engsound = pplayer->ship->sound;
   }
   else
      engsound = -1;
   /* See if sound must change. */
   if (player_lastEngineSound != engsound) {
      sound_stopGroup( player_engine_group );
      if (engsound >= 0)
         sound_playGroup( player_engine_group, engsound, 0 );
   }
   player_lastEngineSound = engsound;

   /* See if must play hail sound. */
   if (player_hailCounter > 0) {
      player_hailTimer -= dt;
      if (player_hailTimer < 0.) {
         player_soundPlayGUI( snd_hail, 1 );
         player_hailCounter--;
         player_hailTimer = 3.;
      }
   }
}


/*
 *    For use in keybindings
 */
/**
 * @brief Activates a player's weapon set.
 */
void player_weapSetPress( int id, double value, int repeat )
{
   int type;

   if (player.p == NULL)
      return;

   if (repeat)
      return;

   type = (value >= 0) ? 1 : -1;

   if ((type > 0)
         && (pilot_isFlag(player.p, PILOT_HYP_PREP)
            || pilot_isFlag(player.p, PILOT_HYPERSPACE)
            || pilot_isFlag(player.p, PILOT_LANDING)
            || pilot_isFlag(player.p, PILOT_TAKEOFF)
            || pilot_isFlag(player.p, PILOT_MANUAL_CONTROL)
            || toolkit_isOpen()))
      return;

   pilot_weapSetPress(player.p, id, type);
}


/**
 * @brief Resets the player speed stuff.
 */
void player_resetSpeed (void)
{
   double spd = player.speed;

   if (!player_isFlag(PLAYER_CINEMATICS))
      spd *= player_dt_default();

   pause_setSpeed(spd);
   sound_setSpeed(player.speed);
}


/**
 * @brief Aborts autonav and other states that take control of the ship.
 *
 *    @param reason Reason for aborting (see player.h)
 *    @param str String accompanying the reason.
 */
void player_restoreControl( int reason, const char *str )
{
   if (player.p==NULL)
      return;

   if (reason != PINPUT_AUTONAV) {
      /* Autonav should be harder to abort when paused. */
      if (!paused || reason != PINPUT_MOVEMENT)
         player_autonavAbort(str, 0);
   }

   if (reason != PINPUT_BRAKING) {
      pilot_rmFlag(player.p, PILOT_BRAKING);
      pilot_rmFlag(player.p, PILOT_COOLDOWN_BRAKE);
      if (pilot_isFlag(player.p, PILOT_COOLDOWN)) {
         gui_cooldownEnd();
         pilot_cooldownEnd(player.p, str);
      }
   }
}


/**
 * @brief Sets the player's target planet.
 *
 *    @param id Target planet or -1 if none should be selected.
 *    @param silent Whether to suppress playing a targeting sound.
 */
void player_targetPlanetSet(int id, int silent)
{
   int old;

   if (id >= array_size(cur_system->planets)) {
      WARN(_("Trying to set player's planet target to invalid ID '%d'"), id);
      return;
   }

   if ((player.p == NULL) || pilot_isFlag( player.p, PILOT_LANDING ))
      return;

   old = player.p->nav_planet;
   player.p->nav_planet = id;
   player_hyperspacePreempt((id < 0) ? 1 : 0);
   if (old != id) {
      player_rmFlag(PLAYER_LANDACK);

      /* Prevent weirdness with auto-landing. */
      if (player_isFlag(PLAYER_AUTONAV) && !player_isFlag(PLAYER_BASICAPPROACH)
            && ((player.autonav == AUTONAV_PNT_APPROACH)
               || (player.autonav == AUTONAV_PNT_BRAKE))) {
         player_setFlag(PLAYER_BASICAPPROACH);
         player_message(_("#oAutonav: auto-landing sequence aborted."));
      }

      if (!silent && (id >= 0))
         player_soundPlayGUI(snd_nav, 1);
   }

   gui_forceBlink();
   gui_setNav();
}


/**
 * @brief Sets the player's target asteroid.
 *
 *    @param field Index of the parent field of the asteoid.
 *    @param id Target planet or -1 if none should be selected.
 */
void player_targetAsteroidSet( int field, int id )
{
   int old, i;
   AsteroidAnchor *anchor;
   Asteroid *ast;
   AsteroidType *at;
   Commodity *com;
   char buf[STRMAX];
   size_t l;

   if ((player.p == NULL) || pilot_isFlag( player.p, PILOT_LANDING ))
      return;

   old = player.p->nav_asteroid;
   player.p->nav_asteroid = id;
   if (old != id) {
      if (id >= 0) {
         player_soundPlayGUI(snd_nav, 1);

         /* See if the player has the asteroid scanner. */
         if (player.p->stats.misc_asteroid_scan) {
            /* Recover and display some info about the asteroid. */
            anchor = &cur_system->asteroids[field];
            ast = &anchor->asteroids[id];
            at = space_getType( ast->type );

            if (array_size(at->material) > 0) {
               l = scnprintf(buf, sizeof(buf), "%s",
                     _("Asteroid targeted; composition:"));
               for (i=0; i<array_size(at->material); i++) {
                  com = at->material[i];
                  l += scnprintf(&buf[l], sizeof(buf) - l,
                        n_("\n%s (%d part)", "\n%s (%d parts)",
                           at->quantity[i]),
                        _(com->name), at->quantity[i]);
               }
               player_message("%s", buf);
            }
            else
               player_message(_("Asteroid targeted; composition: empty"));
         }
         else
            player_message(_("Asteroid targeted"));
      }
   }

   player.p->nav_anchor = field;

   /* Untarget pilot. */
   player.p->target = player.p->id;
}


/**
 * @brief Cycle through planet targets.
 *
 *    @param silent Whether to suppress playing a targeting sound.
 */
void player_targetPlanet(int silent)
{
   int id, i;

   /* Not under manual control. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ))
      return;

   /* Find next planet target. */
   for (id=player.p->nav_planet+1; id<array_size(cur_system->planets); id++)
      if (planet_isKnown( cur_system->planets[id] ))
         break;

   /* Try to select the lowest-indexed valid planet. */
   if (id >= array_size(cur_system->planets) ) {
      id = -1;
      for (i=0; i<array_size(cur_system->planets); i++)
         if (planet_isKnown( cur_system->planets[i] )) {
            id = i;
            break;
         }
   }

   /* Untarget if out of range. */
   player_targetPlanetSet(id, silent);
}


/**
 * @brief Check what the result of a land attempt should be.
 *
 * This does not actually cause the player to land, but may select a new
 * planet target if none was selected.
 *
 *    @param loud Whether or not to show messages irrelevant when auto-landing.
 *    @param silent Whether or not to avoid playing targeting sounds.
 *    @return One of PLAYER_LAND_OK, PLAYER_LAND_AGAIN, or PLAYER_LAND_DENIED.
 */
int player_checkLand(int loud, int silent)
{
   int i;
   int temp_nav;
   double temp_dist;
   double d;
   Planet *planet;

   if (landed)
      return PLAYER_LAND_IMPOSSIBLE;

   /* Not under manual control. */
   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL))
      return PLAYER_LAND_IMPOSSIBLE;

   /* Already landing. */
   if (pilot_isFlag(player.p, PILOT_LANDING))
      return PLAYER_LAND_IMPOSSIBLE;

   /* Check if there are planets to land on. */
   if (array_size(cur_system->planets) == 0) {
      if (loud)
         player_messageRaw(_("#rThere are no planets to land on."));
      return PLAYER_LAND_IMPOSSIBLE;
   }

   /* Landing disabled by a script. */
   if (player_isFlag(PLAYER_NOLAND)) {
      if (loud)
         player_message("#r%s", player_message_noland);
      return PLAYER_LAND_IMPOSSIBLE;
   }

   /* Landing disabled by a script. */
   if (pilot_isFlag(player.p, PILOT_NOLAND)) {
      if (loud)
         player_messageRaw(
               _("#rDocking stabilizers malfunctioning: cannot land."));
      return PLAYER_LAND_IMPOSSIBLE;
   }

   /* Can't land while disabled. */
   if (pilot_isDisabled(player.p))
      return PLAYER_LAND_AGAIN;

   /* Still taking off. */
   if (pilot_isFlag(player.p, PILOT_TAKEOFF))
      return PLAYER_LAND_AGAIN;

   if (player.p->nav_planet == -1) { /* get nearest planet target */
      temp_dist = -1;
      temp_nav = -1;
      for (i=0; i<array_size(cur_system->planets); i++) {
         planet = cur_system->planets[i];
         d = vect_dist(&player.p->solid->pos,&planet->pos);
         /* Try to select the nearest planet that the player can simply
          * land on without bribes. If that's not possible, select the
          * closest landable planet (excluding those which have been
          * overrided to blanket deny landing). */
         if (planet_isKnown(planet)
               && planet_hasService(planet, PLANET_SERVICE_LAND)
               && planet->land_override >= 0
               && ((temp_nav == -1) || (temp_dist == -1)
                  || (!cur_system->planets[temp_nav]->can_land
                     && (cur_system->planets[temp_nav]->land_override <= 0)
                     && (planet->can_land || (planet->land_override > 0)
                        || (temp_dist > d)))
                  || ((planet->can_land || (planet->land_override > 0))
                     && (temp_dist > d)))) {
            temp_nav = i;
            temp_dist = d;
         }
      }
      player_targetPlanetSet(temp_nav, silent);
      player_hyperspacePreempt(0);

      /* no landable planet */
      if (player.p->nav_planet < 0) {
         if (loud)
            player_messageRaw(_("#rNo suitable planet to land on found."));
         return PLAYER_LAND_IMPOSSIBLE;
      }

      silent = 1; /* Suppress further targeting noises. */
   }

   /* attempt to land at selected planet */
   planet = cur_system->planets[player.p->nav_planet];
   if (!planet_hasService(planet, PLANET_SERVICE_LAND)) {
      if (loud)
         player_messageRaw(_("#rYou can't land here."));
      return PLAYER_LAND_IMPOSSIBLE;
   }

   /*check if planet is in range*/
   if (!pilot_inRangePlanet(player.p, player.p->nav_planet)) {
      if (loud)
         player_planetOutOfRangeMsg();

      return PLAYER_LAND_AGAIN;
   }

   if (!player_isFlag(PLAYER_LANDACK)) { /* no landing authorization */
      if (planet_hasService(planet,PLANET_SERVICE_INHABITED)) { /* Basic services */
         if (planet->can_land || (planet->land_override > 0))
            player_message("#%c%s>#0 %s", planet_getColourChar(planet),
                  _(planet->name), planet->land_msg);
         else if (planet->bribed && (planet->land_override >= 0))
            player_message("#%c%s>#0 %s", planet_getColourChar(planet),
                  _(planet->name), planet->bribe_ack_msg);
         else { /* Hostile */
            player_message("#%c%s>#0 %s", planet_getColourChar(planet),
                  _(planet->name), planet->land_msg);
            return PLAYER_LAND_DENIED;
         }
      }
      else /* No shoes, no shirt, no lifeforms, no service. */
         player_message(_("#oReady to land on %s."), _(planet->name));

      player_setFlag(PLAYER_LANDACK);
      if (!silent)
         player_soundPlayGUI(snd_nav, 1);

      return player_checkLand(loud, 1);
   }

   if (vect_dist2(&player.p->solid->pos,&planet->pos) > pow2(planet->radius)) {
      if (loud)
         player_message(_("#rYou are too far away to land on %s."), _(planet->name));
      return PLAYER_LAND_AGAIN;
   }

   if ((pow2(VX(player.p->solid->vel)) + pow2(VY(player.p->solid->vel))) >
         (double)pow2(MAX_HYPERSPACE_VEL)) {
      if (loud)
         player_message(_("#rYou are going too fast to land on %s."), _(planet->name));
      return PLAYER_LAND_AGAIN;
   }

   return PLAYER_LAND_OK;
}


/**
 * @brief Try to land or target closest planet if no land target.
 *
 *    @param loud Whether or not to show messages irrelevant when auto-landing.
 *    @param silent Whether or not to avoid playing sounds.
 *    @return One of PLAYER_LAND_OK, PLAYER_LAND_AGAIN, or PLAYER_LAND_DENIED.
 */
int player_land(int loud, int silent)
{
   int ret;

   ret = player_checkLand(loud, silent);
   if (ret != PLAYER_LAND_OK)
      return ret;

   /* End autonav. */
   player_autonavEnd();

   /* Stop afterburning. */
   pilot_afterburnOver(player.p);
   /* Stop accelerating. */
   player_accelOver();

   /* Stop all on outfits. */
   if (pilot_outfitOffAll(player.p) > 0)
      pilot_calcStats(player.p);

   /* Start landing. */
   player_soundPause();
   player.p->landing_delay = PILOT_LANDING_DELAY * player_dt_default();
   player.p->ptimer = player.p->landing_delay;
   pilot_setFlag(player.p, PILOT_LANDING);
   pilot_setThrust(player.p, 0.);
   pilot_setTurn(player.p, 0.);

   return PLAYER_LAND_OK;
}


/**
 * @brief Revokes landing authorization if the player's reputation is too low.
 */
void player_checkLandAck( void )
{
   Planet *p;

   /* No authorization to revoke. */
   if ((player.p == NULL) || !player_isFlag(PLAYER_LANDACK))
      return;

   /* Avoid a potential crash if PLAYER_LANDACK is set inappropriately. */
   if (player.p->nav_planet < 0) {
      WARN(_("Player has landing permission, but no valid planet targeted."));
      return;
   }

   p = cur_system->planets[ player.p->nav_planet ];

   /* Player can still land. */
   if (p->can_land || (p->land_override > 0) || p->bribed)
      return;

   player_rmFlag(PLAYER_LANDACK);
   player_message( _("#%c%s>#0 Landing permission revoked."),
         planet_getColourChar(p), _(p->name) );
}


/**
 * @brief Checks whether the player's ship is able to takeoff.
 */
int player_canTakeoff(void)
{
   return !pilot_reportSpaceworthy(player.p, NULL, 0);
}


/**
 * @brief Sets the no land message.
 *
 *    @brief str Message to set when the player is not allowed to land temporarily.
 */
void player_nolandMsg( const char *str )
{
   free(player_message_noland);

   /* Duplicate so that Lua memory which might be garbage-collected isn't relied on. */
   if (str != NULL)
      player_message_noland = strdup(str);
   else
      player_message_noland = strdup(_("You are not allowed to land at this moment."));
}


/**
 * @brief Sets the player's hyperspace target.
 *
 *    @param id ID of the hyperspace target.
 */
void player_targetHyperspaceSet( int id )
{
   int old;

   if (id >= array_size(cur_system->jumps)) {
      WARN(_("Trying to set player's hyperspace target to invalid ID '%d'"), id);
      return;
   }

   /* If already hyperspacing, changing hyperspace target would cause
    * problems, so don't allow it. */
   if (pilot_isFlag(player.p, PILOT_HYPERSPACE))
      return;

   /* If hyperspace sequence has started and target is changing, we need
    * to make sure the hyperspacing gets aborted so we don't run into
    * problems. */
   if ((pilot_isFlag(player.p, PILOT_HYP_BEGIN)
            || pilot_isFlag(player.p, PILOT_HYP_PREP))
         && (id != player.p->nav_hyperspace)) {
      pilot_hyperspaceAbort(player.p);
   }

   old = player.p->nav_hyperspace;
   player.p->nav_hyperspace = id;
   player_hyperspacePreempt((id < 0) ? 0 : 1);
   if ((old != id) && (id >= 0))
      player_soundPlayGUI(snd_nav,1);
   gui_setNav();
}


/**
 * @brief Gets a hyperspace target.
 */
void player_targetHyperspace (void)
{
   int id, i;

   /* Not under manual control. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ))
      return;

   /* clear the current map path */
   map_selectCur();
   map_clear();

   for (id=player.p->nav_hyperspace+1; id<array_size(cur_system->jumps); id++)
      if (jp_isKnown( &cur_system->jumps[id]))
         break;

   /* Try to find the lowest-indexed valid jump. */
   if (id >= array_size(cur_system->jumps)) {
      id = -1;
      for (i=0; i<array_size(cur_system->jumps); i++)
         if (jp_isUsable( &cur_system->jumps[i])) {
            id = i;
            break;
         }
   }

   player_targetHyperspaceSet( id );

   /* Map gets special treatment if open. */
   if (id == -1)
      map_select( NULL , 0);
   else
      map_select( cur_system->jumps[ id ].target, 0 );
}


/**
 * @brief Enables or disables jump points preempting planets in autoface and target clearing.
 *
 *    @param preempt Boolean; 1 preempts planet target.
 */
void player_hyperspacePreempt( int preempt )
{
   preemption = preempt;
}


/**
 * @brief Returns whether the jump point target should preempt the planet target.
 *
 *    @return Boolean; 1 preempts planet target.
 */
int player_getHypPreempt(void)
{
   return preemption;
}


/**
 * @brief Returns the player's total default time delta based on dt_mod and ship's dt_default.
 *
 *    @return The default/minimum time delta
 */
double player_dt_default(void)
{
   if ((player.p == NULL) || (player.p->ship == NULL))
      return conf.dt_mod;

   return player.p->stats.time_mod * player.p->ship->dt_default * conf.dt_mod;
}


/**
 * @brief Returns the player's maximum time delta during TC.
 *
 *    @return The maximum TC time delta.
 */
double player_dt_max(void)
{
   double max_speed;
   double dt_max;

   if ((player.p == NULL) || (player.p->ship == NULL))
      return conf.dt_mod;

   max_speed = solid_maxspeed(player.p->solid, player.p->speed,
         player.p->thrust);
   dt_max = conf.compression_velocity / max_speed;
   if (conf.compression_mult >= 1.)
      dt_max = MIN(dt_max, conf.compression_mult);

   /* Safe cap. */
   return MAX(player_dt_default(), dt_max);
}


/**
 * @brief Starts the hail sounds and aborts autoNav
 */
void player_hailStart (void)
{
   char buf[128];

   player_hailCounter = 5;

   input_getKeybindDisplay( "autohail", buf, sizeof(buf) );
   player_message( _("#rReceiving hail! Press %s to respond."), buf );

   /* Reset speed. */
   player_autonavResetSpeed();
   player.autonav_timer = MAX( player.autonav_timer, 10. );
}


/**
 * @brief Actually attempts to jump in hyperspace.
 *
 *    @param loud Whether or not to show errors irrelevant to
 *       auto-hyperspace.
 *    @return 1 if actually started a jump, 0 otherwise.
 */
int player_jump(int loud)
{
   int i, j;
   double dist, mindist;

   /* Must have a jump target and not be already jumping. */
   if (pilot_isFlag(player.p, PILOT_HYPERSPACE))
      return 0;

   /* Not under manual control or disabled. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ) ||
         pilot_isDisabled(player.p))
      return 0;

   /* Select nearest jump if not target. */
   if (player.p->nav_hyperspace == -1) {
      j = -1;
      mindist = INFINITY;
      for (i=0; i<array_size(cur_system->jumps); i++) {
         dist = vect_dist2(&player.p->solid->pos, &cur_system->jumps[i].pos);
         if ((dist < mindist) && jp_isUsable(&cur_system->jumps[i])) {
            mindist = dist;
            j = i;
         }
      }
      if (j < 0) {
         if (loud)
            player_messageRaw(_("#rNo known jump point found."));
         return 0;
      }

      player.p->nav_hyperspace = j;
      player_soundPlayGUI(snd_nav,1);
      map_select( cur_system->jumps[player.p->nav_hyperspace].target, 0 );
      gui_setNav();

      /* Only follow through if within range. */
      if (mindist > pow2(cur_system->jumps[j].radius))
         return 0;
   }

   /* Already jumping, so we break jump. */
   if (pilot_isFlag(player.p, PILOT_HYP_PREP)) {
      pilot_hyperspaceAbort(player.p);
      player_message(_("#rAborting hyperspace sequence."));
      return 0;
   }

   /* Try to hyperspace. */
   i = space_hyperspace(player.p);
   if (i == -1){
      if (loud)
         player_message(
            _("#rYou are too far from a jump point to initiate hyperspace."));
   }
   else if (i == -2) {
      if (loud)
         player_message(_("#rHyperspace drive is offline."));
   }
   else if (i == -3) {
      if (loud)
         player_message(_("#rYou do not have enough fuel to hyperspace jump."));
   }
   else {
      player_message(_("#oPreparing for hyperspace."));
      /* Stop acceleration noise. */
      player_accelOver();
      /* Stop possible shooting. */
      pilot_shootStop(player.p, 0);
      pilot_shootStop(player.p, 1);

      return 1;
   }
   return 0;
}

/**
 * @brief Player actually broke hyperspace (entering new system).
 */
void player_brokeHyperspace (void)
{
   ntime_t t;
   StarSystem *sys;
   JumpPoint *jp;
   Pilot * const *pilot_stack;
   int i, map_npath;

   /* First run jump hook. */
   hooks_run( "jumpout" );

   /* Prevent targeted planet # from carrying over. */
   gui_setNav();
   gui_setTarget();
   player_targetPlanetSet(-1, 1);
   player_targetAsteroidSet( -1, -1 );

   /* calculates the time it takes, call before space_init */
   t  = pilot_hyperspaceDelay( player.p );
   ntime_inc( t );

   /* Save old system. */
   sys = cur_system;

   /* Free old graphics. */
   space_gfxUnload( sys );

   /* enter the new system */
   jp = &cur_system->jumps[player.p->nav_hyperspace];
   space_init( jp->target->name );

   /* set position, the pilot_update will handle lowering vel */
   space_calcJumpInPos( cur_system, sys, &player.p->solid->pos, &player.p->solid->vel, &player.p->solid->dir );
   cam_setTargetPilot( player.p->id, 0 );

   /* reduce fuel */
   player.p->fuel -= player.p->fuel_consumption;

   /* stop hyperspace */
   pilot_rmFlag( player.p, PILOT_HYPERSPACE );
   pilot_rmFlag( player.p, PILOT_HYP_BEGIN );
   pilot_rmFlag( player.p, PILOT_HYP_BRAKE );
   pilot_rmFlag( player.p, PILOT_HYP_PREP );

   /* Set the ttimer. */
   player.p->ptimer = HYPERSPACE_FADEIN;

   /* Update the map */
   map_jump();

   /* Add persisted pilots */
   pilot_stack = pilot_getAll();
   for (i=0; i<array_size(pilot_stack); i++) {
      if (pilot_isFlag(pilot_stack[i], PILOT_PERSIST) || pilot_isFlag(pilot_stack[i], PILOT_PLAYER)) {
         if (pilot_stack[i] != player.p) {
            space_calcJumpInPos( cur_system, sys, &pilot_stack[i]->solid->pos, &pilot_stack[i]->solid->vel, &pilot_stack[i]->solid->dir );
            ai_cleartasks(pilot_stack[i]);
         }
      }
   }

   /* Disable autonavigation if arrived. */
   if (player_isFlag(PLAYER_AUTONAV)) {
      if (player.p->nav_hyperspace == -1) {
         player_message( _("#oAutonav arrived at the %s system."), _(cur_system->name) );
         player_autonavEnd();
      }
      else {
         (void)map_getDestination( &map_npath );
         player_message( n_(
                  "#oAutonav continuing until destination (%d jump left).",
                  "#oAutonav continuing until destination (%d jumps left).",
                  map_npath),
               map_npath );
      }
   }

   /* Safe since this is run in the player hook section. */
   hooks_run( "jumpin" );
   hooks_run( "enter" );
   events_trigger( EVENT_TRIGGER_ENTER );
   missions_run( MIS_AVAIL_SPACE, -1, NULL, NULL );

   /* Player sound. */
   player_soundPlay( snd_hypJump, 1 );
}


/**
 * @brief Start accelerating.
 *
 *    @param acc How much thrust should be applied of maximum (0 - 1).
 */
void player_accel( double acc )
{
   if ((player.p == NULL) || pilot_isFlag(player.p, PILOT_HYP_PREP) ||
         pilot_isFlag(player.p, PILOT_HYPERSPACE))
      return;


   player_acc = acc;
   if (toolkit_isOpen() || paused)
      player_soundPause();
}


/**
 * @brief Done accelerating.
 */
void player_accelOver (void)
{
   player_acc = 0.;
}


/**
 * @brief Attempts a local jump for the player.
 */
void player_localJump(void)
{
   /* Must not be under manual control. */
   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL))
      return;

   pilot_localJump(player.p);
}


/**
 * @brief Sets the player's target.
 *
 *    @param id Target to set for the player.
 */
void player_targetSet(pilotId_t id)
{
   pilotId_t old;
   old = player.p->target;
   pilot_setTarget( player.p, id );
   if ((old != id) && (player.p->target != PLAYER_ID)) {
      gui_forceBlink();
      player_soundPlayGUI( snd_target, 1 );
   }
   gui_setTarget();

   /* The player should not continue following if the target pilot has 
    * been changed as doing so would cause the player to start following
    * the new target, usually not what we want. */
   if (player_isFlag(PLAYER_AUTONAV) && player.autonav == AUTONAV_PLT_FOLLOW)
      player_autonavAbort(NULL, 0);
}


/**
 * @brief Targets the nearest hostile enemy to the player.
 *
 * @note This function largely duplicates pilot_getNearestEnemy, because the
 *       player's hostility with AIs is more nuanced than AI vs AI.
 */
void player_targetHostile (void)
{
   pilotId_t tp;
   double d, td;
   int inRange;
   Pilot * const *pilot_stack;

   tp = PLAYER_ID;
   d  = 0;
   pilot_stack = pilot_getAll();
   for (int i=0; i<array_size(pilot_stack); i++) {
      /* Shouldn't be disabled. */
      if (pilot_isDisabled(pilot_stack[i]))
         continue;

      /* Must be a valid target. */
      if (!pilot_validTarget( player.p, pilot_stack[i] ))
         continue;

      /* Must be hostile. */
      if (pilot_isHostile(pilot_stack[i])) {
         inRange = pilot_inRangePilot(player.p, pilot_stack[i], &td);
         if ((inRange == 1) && (tp == PLAYER_ID || (td < d))) {
            d  = td;
            tp = pilot_stack[i]->id;
         }
      }
   }

   player_targetSet( tp );
}


/**
 * @brief Cycles to next target.
 *
 *    @param mode Mode to target. 0 is normal, 1 is hostiles.
 */
void player_targetNext( int mode )
{
   /* Target nearest if nothing is selected. */
   if (player.p->target == PLAYER_ID) {
      if (mode == 1)
         player_targetHostile();
      else
         player_targetNearest();
      return;
   }

   player_targetSet(pilot_getNextID(player.p->target, mode));
}


/**
 * @brief Cycles to previous target.
 *
 *    @param mode Mode to target. 0 is normal, 1 is hostiles.
 */
void player_targetPrev( int mode )
{
   /* Target nearest if nothing is selected. */
   if (player.p->target == PLAYER_ID) {
      if (mode == 1)
         player_targetHostile();
      else
         player_targetNearest();
      return;
   }

   player_targetSet(pilot_getPrevID(player.p->target, mode));
}


/**
 * @brief Clears the player's ship, planet or hyperspace target, in that order.
 */
void player_targetClear (void)
{
   gui_forceBlink();
   if ((player.p->target == PLAYER_ID) && (player.p->nav_asteroid < 0)
         && (player.p->nav_planet < 0)
         && (preemption == 1 || player.p->nav_planet == -1)
         && !pilot_isFlag(player.p, PILOT_HYP_PREP)) {
      player.p->nav_hyperspace = -1;
      player_hyperspacePreempt(0);
      map_selectCur();
      map_clear();
   }
   else if ((player.p->target == PLAYER_ID) && (player.p->nav_asteroid < 0)) {
      player_targetPlanetSet(-1, 0);
   }
   else {
      player_targetSet(PLAYER_ID);
      player_targetAsteroidSet(-1, -1);
   }
   gui_setNav();
}


/**
 * @brief Clears all player targets: hyperspace, planet, asteroid, etc...
 */
void player_targetClearAll (void)
{
   player_targetHyperspaceSet( -1 );
   player_targetPlanetSet(-1, 0);
   player_targetAsteroidSet( -1, -1 );
   player_targetSet( PLAYER_ID );
}


/**
 * @brief Targets the pilot.
 *
 *    @param prev 1 if is cycling backwards.
 */
void player_targetEscort( int prev )
{
   int i;

   /* Check if current target is an escort. */
   for (i=0; i<array_size(player.p->escorts); i++) {
      if (player.p->target == player.p->escorts[i].id) {

         /* Cycle targets. */
         if (prev)
            pilot_setTarget( player.p, (i > 0) ?
                  player.p->escorts[i-1].id : player.p->id );
         else
            pilot_setTarget( player.p, (i < array_size(player.p->escorts)-1) ?
                  player.p->escorts[i+1].id : player.p->id );

         break;
      }
   }

   /* Not found in loop. */
   if (i >= array_size(player.p->escorts)) {
      /* Check to see if he actually has escorts. */
      if (array_size(player.p->escorts) > 0) {
         /* Cycle forward or backwards. */
         if (prev)
            pilot_setTarget( player.p, array_back(player.p->escorts).id );
         else
            pilot_setTarget( player.p, array_front(player.p->escorts).id );
      }
      else
         pilot_setTarget( player.p, player.p->id );
   }


   if (player.p->target != PLAYER_ID) {
      gui_forceBlink();
      player_soundPlayGUI( snd_target, 1 );
   }
   gui_setTarget();
}



/**
 * @brief Player targets nearest pilot.
 */
void player_targetNearest (void)
{
   pilotId_t t, dt;
   double d;

   d = pilot_getNearestPos( player.p, &dt, player.p->solid->pos.x,
         player.p->solid->pos.y, 1 );
   t = dt;

   /* Disabled ships are typically only valid if within 500 px of the player. */
   if ((d > 250000) && (pilot_isDisabled( pilot_get(dt) ))) {
      t = pilot_getNearestPilot(player.p);
      /* Try to target a disabled ship if there are no active ships in range. */
      if (t == PLAYER_ID)
         t = dt;
   }

   player_targetSet( t );
}


static int screenshot_cur = 0; /**< Current screenshot at. */
/**
 * @brief Takes a screenshot.
 */
void player_screenshot (void)
{
   char filename[PATH_MAX];

   if (PHYSFS_mkdir("screenshots") == 0) {
      WARN(_("Aborting screenshot"));
      return;
   }

   /* Try to find current screenshots. */
   for ( ; screenshot_cur < 1000; screenshot_cur++) {
      snprintf( filename, sizeof(filename), "screenshots/screenshot%03d.png", screenshot_cur );
      if (!PHYSFS_exists( filename ))
         break;
   }

   if (screenshot_cur >= 999) { /* in case the crap system breaks :) */
      WARN(_("You have reached the maximum amount of screenshots [999]"));
      return;
   }

   /* now proceed to take the screenshot */
   DEBUG( _("Taking screenshot [%03d]..."), screenshot_cur );
   gl_screenshot(filename);
}


/**
 * @brief Checks to see if player is still being hailed and clears hail counters
 *        if he isn't.
 */
static void player_checkHail (void)
{
   int i;
   Pilot *p;
   Pilot * const *pilot_stack;

   /* See if a pilot is hailing. */
   pilot_stack = pilot_getAll();
   for (i=0; i<array_size(pilot_stack); i++) {
      p = pilot_stack[i];

      /* Must be hailing. */
      if (pilot_isFlag(p, PILOT_HAILING))
         return;
   }

   /* Clear hail timer. */
   player_hailCounter   = 0;
   player_hailTimer     = 0.;
}


/**
 * @brief Displays an out of range message for the player's currently selected planet.
 */
static void player_planetOutOfRangeMsg (void)
{
   player_message( _("#r%s is out of comm range, unable to contact."),
         _(cur_system->planets[player.p->nav_planet]->name) );
}


/**
 * @brief Opens communication with the player's target.
 */
void player_hail (void)
{
   if (player.p->target != player.p->id)
      comm_openPilot(player.p->target);
   else if (player.p->nav_planet != -1) {
      if (pilot_inRangePlanet( player.p, player.p->nav_planet ))
         comm_openPlanet(cur_system->planets[player.p->nav_planet], 0);
      else
         player_planetOutOfRangeMsg();
   }
   else
      player_message(_("#rNo target selected to hail."));

   /* Clear hails if none found. */
   player_checkHail();
}


/**
 * @brief Opens communication with the player's planet target.
 *
 *    @param loud Whether to output messages irrelevant to autonav
 *    @return 1 if actually hailed, 0 if could not contact.
 */
int player_hailPlanet(int loud)
{
   /* Not under manual control. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ))
      return 0;

   if (player.p->nav_planet != -1) {
      if (pilot_inRangePlanet( player.p, player.p->nav_planet ))
         comm_openPlanet(cur_system->planets[player.p->nav_planet], 1);
      else {
         if (loud)
            player_planetOutOfRangeMsg();
         return 0;
      }
   }
   else
      player_message(_("#rNo target selected to hail."));

   return 1;
}


/**
 * @brief Automatically tries to hail a pilot that hailed the player.
 */
void player_autohail (void)
{
   int i;
   Pilot *p;
   Pilot * const *pilot_stack;

   /* Not under manual control or disabled. */
   if (pilot_isFlag( player.p, PILOT_MANUAL_CONTROL ) ||
         pilot_isDisabled(player.p))
      return;

   /* Find pilot to autohail. */
   pilot_stack = pilot_getAll();
   for (i=0; i<array_size(pilot_stack); i++) {
      p = pilot_stack[i];

      /* Must be hailing. */
      if (pilot_isFlag(p, PILOT_HAILING)) {
         /* Try to hail. */
         pilot_setTarget( player.p, p->id );
         gui_setTarget();
         player_hail();

         /* Clear hails if none found. */
         player_checkHail();
         return;
      }
   }

   player_message(_("#rYou haven't been hailed by any pilots."));
}


/**
 * @brief Toggles mouse flying.
 */
void player_toggleMouseFly(void)
{
   if (!player_isFlag(PLAYER_MFLY)) {
      input_mouseShow();
      player_message(_("#oMouse flying enabled."));
      player_setFlag(PLAYER_MFLY);
   }
   else {
      input_mouseHide();
      player_rmFlag(PLAYER_MFLY);
      player_message(_("#rMouse flying disabled."));
   }
}


/**
 * @brief Starts braking or active cooldown.
 */
void player_brake(void)
{
   if (pilot_isFlag(player.p, PILOT_TAKEOFF))
      return;

   /* Not under manual control or disabled. */
   if (pilot_isFlag(player.p, PILOT_MANUAL_CONTROL)
         || pilot_isDisabled(player.p))
      return;

   /* Don't restart cooldown if already started. */
   if (pilot_isFlag(player.p, PILOT_COOLDOWN))
      return;

   /* pilot_cooldown contains logic to autobrake within. */
   pilot_cooldown(player.p);
}


/**
 * @brief Handles mouse flying based on cursor position.
 *
 *    @return 1 if turned to face the mouse, 0 if didn't.
 */
static int player_thinkMouseFly(void)
{
   double px, py, r, x, y;

   px = player.p->solid->pos.x;
   py = player.p->solid->pos.y;
   gl_screenToGameCoords( &x, &y, player.mousex, player.mousey );
   r = sqrt(pow2(x-px) + pow2(y-py));
   if (r > 50.) { /* Ignore mouse input within a 50 px radius of the centre. */
      pilot_face(player.p, atan2( y - py, x - px));
      return 1;
   }
   else
      return 0;
}


/**
 * @brief Player got pwned.
 */
void player_dead (void)
{
   /* Explode at normal speed. */
   pause_setSpeed(1.);
   sound_setSpeed(1.);

   /* Close the overlay. */
   ovr_setOpen(0);
}


/**
 * @brief Player blew up in a fireball.
 */
void player_destroyed (void)
{
   if (player_isFlag(PLAYER_DESTROYED))
      return;

   /* Mark as destroyed. */
   player_setFlag(PLAYER_DESTROYED);

   /* Set timer for death menu. */
   player_timer = 5.;

   /* Stop sounds. */
   player_soundStop();

   /* Stop autonav */
   player_autonavEnd();

   /* Reset time compression when player dies. */
   pause_setSpeed(1.);
   sound_setSpeed(1.);
}


/**
 * @brief PlayerShip_t compare function for qsort().
 */
static int player_shipsCompare( const void *arg1, const void *arg2 )
{
   PlayerShip_t *ps1, *ps2;
   credits_t p1, p2;

   /* Get the arguments. */
   ps1 = (PlayerShip_t*) arg1;
   ps2 = (PlayerShip_t*) arg2;

   /* Get prices. */
   p1 = pilot_worth( ps1->p );
   p2 = pilot_worth( ps2->p );

   /* Compare price INVERSELY */
   if (p1 < p2)
      return +1;
   else if (p1 > p2)
      return -1;

   /* In case of tie sort by name so they don't flip or something. */
   return strcmp( ps1->p->name, ps2->p->name );
}


/**
 * @brief Sorts the players ships.
 */
void player_shipsSort (void)
{
   if (array_size(player_stack) == 0)
      return;

   /* Sort. */
   qsort( player_stack, array_size(player_stack), sizeof(PlayerShip_t), player_shipsCompare );
}


/**
 * @brief Returns a buffer with all the player's ships names.
 *
 *    @param sships Fills sships with player_nships ship names.
 *    @param tships Fills sships with player_nships ship target textures.
 *    @return Freshly allocated array with allocated ship names.
 *    @return The number of ships the player has.
 */
int player_ships( char** sships, glTexture** tships )
{
   int i;

   /* Sort. */
   player_shipsSort();

   /* Create the struct. */
   for (i=0; i < array_size(player_stack); i++) {
      sships[i] = strdup(player_stack[i].p->name);
      tships[i] = player_stack[i].p->ship->gfx_store;
   }

   return array_size(player_stack);
}


/**
 * @brief Gets the array (array.h) of the player's ships.
 */
const PlayerShip_t* player_getShipStack (void)
{
   return player_stack;
}


/**
 * @brief Gets the amount of ships player has in storage.
 *
 *    @return The number of ships the player has.
 */
int player_nships (void)
{
   return array_size(player_stack);
}


/**
 * @brief Sees if player has a ship of a name.
 *
 *    @param shipname Nome of the ship to get.
 *    @return 1 if ship exists.
 */
int player_hasShip( const char *shipname )
{
   int i;

   /* Check current ship. */
   if ((player.p != NULL) && (strcmp(player.p->name,shipname)==0))
      return 1;

   /* Check stocked ships. */
   for (i=0; i < array_size(player_stack); i++)
      if (strcmp(player_stack[i].p->name, shipname)==0)
         return 1;
   return 0;
}


/**
 * @brief Gets a specific ship.
 *
 *    @param shipname Nome of the ship to get.
 *    @return The ship matching name.
 */
Pilot *player_getShip( const char *shipname )
{
   int i;

   if ((player.p != NULL) && (strcmp(shipname,player.p->name)==0))
      return player.p;

   for (i=0; i < array_size(player_stack); i++)
      if (strcmp(player_stack[i].p->name, shipname)==0)
         return player_stack[i].p;

   WARN(_("Player ship '%s' not found in stack"), shipname);
   return NULL;
}


/**
 * @brief Gets how many of the outfit the player owns.
 *
 *    @param o Outfit to check how many the player owns.
 *    @return The number of outfits matching outfitname owned.
 */
int player_outfitOwned( const Outfit* o )
{
   int i;

   /* Special case map. */
   if ((outfit_isMap(o) && map_isUseless(o)) ||
         (outfit_isLocalMap(o) && localmap_isUseless()))
      return 1;

   /* Special case license. */
   if (outfit_isLicense(o) &&
         player_hasLicense(o->name))
      return 1;

   /* Try to find it. */
   for (i=0; i<array_size(player_outfits); i++)
      if (player_outfits[i].o == o)
         return player_outfits[i].q;

   return 0;
}


/**
 * Total number of an outfit owned by the player (including equipped).
 */
int player_outfitOwnedTotal( const Outfit* o )
{
   int i, q;

   q  = player_outfitOwned(o);

   q += pilot_numOutfit( player.p, o );
   for (i=0; i<array_size(player_stack); i++)
      q += pilot_numOutfit( player_stack[i].p, o );

   return q;
}


/**
 * @brief qsort() compare function for PlayerOutfit_t sorting.
 */
static int player_outfitCompare( const void *arg1, const void *arg2 )
{
   PlayerOutfit_t *po1, *po2;

   /* Get type. */
   po1 = (PlayerOutfit_t*) arg1;
   po2 = (PlayerOutfit_t*) arg2;

   /* Compare. */
   return outfit_compareTech( &po1->o, &po2->o );
}


/**
 * @brief Gets an array (array.h) of the player's outfits.
 */
const PlayerOutfit_t* player_getOutfits (void)
{
   return player_outfits;
}


/**
 * @brief Prepares two arrays for displaying in an image array.
 *
 *    @param[out] outfits Outfits the player owns.
 *    @param[in] filter Function to filter which outfits to get.
 *    @param[in] name Name fragment that each outfit must contain.
 *    @return Number of outfits.
 */
int player_getOutfitsFiltered( const Outfit **outfits,
      int(*filter)( const Outfit *o ), char *name )
{
   int i;

   if (array_size(player_outfits) == 0)
      return 0;

   /* We'll sort. */
   qsort( player_outfits, array_size(player_outfits),
         sizeof(PlayerOutfit_t), player_outfitCompare );

   for (i=0; i<array_size(player_outfits); i++)
      outfits[i] = (Outfit*)player_outfits[i].o;

   return outfits_filter( outfits, array_size(player_outfits), filter, name );
}


/**
 * @brief Gets the amount of different outfits in the player outfit stack.
 *
 *    @return Amount of different outfits.
 */
int player_numOutfits (void)
{
   return array_size(player_outfits);
}


/**
 * @brief Adds an outfit to the player outfit stack.
 *
 *    @param o Outfit to add.
 *    @param quantity Amount to add.
 *    @return Amount added.
 */
int player_addOutfit( const Outfit *o, int quantity )
{
   int i;
   PlayerOutfit_t *po;

   /* Validity check. */
   if (quantity == 0)
      return 0;

   /* Don't readd uniques. */
   if (outfit_isProp(o,OUTFIT_PROP_UNIQUE) && (player_outfitOwned(o)>0))
      return 0;

   /* special case if it's a map */
   if (outfit_isMap(o)) {
      map_map(o);
      return 1; /* Success. */
   }
   else if (outfit_isLocalMap(o)) {
      localmap_map();
      return 1;
   }
   /* special case if it's a license. */
   else if (outfit_isLicense(o)) {
      player_addLicense(o->name);
      return 1; /* Success. */
   }

   /* Try to find it. */
   for (i=0; i<array_size(player_outfits); i++) {
      if (player_outfits[i].o == o) {
         player_outfits[i].q  += quantity;
         return quantity;
      }
   }

   /* Allocate if needed. */
   po = &array_grow( &player_outfits );

   /* Add the outfit. */
   po->o = o;
   po->q = quantity;
   return quantity;
}


/**
 * @brief Remove an outfit from the player's outfit stack.
 *
 *    @param o Outfit to remove.
 *    @param quantity Amount to remove.
 *    @return Amount removed.
 */
int player_rmOutfit( const Outfit *o, int quantity )
{
   int i, q;

   /* Try to find it. */
   for (i=0; i<array_size(player_outfits); i++) {
      if (player_outfits[i].o == o) {
         /* See how many to remove. */
         q = MIN( player_outfits[i].q, quantity );
         player_outfits[i].q -= q;

         /* See if must remove element. */
         if (player_outfits[i].q <= 0)
            array_erase( &player_outfits, &player_outfits[i], &player_outfits[i+1] );

         /* Return removed outfits. */
         return q;
      }
   }

   /* Nothing removed. */
   return 0;
}


/**
 * @brief Marks a mission as completed.
 *
 *    @param id ID of the mission to mark as completed.
 */
void player_missionFinished( int id )
{
   /* Make sure not already marked. */
   if (player_missionAlreadyDone(id))
      return;

   /* Mark as done. */
   if (missions_done == NULL)
      missions_done = array_create( int );
   array_push_back( &missions_done, id );
}


/**
 * @brief Checks to see if player has already completed a mission.
 *
 *    @param id ID of the mission to see if player has completed.
 *    @return 1 if player has completed the mission, 0 otherwise.
 */
int player_missionAlreadyDone( int id )
{
   int i;
   for (i=0; i<array_size(missions_done); i++)
      if (missions_done[i] == id)
         return 1;
   return 0;
}


/**
 * @brief Marks a event as completed.
 *
 *    @param id ID of the event to mark as completed.
 */
void player_eventFinished( int id )
{
   /* Make sure not already done. */
   if (player_eventAlreadyDone(id))
      return;

   /* Mark as done. */
   if (events_done == NULL)
      events_done = array_create( int );
   array_push_back( &events_done, id );
}


/**
 * @brief Checks to see if player has already completed a event.
 *
 *    @param id ID of the event to see if player has completed.
 *    @return 1 if player has completed the event, 0 otherwise.
 */
int player_eventAlreadyDone( int id )
{
   int i;
   for (i=0; i<array_size(events_done); i++)
      if (events_done[i] == id)
         return 1;
   return 0;
}


/**
 * @brief Checks to see if player has license.
 *
 *    @param license License to check to see if the player has.
 *    @return 1 if has license (or none needed), 0 if doesn't.
 */
int player_hasLicense(const char *license)
{
   int i;
   if (license == NULL)
      return 1;

   for (i=0; i<array_size(player_licenses); i++)
      if (strcmp(license, player_licenses[i])==0)
         return 1;

   return 0;
}


/**
 * @brief Gives the player a license.
 *
 *    @brief license License to give the player.
 */
void player_addLicense(const char *license)
{
   if (player_hasLicense(license))
      return;
   if (player_licenses == NULL)
      player_licenses = array_create( char* );
   array_push_back( &player_licenses, strdup(license) );
}


/**
 * @brief Gets the array (array.h) of license names in the player's inventory.
 */
char **player_getLicenses ()
{
   return player_licenses;
}


/**
 * @brief Runs hooks for the player.
 */
void player_runHooks (void)
{
   /* Player must exist. */
   if (player.p == NULL)
      return;

   if (player_isFlag( PLAYER_HOOK_HYPER )) {
      player_brokeHyperspace();
      player_rmFlag( PLAYER_HOOK_HYPER );
   }
   if (player_isFlag( PLAYER_HOOK_JUMPIN)) {
      hooks_run( "jumpin" );
      hooks_run( "enter" );
      events_trigger( EVENT_TRIGGER_ENTER );
      missions_run( MIS_AVAIL_SPACE, -1, NULL, NULL );
      player_rmFlag( PLAYER_HOOK_JUMPIN );
   }
   if (player_isFlag( PLAYER_HOOK_LAND )) {
      if (player.p->nav_planet >= 0)
         land(cur_system->planets[player.p->nav_planet], 0);
      player_rmFlag( PLAYER_HOOK_LAND );
   }
}


/**
 * @brief Clears escorts to make sure deployment is safe.
 */
static void player_clearEscorts (void)
{
   int i;

   for (i=0; i<array_size(player.p->outfits); i++) {
      if (player.p->outfits[i]->outfit == NULL)
         continue;

      if (outfit_isFighterBay(player.p->outfits[i]->outfit))
         player.p->outfits[i]->u.ammo.deployed = 0;
   }
}


/**
 * @brief Adds the player's escorts.
 *
 *    @return 0 on success.
 */
int player_addEscorts (void)
{
   int i, j;
   double a;
   Vector2d v;
   pilotId_t e;
   Outfit *o;
   int q;
   int dockslot = -1;

   /* Clear escorts first. */
   player_clearEscorts();

   for (i=0; i<array_size(player.p->escorts); i++) {
      if (!player.p->escorts[i].persist) {
         escort_rmListIndex(player.p, i);
         i--;
         continue;
      }

      a = RNGF() * 2 * M_PI;
      vect_cset( &v, player.p->solid->pos.x + 50.*cos(a),
            player.p->solid->pos.y + 50.*sin(a) );

      /* Update outfit if needed. */
      if (player.p->escorts[i].type != ESCORT_TYPE_BAY)
         continue;

      for (j=0; j<array_size(player.p->outfits); j++) {
         /* Must have outfit. */
         if (player.p->outfits[j]->outfit == NULL)
            continue;

         /* Must be fighter bay. */
         if (!outfit_isFighterBay(player.p->outfits[j]->outfit))
            continue;

         /* Ship must match. */
         o = outfit_ammo(player.p->outfits[j]->outfit);
         if (!outfit_isFighter(o) ||
               (strcmp(player.p->escorts[i].ship,o->u.fig.ship)!=0))
            continue;

         /* Must not have all deployed. */
         q = player.p->outfits[j]->u.ammo.deployed + player.p->outfits[j]->u.ammo.quantity;
         if (q >= pilot_maxAmmoO(player.p, player.p->outfits[j]->outfit))
            continue;

         dockslot = j;
         break;
      }

      if (dockslot == -1)
         DEBUG(_("Escort is undeployed"));

      /* Create escort. */
      e = escort_create( player.p, player.p->escorts[i].ship,
            &v, &player.p->solid->vel, player.p->solid->dir,
            player.p->escorts[i].type, 0, dockslot );
      player.p->escorts[i].id = e; /* Important to update ID. */
   }

   return 0;
}


/**
 * @brief Saves the player's escorts.
 */
static int player_saveEscorts( xmlTextWriterPtr writer )
{
   int i;

   for (i=0; i<array_size(player.p->escorts); i++) {
      if (player.p->escorts[i].persist) {
         xmlw_startElem(writer, "escort");
         xmlw_attr(writer,"type","bay"); /**< @todo other types. */
         xmlw_str(writer, "%s", player.p->escorts[i].ship);
         xmlw_endElem(writer); /* "escort" */
      }
   }

   return 0;
}


/**
 * @brief Save the freaking player in a freaking xmlfile.
 *
 *    @param writer xml Writer to use.
 *    @return 0 on success.
 */
int player_save( xmlTextWriterPtr writer )
{
   char **guis;
   int i;
   MissionData *m;
   const char *ev;
   int years, days, seconds;
   double rem;

   xmlw_startElem(writer,"player");

   /* Standard player details. */
   xmlw_attr(writer,"name","%s",player.name);
   xmlw_elem(writer,"credits","%"CREDITS_PRI,player.p->credits);
   if (player.gui != NULL)
      xmlw_elem(writer,"gui","%s",player.gui);
   xmlw_elem(writer,"guiOverride","%d",player.guiOverride);
   xmlw_elem(writer,"mapOverlay","%d",ovr_isOpen());
   gui_radarGetRes( &player.radar_res );
   xmlw_elem(writer,"radar_res","%f",player.radar_res);

   /* Time. */
   xmlw_startElem(writer,"time");
   ntime_getR(&years, &days, &seconds, &rem);
   xmlw_elem(writer, "years", "%d", years);
   xmlw_elem(writer, "days", "%d", days);
   xmlw_elem(writer, "seconds", "%d", seconds);
   xmlw_elem(writer, "Remainder", "%lf", rem);
   xmlw_endElem(writer); /* "time" */

   /* Current ship. */
   xmlw_elem(writer, "location", "%s", land_planet->name);
   if (planet_hasSystem(land_planet->name))
      xmlw_elem(writer, "location_system", "%s",
            planet_getSystem(land_planet->name));
   player_saveShip( writer, player.p ); /* current ship */

   /* Ships. */
   xmlw_startElem(writer,"ships");
   for (i=0; i<array_size(player_stack); i++)
      player_saveShip( writer, player_stack[i].p );
   xmlw_endElem(writer); /* "ships" */

   /* GUIs. */
   xmlw_startElem(writer,"guis");
   guis = player_guiList();
   for (i=0; i<array_size(guis); i++)
      xmlw_elem(writer,"gui","%s",guis[i]);
   xmlw_endElem(writer); /* "guis" */

   /* Outfits. */
   xmlw_startElem(writer,"outfits");
   for (i=0; i<array_size(player_outfits); i++) {
      xmlw_startElem(writer, "outfit");
      xmlw_attr(writer, "quantity", "%d", player_outfits[i].q);
      xmlw_str(writer, "%s", player_outfits[i].o->name);
      xmlw_endElem(writer); /* "outfit" */
   }
   xmlw_endElem(writer); /* "outfits" */

   /* Licenses. */
   xmlw_startElem(writer, "licenses");
   for (i=0; i<array_size(player_licenses); i++)
      xmlw_elem(writer, "license", "%s", player_licenses[i]);
   xmlw_endElem(writer); /* "licenses" */

   xmlw_endElem(writer); /* "player" */

   /* Mission the player has done. */
   xmlw_startElem(writer,"missions_done");
   for (i=0; i<array_size(missions_done); i++) {
      m = mission_get(missions_done[i]);
      if (m != NULL) /* In case mission name changes between versions */
         xmlw_elem(writer, "done", "%s", m->name);
   }
   xmlw_endElem(writer); /* "missions_done" */

   /* Events the player has done. */
   xmlw_startElem(writer, "events_done");
   for (i=0; i<array_size(events_done); i++) {
      ev = event_dataName(events_done[i]);
      if (ev != NULL) /* In case mission name changes between versions */
         xmlw_elem(writer, "done", "%s", ev);
   }
   xmlw_endElem(writer); /* "events_done" */

   /* Escorts. */
   xmlw_startElem(writer, "escorts");
   player_saveEscorts(writer);
   xmlw_endElem(writer); /* "escorts" */

   /* Metadata. */
   xmlw_startElem(writer,"metadata");
   player_saveMetadata( writer );
   xmlw_endElem(writer); /* "metadata" */

   return 0;
}

/**
 * @brief Saves an outfit slot.
 */
static int player_saveShipSlot( xmlTextWriterPtr writer, PilotOutfitSlot *slot, int i )
{
   const Outfit *o;
   o = slot->outfit;
   xmlw_startElem(writer,"outfit");
   xmlw_attr(writer,"slot","%d",i);
   if ((outfit_ammo(o) != NULL) &&
         (slot->u.ammo.outfit != NULL)) {
      xmlw_attr(writer,"ammo","%s",slot->u.ammo.outfit->name);
      xmlw_attr(writer,"quantity","%d", slot->u.ammo.quantity);
   }
   xmlw_str(writer,"%s",o->name);
   xmlw_endElem(writer); /* "outfit" */

   return 0;
}


/**
 * @brief Saves a ship.
 *
 *    @param writer XML writer.
 *    @param ship Ship to save.
 *    @return 0 on success.
 */
static int player_saveShip( xmlTextWriterPtr writer, Pilot* ship )
{
   int i, j, k;
   int found;
   const char *name;
   PilotWeaponSetOutfit *weaps;

   xmlw_startElem(writer,"ship");
   xmlw_attr(writer,"name","%s",ship->name);
   xmlw_attr(writer,"model","%s",ship->ship->name);

   /* save the fuel */
   xmlw_elem(writer, "fuel", "%f", ship->fuel);

   /* save the outfits */
   xmlw_startElem(writer,"outfits_structure");
   for (i=0; i<array_size(ship->outfit_structure); i++) {
      if (ship->outfit_structure[i].outfit==NULL)
         continue;
      player_saveShipSlot( writer, &ship->outfit_structure[i], i );
   }
   xmlw_endElem(writer); /* "outfits_structure" */
   xmlw_startElem(writer,"outfits_utility");
   for (i=0; i<array_size(ship->outfit_utility); i++) {
      if (ship->outfit_utility[i].outfit==NULL)
         continue;
      player_saveShipSlot( writer, &ship->outfit_utility[i], i );
   }
   xmlw_endElem(writer); /* "outfits_utility" */
   xmlw_startElem(writer,"outfits_weapon");
   for (i=0; i<array_size(ship->outfit_weapon); i++) {
      if (ship->outfit_weapon[i].outfit==NULL)
         continue;
      player_saveShipSlot( writer, &ship->outfit_weapon[i], i );
   }
   xmlw_endElem(writer); /* "outfits_weapon" */

   /* save the commodities */
   xmlw_startElem(writer,"commodities");
   for (i=0; i<array_size(ship->commodities); i++) {
      /* Remove cargo with id and no mission. */
      if (ship->commodities[i].id > 0) {
         found = 0;
         for (j=0; j<MISSION_MAX; j++) {
            /* Only check active missions. */
            if (player_missions[j]->id > 0) {
               /* Now check if it's in the cargo list. */
               for (k=0; k<array_size(player_missions[j]->cargo); k++) {
                  /* See if it matches a cargo. */
                  if (player_missions[j]->cargo[k] == ship->commodities[i].id) {
                     found = 1;
                     break;
                  }
               }
            }
            if (found)
               break;
         }

         if (!found) {
            WARN(_("Found mission cargo without associated mission."));
            WARN(_("Please reload save game to remove the dead cargo."));
            continue;
         }
      }

      xmlw_startElem(writer,"commodity");

      xmlw_attr(writer,"quantity","%d",ship->commodities[i].quantity);
      if (ship->commodities[i].id > 0)
         xmlw_attr(writer,"id","%d",ship->commodities[i].id);
      xmlw_str(writer,"%s",ship->commodities[i].commodity->name);

      xmlw_endElem(writer); /* commodity */
   }
   xmlw_endElem(writer); /* "commodities" */

   xmlw_startElem(writer, "weaponsets");
   xmlw_attr(writer, "autoweap", "%d", ship->autoweap);
   xmlw_attr(writer, "active_set", "%d", ship->active_set);
   xmlw_attr(writer, "aim_lines", "%d", ship->aimLines);
   for (i=0; i<PILOT_WEAPON_SETS; i++) {
      weaps = pilot_weapSetList( ship, i );
      xmlw_startElem(writer,"weaponset");
      /* Inrange isn't handled by autoweap for the player. */
      xmlw_attr(writer,"inrange","%d",pilot_weapSetInrangeCheck(ship,i));
      xmlw_attr(writer,"id","%d",i);
      if (!ship->autoweap) {
         name = pilot_weapSetName(ship,i);
         if (name != NULL)
            xmlw_attr(writer,"name","%s",name);
         xmlw_attr(writer,"type","%d",pilot_weapSetTypeCheck(ship,i));
         for (j=0; j<array_size(weaps); j++) {
            xmlw_startElem(writer,"weapon");
            xmlw_attr(writer,"level","%d",weaps[j].level);
            xmlw_str(writer,"%d",weaps[j].slot->id);
            xmlw_endElem(writer); /* "weapon" */
         }
      }
      xmlw_endElem(writer); /* "weaponset" */
   }
   xmlw_endElem(writer); /* "weaponsets" */

   xmlw_endElem(writer); /* "ship" */

   return 0;
}


/**
 * @brief Saves the player meta-data.
 *
 *    @param writer XML writer.
 *    @return 0 on success.
 */
static int player_saveMetadata( xmlTextWriterPtr writer )
{
   time_t t = time(NULL);

   /* Compute elapsed time. */
   player.time_played += difftime( t, player.time_since_save );
   player.time_since_save = t;

   /* Save the stuff. */
   xmlw_saveTime(writer, "last_played", time(NULL));
   xmlw_saveTime(writer, "date_created", player.date_created);
   xmlw_saveTime(writer, "time_played", player.time_played);

   /* Damage stuff. */
   xmlw_elem(writer, "dmg_done_shield", "%f", player.dmg_done_shield);
   xmlw_elem(writer, "dmg_done_armour", "%f", player.dmg_done_armour);
   xmlw_elem(writer, "dmg_taken_shield", "%f", player.dmg_taken_shield);
   xmlw_elem(writer, "dmg_taken_armour", "%f", player.dmg_taken_armour);

   /* Ships destroyed. */
   xmlw_elem(writer, "ships_destroyed", "%u", player.ships_destroyed);

   return 0;
}


/**
 * @brief Loads the player stuff.
 *
 *    @param parent Node where the player stuff is to be found.
 *    @return 0 on success.
 */
Planet* player_load( xmlNodePtr parent )
{
   xmlNodePtr node;
   Planet *pnt;

   /* some cleaning up */
   memset(&player, 0, sizeof(Player_t));
   player.speed = 1.;
   pnt = NULL;
   map_cleanup();

   /* Reasonable time defaults. */
   player.last_played = time(NULL);
   player.date_created = player.last_played;
   player.time_since_save = player.last_played;

   if (player_stack==NULL)
      player_stack = array_create( PlayerShip_t );
   if (player_outfits==NULL)
      player_outfits = array_create( PlayerOutfit_t );

   node = parent->xmlChildrenNode;
   do {
      if (xml_isNode(node,"metadata"))
         player_parseMetadata(node);
      else if (xml_isNode(node,"player"))
         pnt = player_parse( node );
      else if (xml_isNode(node,"missions_done"))
         player_parseDoneMissions( node );
      else if (xml_isNode(node,"events_done"))
         player_parseDoneEvents( node );
      else if (xml_isNode(node,"escorts"))
         player_parseEscorts(node);
   } while (xml_nextNode(node));

   /* Set up meta-data. */
   player.time_since_save = time(NULL);

   return pnt;
}


/**
 * @brief Runs the save updater script, leaving any result on the stack of naevL.
 *
 *    @param type Type of item to translate (corresponds to a function
 *       in save_updater.lua).
 *    @param name Name of the inventory item.
 *    @param q Quantity in possession.
 *    @return Stack depth: 1 if player got a translated item back, 0 if
 *       they got nothing or just money.
 */
static int player_runUpdaterScript(const char* type, const char* name, int q)
{
   static nlua_env player_updater_env = LUA_NOREF;

   player_ran_updater = 1;

   /* Load env if necessary. */
   if (player_updater_env == LUA_NOREF) {
      player_updater_env = nlua_newEnv(0);
      size_t bufsize;
      char *buf = ndata_read(SAVE_UPDATER_PATH, &bufsize);
      if (nlua_dobufenv(player_updater_env, buf, bufsize, SAVE_UPDATER_PATH) != 0) {
         WARN( _("Error loading file: %s\n"
            "%s\n"
            "Most likely Lua file has improper syntax, please check"),
               SAVE_UPDATER_PATH, lua_tostring(naevL, -1));
         free(buf);
         return 0;
      }
      free(buf);
   }

   /* Try to find out equivalent. */
   nlua_getenv(player_updater_env, type);
   lua_pushstring(naevL, name);
   if (nlua_pcall(player_updater_env, 1, 1)) {
      /* error has occurred */
      WARN(_("Updater (%s): '%s'"), type, lua_tostring(naevL, -1));
      lua_pop(naevL, 1);
      return 0;
   }
   if (lua_type(naevL, -1) == LUA_TNUMBER) {
      player_payback += q * round(lua_tonumber(naevL, -1));
      lua_pop(naevL, 1);
      return 0;
   }

   return 1;
}


/**
 * @brief Tries to get an outfit for the player or looks for equivalents.
 */
static const Outfit* player_tryGetOutfit(const char *name, int q)
{
   const Outfit *o = outfit_getW(name);

   /* Outfit was found normally. */
   if (o != NULL)
      return o;
   player_ran_updater = 1;

   /* Try to find out equivalent. */
   if (player_runUpdaterScript("outfit", name, q) == 0)
      return NULL;
   else if (lua_type(naevL, -1) == LUA_TSTRING)
      o = outfit_get(lua_tostring(naevL, -1));
   else if (lua_isoutfit(naevL, -1))
      o = lua_tooutfit(naevL, -1);
   else
      WARN(_("Outfit '%s' in player save not found!"), name);

   lua_pop(naevL, 1);

   return o;
}


/**
 * @brief Tries to get an ship for the player or looks for equivalents.
 */
static const Ship* player_tryGetShip(const char *name)
{
   const Ship *s = ship_getW(name);

   /* Ship was found normally. */
   if (s != NULL)
      return s;
   player_ran_updater = 1;

   /* Try to find out equivalent. */
   if (player_runUpdaterScript("ship", name, 1) == 0)
      return NULL;
   else if (lua_type(naevL, -1) == LUA_TSTRING)
      s = ship_get( lua_tostring(naevL, -1) );
   else if (lua_isship(naevL, -1))
      s = lua_toship(naevL, -1);
   else
      WARN(_("Ship '%s' in player save not found!"), name);

   lua_pop(naevL, 1);

   return s;
}


/**
 * @brief Parses the player node.
 *
 *    @param parent The player node.
 *    @return Planet to start on on success.
 */
static Planet* player_parse( xmlNodePtr parent )
{
   char *planet, *found;
   unsigned int services;
   Planet *pnt;
   xmlNodePtr node, cur;
   int q;
   const char *oname;
   const Outfit *o;
   int i, map_overlay_enabled;
   StarSystem *sys;
   double a, r;
   Pilot *old_ship;
   PilotFlags flags;
   int years, days, seconds, time_set;
   int cycles, periods, stu;
   double rem;

   xmlr_attr_strd(parent, "name", player.name);
   player_ran_updater = 0;

   /* Make sure player.p is NULL. */
   player.p = NULL;
   pnt = NULL;

   /* Safe defaults. */
   planet      = NULL;
   time_set    = 0;
   map_overlay_enabled = 0;

   player.radar_res = RADAR_RES_DEFAULT;

   /* Must get planet first. */
   node = parent->xmlChildrenNode;
   do {
      xmlr_str(node,"location",planet);
   } while (xml_nextNode(node));

   /* Parse rest. */
   node = parent->xmlChildrenNode;
   do {

      /* global stuff */
      xmlr_ulong(node, "credits", player_creds);
      xmlr_strd(node, "gui", player.gui);
      xmlr_int(node, "guiOverride", player.guiOverride);
      xmlr_int(node, "mapOverlay", map_overlay_enabled);
      ovr_setOpen(map_overlay_enabled);
      xmlr_float(node, "radar_res", player.radar_res);

      /* Time. */
      if (xml_isNode(node,"time")) {
         cur = node->xmlChildrenNode;
         years = days = seconds = -1;
         cycles = periods = stu = -1;
         rem = -1.;
         do {
            /* Compatibility for old saves. */
            xmlr_int(cur, "SCU", cycles);
            xmlr_int(cur, "STP", periods);
            xmlr_int(cur, "STU", stu);
            /* Modern save data. */
            xmlr_int(cur, "years", years);
            xmlr_int(cur, "days", days);
            xmlr_int(cur, "seconds", seconds);
            xmlr_float(cur, "Remainder", rem);
         } while (xml_nextNode(cur));

         /* Use the old format data if and only if the new format
          * data is unavailable. */
         if (years == -1)
            years = cycles;
         if (days == -1)
            days = periods / NT_DAY_HOURS;
         if (seconds == -1)
            seconds = stu;

         if ((years < 0) || (days < 0) || (seconds < 0) || (rem < 0.))
            WARN(_("Malformed time in save game!"));

         ntime_setR(years, days, seconds, rem);
         if ((years >= 0) || (days >= 0) || (seconds >= 0))
            time_set = 1;
      }

      if (xml_isNode(node, "ship"))
         player_parseShip(node, 1);

      /* Parse ships. */
      else if (xml_isNode(node,"ships")) {
         cur = node->xmlChildrenNode;
         do {
            if (xml_isNode(cur,"ship"))
               player_parseShip(cur, 0);
         } while (xml_nextNode(cur));
      }

      /* Parse outfits. */
      else if (xml_isNode(node,"outfits")) {
         cur = node->xmlChildrenNode;
         do {
            if (xml_isNode(cur,"outfit")) {
               oname = xml_get(cur);
               if (oname == NULL) {
                  WARN(_("Outfit was saved without name, skipping."));
                  continue;
               }

               xmlr_attr_float(cur, "quantity", q);
               if (q == 0) {
                  WARN(_("Outfit '%s' was saved without quantity!"), oname);
                  continue;
               }

               o = player_tryGetOutfit(oname, q);
               if (o == NULL)
                  continue;

               player_addOutfit(o, q);
            }
         } while (xml_nextNode(cur));
      }

      /* Parse licenses. */
      else if (xml_isNode(node,"licenses"))
         player_parseLicenses(node);

   } while (xml_nextNode(node));

   /* Handle cases where ship is missing. */
   if (player.p == NULL) {
      pilot_clearFlagsRaw( flags );
      pilot_setFlagRaw( flags, PILOT_PLAYER );
      pilot_setFlagRaw( flags, PILOT_NO_OUTFITS );
      WARN(_("Player ship does not exist!"));

      if (array_size(player_stack) == 0) {
         WARN(_("Player has no other ships, giving starting ship."));
         pilot_create( ship_get(start_ship()), "MIA",
               faction_get("Player"), "player", 0., NULL, NULL, flags, 0, 0 );
      }
      else {

         /* Just give player.p a random ship in the stack. */
         old_ship = player_stack[array_size(player_stack)-1].p;
         pilot_create( old_ship->ship, old_ship->name,
               faction_get("Player"), "player", 0., NULL, NULL, flags, 0, 0 );
         player_rmShip( old_ship->name );
         WARN(_("Giving player ship '%s'."), player.p->name );
      }
   }

   /* Check. */
   if (player.p == NULL) {
      ERR(_("Something went horribly wrong, player does not exist after load..."));
      return NULL;
   }

   /* Reset player speed */
   player.speed = 1.;

   /* set global thingies */
   player.p->credits = player_creds + player_payback;
   if (!time_set) {
      WARN(_("Save has no time information, setting to start information."));
      ntime_set( start_date() );
   }

   /* Updater message. */
   if (player_ran_updater) {
      DEBUG(_("Player save was updated."));
   }

   /* set player in system */
   pnt = planet_get( planet );
   /* Get random planet if it's NULL. */
   if ((pnt == NULL) || (planet_getSystem(planet) == NULL) ||
         !planet_hasService(pnt, PLANET_SERVICE_LAND)) {
      WARN(_("Player starts out in non-existent or invalid planet '%s',"
            "trying to find a suitable one instead."),
            planet );

      /* Find a landable, inhabited planet that's in a system, offers refueling
       * and meets the following additional criteria:
       *
       *    0: Shipyard, outfitter, non-hostile
       *    1: Outfitter, non-hostile
       *    2: None
       *
       * If no planet meeting the current criteria can be found, the next
       * set of criteria is tried until none remain.
       */
      found = NULL;
      for (i=0; i<3; i++) {
         services = PLANET_SERVICE_LAND | PLANET_SERVICE_INHABITED |
               PLANET_SERVICE_REFUEL;

         if (i == 0)
            services |= PLANET_SERVICE_SHIPYARD;

         if (i != 2)
            services |= PLANET_SERVICE_OUTFITS;

         found = space_getRndPlanet( 1, services,
               (i != 2) ? player_filterSuitablePlanet : NULL );
         if (found != NULL)
            break;

         WARN(_("Could not find a planet satisfying criteria %d."), i);
      }

      if (found == NULL) {
         WARN(_("Could not find a suitable planet. Choosing a random planet."));
         found = space_getRndPlanet(0, 0, NULL); /* This should never, ever fail. */
      }
      pnt = planet_get(found);
   }
   sys = system_get(planet_getSystem(pnt->name));

   /* This should never happen, but putting this here just in case.
    * Otherwise we'll get a segfault in the next line. */
   if (sys == NULL)
      ERR("Ended up on a planet that either doesn't exist, or has no system.");

   space_gfxLoad( sys );
   a = RNGF() * 2.*M_PI;
   r = RNGF() * pnt->radius * 0.8;
   player_warp( pnt->pos.x + r*cos(a), pnt->pos.y + r*sin(a) );
   player.p->solid->dir = RNG(0,359) * M_PI/180.;

   /* initialize the system */
   space_init(sys->name);
   map_cleanup();
   map_clear(); /* sets the map up */

   /* initialize the sound */
   player_initSound();

   return pnt;
}


/**
 * @brief Filter function for space_getRndPlanet
 *
 *    @param p Planet.
 *    @return Whether the planet is suitable for teleporting to.
 */
static int player_filterSuitablePlanet( Planet *p )
{
   return !faction_isPlayerEnemy(p->faction);
}


/**
 * @brief Parses player's done missions.
 *
 *    @param parent Node of the missions.
 *    @return 0 on success.
 */
static int player_parseDoneMissions( xmlNodePtr parent )
{
   xmlNodePtr node;
   int id;

   node = parent->xmlChildrenNode;

   do {
      if (xml_isNode(node,"done")) {
         id = mission_getID( xml_get(node) );
         if (id < 0)
            DEBUG(_("Mission '%s' doesn't seem to exist anymore, removing from save."),
                  xml_get(node));
         else
            player_missionFinished( id );
      }
   } while (xml_nextNode(node));

   return 0;
}


/**
 * @brief Parses player's done missions.
 *
 *    @param parent Node of the missions.
 *    @return 0 on success.
 */
static int player_parseDoneEvents( xmlNodePtr parent )
{
   xmlNodePtr node;
   int id;

   node = parent->xmlChildrenNode;

   do {
      if (xml_isNode(node,"done")) {
         id = event_dataID( xml_get(node) );
         if (id < 0)
            DEBUG(_("Event '%s' doesn't seem to exist anymore, removing from save."),
                  xml_get(node));
         else
            player_eventFinished( id );
      }
   } while (xml_nextNode(node));

   return 0;
}


/**
 * @brief Parses player's licenses.
 *
 *    @param parent Node of the licenses.
 *    @return 0 on success.
 */
static int player_parseLicenses( xmlNodePtr parent )
{
   xmlNodePtr node;
   char *name;

   node = parent->xmlChildrenNode;

   do {
      if (xml_isNode(node, "license")) {
         name = xml_get(node);
         if (name == NULL) {
            WARN(_("License node is missing name attribute."));
            continue;
         }
         player_addLicense(name);
      }
   } while (xml_nextNode(node));

   return 0;
}


/**
 * @brief Parses the escorts from the escort node.
 *
 *    @param parent "escorts" node to parse.
 *    @return 0 on success.
 */
static int player_parseEscorts( xmlNodePtr parent )
{
   xmlNodePtr node;
   char *buf, *ship;
   EscortType_t type;

   node = parent->xmlChildrenNode;

   do {
      if (xml_isNode(node,"escort")) {
         xmlr_attr_strd( node, "type", buf );
         if (strcmp(buf,"bay")==0)
            type = ESCORT_TYPE_BAY;
         else {
            WARN(_("Escort has invalid type '%s'."), buf);
            type = ESCORT_TYPE_NULL;
         }
         free(buf);

         ship = xml_get(node);
         if (ship == NULL) {
            WARN(_("Escort is missing ship type, skipping"));
            continue;
         }

         /* Add escort to the list. */
         escort_addList( player.p, ship, type, 0, 1 );
      }
   } while (xml_nextNode(node));

   return 0;
}


/**
 * @brief Parses the player metadata.
 *
 *    @param parent "metadata" node to parse.
 *    @return 0 on success.
 */
static int player_parseMetadata( xmlNodePtr parent )
{
   xmlNodePtr node;

   node = parent->xmlChildrenNode;
   do {
      xml_onlyNodes(node);

      if (xml_isNode(node,"last_played"))
         xml_parseTime(node, &player.last_played);
      else if (xml_isNode(node,"time_played"))
         xml_parseTime(node, &player.time_played);
      else if (xml_isNode(node,"date_created"))
         xml_parseTime(node, &player.date_created);
      else if (xml_isNode(node,"dmg_done_shield"))
         player.dmg_done_shield = xml_getFloat(node);
      else if (xml_isNode(node,"dmg_done_armour"))
         player.dmg_done_armour = xml_getFloat(node);
      else if (xml_isNode(node,"dmg_taken_shield"))
         player.dmg_taken_shield = xml_getFloat(node);
      else if (xml_isNode(node,"dmg_taken_armour"))
         player.dmg_taken_armour = xml_getFloat(node);
      else if (xml_isNode(node,"ships_destroyed"))
         player.ships_destroyed = xml_getInt(node);
   } while (xml_nextNode(node));

   return 0;
}


/**
 * @brief Adds outfit to pilot if it can.
 */
static void player_addOutfitToPilot(Pilot* pilot, const Outfit* outfit,
      PilotOutfitSlot *s)
{
   int ret;

   if (!outfit_fitsSlot( outfit, &s->sslot->slot )) {
      DEBUG( _("Outfit '%s' does not fit designated slot on player's pilot '%s', adding to stock."),
            outfit->name, pilot->name );
      player_addOutfit( outfit, 1 );
      return;
   }

   ret = pilot_addOutfitRaw( pilot, outfit, s );
   if (ret != 0) {
      DEBUG(_("Outfit '%s' does not fit on player's pilot '%s', adding to stock."),
            outfit->name, pilot->name);
      player_addOutfit( outfit, 1 );
      return;
   }

   /* Update stats. */
   pilot_calcStats( pilot );
}


/**
 * @brief Parses a ship outfit slot.
 */
static void player_parseShipSlot( xmlNodePtr node, Pilot *ship, PilotOutfitSlot *slot )
{
   const Outfit *o, *ammo;
   char *buf;
   int q;

   char *name = xml_get(node);
   if (name == NULL) {
      WARN(_("Empty ship slot node found, skipping."));
      return;
   }

   /* Add the outfit. */
   o = player_tryGetOutfit(name, 1);
   if (o==NULL)
      return;
   player_addOutfitToPilot( ship, o, slot );

   /* Doesn't have ammo. */
   if (outfit_ammo(o)==NULL)
      return;

   /* See if has ammo. */
   xmlr_attr_strd(node,"ammo",buf);
   if (buf == NULL)
      return;

   /* Get the ammo. */
   ammo = outfit_get(buf);
   free(buf);
   if (ammo==NULL)
      return;

   /* See if has quantity. */
   xmlr_attr_int(node,"quantity",q);
   if (q > 0)
      pilot_addAmmo( ship, slot, ammo, q );
}


/**
 * @brief Parses a player's ship.
 *
 *    @param parent Node of the ship.
 *    @param is_player Is it the ship the player is currently in?
 *    @return 0 on success.
 */
static int player_parseShip( xmlNodePtr parent, int is_player )
{
   char *name, *model;
   int i, n, id;
   int fuel;
   const Ship *ship_parsed;
   Pilot* ship;
   xmlNodePtr node, cur, ccur;
   int quantity;
   const Outfit *o;
   int ret;
   const char *com_name;
   Commodity *com;
   PilotFlags flags;
   pilotId_t pid;
   int autoweap, level, weapid, active_set, aim_lines, in_range, weap_type;
   PlayerShip_t *ps;

   xmlr_attr_strd( parent, "name", name );
   xmlr_attr_strd( parent, "model", model );

   /* Safe defaults. */
   pilot_clearFlagsRaw( flags );
   pilot_setFlagRaw( flags, PILOT_PLAYER );
   pilot_setFlagRaw( flags, PILOT_NO_OUTFITS );

   /* Get the ship. */
   ship_parsed = player_tryGetShip(model);
   if (ship_parsed == NULL) {
      WARN(_("Player ship '%s' not found!"), model);

      /* Clean up. */
      free(name);
      free(model);

      return -1;
   }

   /* Add GUI if applicable. */
   player_guiAdd(ship_parsed->gui);

   /* player is currently on this ship */
   if (is_player != 0) {
      pid = pilot_create( ship_parsed, name, faction_get("Player"), "player", 0., NULL, NULL, flags, 0, 0 );
      ship = player.p;
      cam_setTargetPilot( pid, 0 );
   }
   else
      ship = pilot_createEmpty( ship_parsed, name, faction_get("Player"), "player", flags );

   /* Ship should not have default outfits. */
   for (i=0; i<array_size(ship->outfits); i++)
      pilot_rmOutfitRaw( ship, ship->outfits[i] );

   /* Clean up. */
   free(name);
   free(model);

   /* Defaults. */
   fuel = -1;
   autoweap = 1;
   aim_lines = 0;

   /* Start parsing. */
   node = parent->xmlChildrenNode;
   do {
      /* get fuel */
      xmlr_int(node,"fuel",fuel);

      /* New outfit loading. */
      if (xml_isNode(node,"outfits_structure")) {
         cur = node->xmlChildrenNode;
         do { /* load each outfit */
            if (xml_isNode(cur,"outfit")) {
               xmlr_attr_int_def( cur, "slot", n, -1 );
               if ((n<0) || (n >= array_size(ship->outfit_structure))) {
                  name = xml_get(cur);
                  o = player_tryGetOutfit(name, 1);
                  if (o != NULL)
                     player_addOutfit(o, 1);
                  DEBUG(_("Outfit slot out of range, not adding to ship."));
                  continue;
               }
               player_parseShipSlot( cur, ship, &ship->outfit_structure[n] );
            }
         } while (xml_nextNode(cur));
      }
      else if (xml_isNode(node,"outfits_utility")) {
         cur = node->xmlChildrenNode;
         do { /* load each outfit */
            if (xml_isNode(cur,"outfit")) {
               xmlr_attr_int_def( cur, "slot", n, -1 );
               if ((n<0) || (n >= array_size(ship->outfit_utility))) {
                  name = xml_get(cur);
                  o = player_tryGetOutfit(name, 1);
                  if (o != NULL)
                     player_addOutfit(o, 1);
                  WARN(_("Outfit slot out of range, not adding to ship."));
                  continue;
               }
               player_parseShipSlot( cur, ship, &ship->outfit_utility[n] );
            }
         } while (xml_nextNode(cur));
      }
      else if (xml_isNode(node,"outfits_weapon")) {
         cur = node->xmlChildrenNode;
         do { /* load each outfit */
            if (xml_isNode(cur,"outfit")) {
               xmlr_attr_int_def( cur, "slot", n, -1 );
               if ((n<0) || (n >= array_size(ship->outfit_weapon))) {
                  name = xml_get(cur);
                  o = player_tryGetOutfit(name, 1);
                  if (o != NULL)
                     player_addOutfit(o, 1);
                  WARN(_("Outfit slot out of range, not adding to ship."));
                  continue;
               }
               player_parseShipSlot( cur, ship, &ship->outfit_weapon[n] );
            }
         } while (xml_nextNode(cur));
      }
      else if (xml_isNode(node, "commodities")) {
         cur = node->xmlChildrenNode;
         do {
            if (xml_isNode(cur, "commodity")) {
               xmlr_attr_int( cur, "quantity", quantity );
               xmlr_attr_int( cur, "id", i );

               /* Get the commodity. */
               com_name = xml_get(cur);
               if (com_name == NULL) {
                  WARN(_("Commodity missing name, removing."));
                  continue;
               }
               com = commodity_get(com_name);
               if (com == NULL) {
                  WARN(_("Unknown commodity '%s' detected, removing."), com_name);
                  continue;
               }

               /* actually add the cargo with id hack
                * Note that the player's cargo_free is ignored here.
                */
               pilot_cargoAddRaw(ship, com, quantity, i);
            }
         } while (xml_nextNode(cur));
      }
   } while (xml_nextNode(node));

   /* Update stats. */
   pilot_calcStats( ship );

   /* Test for validity. */
   if (fuel >= 0)
      ship->fuel = MIN(ship->fuel_max, fuel);
   if (!pilot_slotsCheckSafety( ship )) {
      DEBUG(_("Player ship '%s' failed slot validity check , removing all outfits and adding to stock."),
            ship->name );
      /* Remove all outfits. */
      for (i=0; i<array_size(ship->outfits); i++) {
         o = ship->outfits[i]->outfit;
         ret = pilot_rmOutfitRaw( ship, ship->outfits[i] );
         if (ret==0)
            player_addOutfit( o, 1 );
      }
      pilot_calcStats( ship );
   }

   /* add it to the stack if it's not what the player is in */
   if (is_player == 0) {
      ps = &array_grow( &player_stack );
      ps->p = ship;
   }

   /* Sets inrange by default if weapon sets are missing. */
   for (i=0; i<PILOT_WEAPON_SETS; i++) {
      pilot_weapSetInrange(ship, i, WEAPSET_INRANGE_PLAYER_DEF);
   }

   /* Second pass for weapon sets. */
   active_set = 0;
   node = parent->xmlChildrenNode;
   do {
      if (!xml_isNode(node,"weaponsets"))
         continue;

      /* Check for autoweap. */
      xmlr_attr_int( node, "autoweap", autoweap );

      /* Load the last weaponset the player used on this ship. */
      xmlr_attr_int_def( node, "active_set", active_set, -1 );

      /* Check for aim_lines. */
      xmlr_attr_int( node, "aim_lines", aim_lines );

      /* Parse weapon sets. */
      cur = node->xmlChildrenNode;
      do { /* Load each weapon set. */
         xml_onlyNodes(cur);
         if (!xml_isNode(cur,"weaponset")) {
            WARN(_("Player ship '%s' has unknown node '%s' in 'weaponsets' (expected 'weaponset')."),
                  ship->name, cur->name);
            continue;
         }

         /* Get id. */
         xmlr_attr_int_def(cur, "id", id, -1);
         if (id == -1) {
            WARN(_("Player ship '%s' missing 'id' tag for weapon set."),ship->name);
            continue;
         }
         if ((id < 0) || (id >= PILOT_WEAPON_SETS)) {
            WARN(_("Player ship '%s' has invalid weapon set id '%d' [max %d]."),
                  ship->name, id, PILOT_WEAPON_SETS-1 );
            continue;
         }

         /* Set inrange mode. */
         xmlr_attr_int( cur, "inrange", in_range );
         pilot_weapSetInrange( ship, id, in_range );

         if (autoweap) /* Autoweap handles everything except inrange. */
            continue;

         /* Set type mode. */
         xmlr_attr_int_def( cur, "type", weap_type, -1 );
         if (weap_type == -1) {
            WARN(_("Player ship '%s' missing 'type' tag for weapon set."),ship->name);
            continue;
         }
         pilot_weapSetType( ship, id, weap_type );

         /* Parse individual weapons. */
         ccur = cur->xmlChildrenNode;
         do {
            /* Only nodes. */
            xml_onlyNodes(ccur);

            /* Only weapon nodes. */
            if (!xml_isNode(ccur,"weapon")) {
               WARN(_("Player ship '%s' has unknown 'weaponset' child node '%s' (expected 'weapon')."),
                     ship->name, ccur->name );
               continue;
            }

            /* Get level. */
            xmlr_attr_int_def( ccur, "level", level, -1 );
            if (level == -1) {
               WARN(_("Player ship '%s' missing 'level' tag for weapon set weapon."), ship->name);
               continue;
            }
            weapid = xml_getInt(ccur);
            if ((weapid < 0) || (weapid >= array_size(ship->outfits))) {
               WARN(_("Player ship '%s' has invalid weapon id %d [max %d]."),
                     ship->name, weapid, array_size(ship->outfits)-1 );
               continue;
            }

            /* Add the weapon set. */
            pilot_weapSetAdd( ship, id, ship->outfits[weapid], level );

         } while (xml_nextNode(ccur));
      } while (xml_nextNode(cur));
   } while (xml_nextNode(node));

   /* Set up autoweap if necessary. */
   ship->autoweap = autoweap;
   if (autoweap)
      pilot_weaponAuto( ship );
   pilot_weaponSafe( ship );
   if (active_set >= 0 && active_set < PILOT_WEAPON_SETS)
      ship->active_set = active_set;
   else
      pilot_weaponSetDefault( ship );

   /* Set aimLines */
   ship->aimLines = aim_lines;

   return 0;
}
