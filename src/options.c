/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file options.c
 *
 * @brief Options menu
 */


/** @cond */
#include <ctype.h>
#include "physfs.h"
#include "SDL.h"

#include "naev.h"
/** @endcond */

#include "options.h"

#include "array.h"
#include "background.h"
#include "conf.h"
#include "dialogue.h"
#include "input.h"
#include "log.h"
#include "menu.h"
#include "music.h"
#include "ndata.h"
#include "nstring.h"
#include "player.h"
#include "render.h"
#include "sound.h"
#include "toolkit.h"


#define BUTTON_WIDTH    200 /**< Button width, standard across menus. */
#define BUTTON_HEIGHT   30 /**< Button height, standard across menus. */

#define OPT_WIN_GAMEPLAY   0
#define OPT_WIN_VIDEO      1
#define OPT_WIN_AUDIO      2
#define OPT_WIN_INPUT      3
#define OPT_WINDOWS        4

static unsigned int opt_wid = 0;
static unsigned int *opt_windows;
static const char *opt_names[] = {
   N_("Gameplay"),
   N_("Video"),
   N_("Audio"),
   N_("Input")
};


static int opt_restart = 0;


/* Initial values (reverted to on cancel). */
static int opt_orig_colorblind;
static ColorblindMode opt_orig_colorblind_mode;
static double opt_orig_scalefactor;
static double opt_orig_bg_brightness;
static double opt_orig_gamma_correction;
static double opt_orig_zoom_far;
static double opt_orig_zoom_near;


/*
 * External stuff.
 */
static const char *opt_selectedKeybind; /**< Selected keybinding. */
static int opt_lastKeyPress = 0; /**< Last keypress. */


/*
 * prototypes
 */
/* Misc. */
static void opt_close( unsigned int wid, char *name );
static void opt_needRestart (void);
/* Gameplay. */
static char** lang_list( int *n );
static void opt_gameplay( unsigned int wid );
static void opt_setGameSpeed(unsigned int wid, char *str);
static void opt_setTCVelocity(unsigned int wid, char *str);
static void opt_setTCMax(unsigned int wid, char *str);
static void opt_setAutonavResetSpeed( unsigned int wid, char *str );
static void opt_setMapOverlayOpacity( unsigned int wid, char *str );
static void opt_setGamma(unsigned int wid, char *str);
static void opt_OK( unsigned int wid, char *str );
static int opt_gameplaySave( unsigned int wid, char *str );
static void opt_gameplayDefaults( unsigned int wid, char *str );
static void opt_gameplayUpdate( unsigned int wid, char *str );
/* Video. */
static void opt_video( unsigned int wid );
static void opt_videoRes( unsigned int wid, char *str );
static int opt_videoSave( unsigned int wid, char *str );
static void opt_videoDefaults( unsigned int wid, char *str );
static void opt_getVideoMode( int *w, int *h, int *fullscreen );
static void opt_setScalefactor( unsigned int wid, char *str );
static void opt_setZoomFar( unsigned int wid, char *str );
static void opt_setZoomNear( unsigned int wid, char *str );
static void opt_setBGBrightness( unsigned int wid, char *str );
static void opt_checkColorblind( unsigned int wid, char *str );
static void opt_videoColorblindMode(wid_t wid, char *str);
/* Audio. */
static void opt_audio( unsigned int wid );
static int opt_audioSave( unsigned int wid, char *str );
static void opt_audioDefaults( unsigned int wid, char *str );
static void opt_audioUpdate( unsigned int wid );
static void opt_audioLevelStr( char *buf, int max, int type, double pos );
static void opt_setAudioLevel( unsigned int wid, char *str );
static void opt_beep( unsigned int wid, char *str );
/* Keybind menu. */
static void opt_keybinds( unsigned int wid );
static void menuKeybinds_getDim( unsigned int wid, int *w, int *h,
      int *lw, int *lh, int *bw, int *bh );
static void menuKeybinds_genList( unsigned int wid );
static void menuKeybinds_update( unsigned int wid, char *name );
static void opt_keyDefaults( unsigned int wid, char *str );
/* Setting keybindings. */
static int opt_setKeyEvent( unsigned int wid, SDL_Event *event );
static void opt_setKey( unsigned int wid, char *str );
static void opt_unsetKey( unsigned int wid, char *str );


/**
 * @brief Creates the options menu thingy.
 */
void opt_menu (void)
{
   size_t i;
   int w, h;
   const char **names;

   /* Dimensions. */
   w = 720;
   h = 640;

   /* Create window and tabs. */
   opt_wid = window_create( "wdwOptions", _("Options"), -1, -1, w, h );
   window_setCancel( opt_wid, opt_close );

   /* Create tabbed window. */
   names = calloc( sizeof(char*), sizeof(opt_names)/sizeof(char*) );
   for (i=0; i<sizeof(opt_names)/sizeof(char*); i++)
      names[i] = _(opt_names[i]);
   opt_windows = window_addTabbedWindow( opt_wid, -1, -1, -1, -1, "tabOpt",
         OPT_WINDOWS, (const char**)names, 0 );
   free(names);

   /* Load tabs. */
   opt_gameplay(  opt_windows[ OPT_WIN_GAMEPLAY ] );
   opt_video(     opt_windows[ OPT_WIN_VIDEO ] );
   opt_audio(     opt_windows[ OPT_WIN_AUDIO ] );
   opt_keybinds(  opt_windows[ OPT_WIN_INPUT ] );

   /* Set as need restart if needed. */
   if (opt_restart)
      opt_needRestart();

   menu_Open(MENU_OPTIONS);
}


/**
 * @brief Saves all options and closes the options screen.
 */
static void opt_OK( unsigned int wid, char *str )
{
   (void) wid;
   int ret, prompted_restart;

   prompted_restart = opt_restart;
   ret = 0;
   ret |= opt_gameplaySave(opt_windows[OPT_WIN_GAMEPLAY], str);
   ret |= opt_audioSave(opt_windows[OPT_WIN_AUDIO], str);
   ret |= opt_videoSave(opt_windows[OPT_WIN_VIDEO], str);

   if (opt_restart && !prompted_restart)
      dialogue_msgRaw(_("Warning"),
         _("Restart Naikari for changes to take effect."));

   /* Close window if no errors occurred. */
   if (!ret) {
      window_destroy(opt_wid);
      menu_Close(MENU_OPTIONS);
      opt_wid = 0;
   }
}

/**
 * @brief Closes the options screen without saving.
 */
static void opt_close( unsigned int wid, char *name )
{
   (void) wid;
   (void) name;

   /* At this point, set sound levels as defined in the config file.
    * This ensures that sound volumes are reset on "Cancel". */
   sound_volume(conf.sound);
   music_volume(conf.music);

   /* Set others to original values as needed. */
   conf.colorblind = opt_orig_colorblind;
   conf.colorblind_mode = opt_orig_colorblind_mode;
   gl_colorblind(conf.colorblind, conf.colorblind_mode);
   conf.scalefactor = opt_orig_scalefactor;
   conf.bg_brightness = opt_orig_bg_brightness;
   conf.gamma_correction = opt_orig_gamma_correction;
   conf.zoom_far = opt_orig_zoom_far;
   conf.zoom_near = opt_orig_zoom_near;

   /* Need to set gamma again in case it was changed. */
   render_setGamma(conf.gamma_correction);

   window_destroy(opt_wid);
   menu_Close(MENU_OPTIONS);
   opt_wid = 0;
}


/**
 * @brief Handles resize events nfor the options menu.
 */
void opt_resize (void)
{
   int w, h, fullscreen;
   char buf[16];

   /* Nothing to do if not open. */
   if (!opt_wid)
      return;

   /* Update the resolution input widget. */
   opt_getVideoMode( &w, &h, &fullscreen );
   snprintf( buf, sizeof(buf), "%dx%d", w, h );
   window_setInput( opt_windows[OPT_WIN_VIDEO], "inpRes", buf );
}


/*
 * Gets the list of languages available.
 */
static char** lang_list( int *n )
{
   char **ls;
   LanguageOption *opts = gettext_languageOptions();
   int i;

   /* Default English only. */
   ls = malloc( sizeof(char*)*128 );
   ls[0] = strdup(_("system"));
   *n = 1;

   /* Try to open the available languages. */
   for (i=0; i<array_size(opts); i++)
      ls[(*n)++] = opts[i].language;
   array_free( opts );

   return ls;
}


/**
 * @brief Opens the gameplay menu.
 */
static void opt_gameplay( unsigned int wid )
{
   (void) wid;
   char buf[STRMAX];
   char **paths;
   int cw;
   int w, h, y, x, by, l, n, i;
   char **ls;

   /* Get size. */
   window_dimWindow( wid, &w, &h );

   /* Close button */
   window_addButton( wid, -20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnClose", _("OK"), opt_OK );
   window_addButton( wid, -20 - 1*(BUTTON_WIDTH+20), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnCancel", _("Cancel"), opt_close );
   window_addButton( wid, -20 - 2*(BUTTON_WIDTH+20), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnDefaults", _("Defaults"), opt_gameplayDefaults );

   /* Information. */
   cw = (w-40);
   x = 20;
   y = -35;
   window_addText( wid, x, y, cw, 20, 1, "txtVersion",
         &gl_smallFont, NULL, naev_version(1) );
   y -= 20;

   paths = PHYSFS_getSearchPath();
   for (i=l=0; paths[i]!=NULL && (size_t)l < sizeof(buf); i++)
   {
      if (i == 0)
         l = scnprintf( buf, sizeof(buf), _("ndata: %s"), paths[i] );
      else
         l += scnprintf( &buf[l], sizeof(buf)-l, ":%s", paths[i] );
   }
   PHYSFS_freeList(paths);
   paths = NULL;
   window_addText( wid, x, y, cw, 20, 1, "txtNdata",
         &gl_smallFont, NULL, buf );
   y -= 40;
   by = y;


   cw = (w-60)/2 - 40;
   y  = by;
   x  = 20;
   window_addText(wid, x, y, cw, 20, 0, "txtLanguage",
         NULL, NULL, _("Language"));
   y -= 30;
   ls = lang_list( &n );
   i = 0;
   if (conf.language != NULL) {
      for (i=0; i<n; i++)
         if (strcmp(conf.language,ls[i])==0)
            break;
      if (i>=n)
         i = 0;
   }
   window_addList( wid, x, y, cw, 240, "lstLanguage", ls, n, i, NULL, NULL );
   y -= 260;

   /* Compiletime stuff. */
   window_addText( wid, x, y, cw, 20, 0, "txtCompile",
         NULL, NULL, _("Compilation Flags") );
   y -= 30;
   window_addText( wid, x, y, cw, h+y-20, 0, "txtFlags",
         &gl_smallFont, &cFontOrange,
         ""
#if DEBUGGING
#if DEBUG_PARANOID
         "Debug Paranoid\n"
#else /* DEBUG_PARANOID */
         "Debug\n"
#endif /* DEBUG_PARANOID */
#endif /* DEBUGGING */
#if LINUX
         "Linux\n"
#elif FREEBSD
         "FreeBSD\n"
#elif MACOS
         "macOS\n"
#elif WIN32
         "Windows\n"
#else
         "Unknown OS\n"
#endif
#if HAVE_LUAJIT
         "Using LuaJIT\n"
#endif
         );


   y -= window_getTextHeight(wid, "txtFlags") + 10;

   /* Options. */


   (void) y;
   x = 20 + cw + 20;
   y  = by;
   cw += 80;

   /* Base game speed (dt_mod). */
   window_addText(wid, x, y, cw, 20, 1, "txtGameSpeed", &gl_smallFont,
         NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw, 20, "fadGameSpeed", 0.25, 1.,
         conf.dt_mod, opt_setGameSpeed);
   y -= 40;

   window_addCheckbox(wid, x, y, cw, 20,
         "chkZoomManual", _("Enable manual zoom control"), NULL,
         conf.zoom_manual);
   y -= 25;
   window_addCheckbox(wid, x, y, cw, 20,
         "chkAfterburn", _("Enable double-tap afterburn"), NULL,
         conf.doubletap_afterburn);
   y -= 25;
   window_addCheckbox(wid, x, y, cw, 20,
         "chkFollow", _("Enable right-click pilot follow"), NULL,
         conf.rightclick_follow);
   y -= 25;
   window_addCheckbox(wid, x, y, cw, 20,
         "chkCompress", _("Enable saved game compression"), NULL,
         conf.save_compress);
   y -= 50;

   /* Autonav Time Compression Settings */
   window_addText(wid, x, y, cw-130, 20, 0, "txtAutonavTCHeader",
         NULL, NULL, _("Autonav Time Compression"));
   y -= 30;
   /* TC Velocity */
   window_addText(wid, x, y, cw, 20, 1, "txtTCVelocity",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw, 20, "fadTCVelocity", 1000., 10000.,
         conf.compression_velocity, opt_setTCVelocity);
   y -= 30;
   /* TC Max */
   window_addText(wid, x, y, cw, 20, 1, "txtTCMax",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw, 20, "fadTCMax", 1., 201.,
         conf.compression_mult, opt_setTCMax);
   y -= 30;
   /* TC reset threshold */
   window_addText(wid, x, y, cw, 20, 1, "txtResetThreshold",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw, 20, "fadResetThreshold", 0., 1.,
         conf.autonav_reset_speed, opt_setAutonavResetSpeed);
   y -= 30;
   window_addCheckbox(wid, x, y, cw, 20,
         "chkIgnorePassive", _("Ignore passive enemy presence"), NULL,
         conf.autonav_ignore_passive);
   y -= 50;

   /* Restart text. */
   window_addText( wid, 20, 20 + BUTTON_HEIGHT,
         w - 40, 30, 0, "txtRestart", &gl_smallFont, NULL, NULL );

   /* Update. */
   opt_gameplayUpdate( wid, NULL );
}

/**
 * @brief Saves the gameplay options.
 */
static int opt_gameplaySave( unsigned int wid, char *str )
{
   (void) str;
   int p, newlang;
   char *s;
   double tc_vel;
   double tc_max;

   /* List. */
   p = toolkit_getListPos( wid, "lstLanguage" );
   s = (p==0) ? NULL : toolkit_getList( wid, "lstLanguage" );
   newlang = ((s != NULL) != (conf.language != NULL))
          || ((s != NULL) && (strcmp( s, conf.language) != 0));
   if (newlang) {
      free( conf.language );
      conf.language = (s==NULL) ? NULL : strdup( s );
      /* Apply setting going forward; advise restart to regen other text. */
      gettext_setLanguage( conf.language );
      opt_needRestart();
   }

   /* Checkboxes. */
   conf.autonav_ignore_passive = window_checkboxState(wid, "chkIgnorePassive");
   conf.zoom_manual = window_checkboxState(wid, "chkZoomManual");
   conf.doubletap_afterburn = window_checkboxState(wid, "chkAfterburn");
   conf.rightclick_follow = window_checkboxState(wid, "chkFollow");
   conf.save_compress = window_checkboxState(wid, "chkCompress");

   /* Faders. */
   conf.dt_mod = window_getFaderValue(wid, "fadGameSpeed");
   conf.autonav_reset_speed = window_getFaderValue(wid, "fadResetThreshold");

   /* Save TC Velocity in increments of 25. */
   tc_vel = window_getFaderValue(wid, "fadTCVelocity");
   conf.compression_velocity = round(tc_vel/25.) * 25.;

   /* Save TC Max in increments of 100%. */
   tc_max = window_getFaderValue(wid, "fadTCMax");
   conf.compression_mult = round(tc_max/1.) * 1.;

   if (!menu_isOpen(MENU_MAIN)) {
      /* Reset speed so changes to base speed take effect
       * immediately. */
      player_autonavResetSpeed();

      /* Recalculate player.tc_max in case autonav TC parameters have
       * changed while autonav is active. */
      player.tc_max = player_dt_max();
   }

   return 0;
}

/**
 * @brief Sets the default gameplay options.
 */
static void opt_gameplayDefaults( unsigned int wid, char *str )
{
   (void) str;

   /* Restore. */
   /* Checkboxes. */
   window_checkboxSet(wid, "chkIgnorePassive", AUTONAV_IGNORE_PASSIVE_DEFAULT);
   window_checkboxSet(wid, "chkZoomManual", MANUAL_ZOOM_DEFAULT);
   window_checkboxSet(wid, "chkAfterburn", DOUBLETAP_AFTERBURN_DEFAULT);
   window_checkboxSet(wid, "chkFollow", RIGHTCLICK_FOLLOW_DEFAULT);
   window_checkboxSet(wid, "chkCompress", SAVE_COMPRESSION_DEFAULT);

   /* Faders. */
   window_faderSetBoundedValue(wid, "fadGameSpeed", DT_MOD_DEFAULT);
   window_faderSetBoundedValue(wid, "fadTCVelocity",
         TIME_COMPRESSION_DEFAULT_VEL);
   window_faderSetBoundedValue(wid, "fadTCMax", TIME_COMPRESSION_DEFAULT_MULT);
   window_faderSetBoundedValue(wid, "fadResetThreshold",
         AUTONAV_RESET_SPEED_DEFAULT);
}

/**
 * @brief Updates the gameplay options.
 */
static void opt_gameplayUpdate( unsigned int wid, char *str )
{
   (void) str;

   /* Checkboxes. */
   window_checkboxSet(wid, "chkIgnorePassive", conf.autonav_ignore_passive);
   window_checkboxSet(wid, "chkZoomManual", conf.zoom_manual);
   window_checkboxSet(wid, "chkAfterburn", conf.doubletap_afterburn);
   window_checkboxSet(wid, "chkFollow", conf.rightclick_follow);
   window_checkboxSet(wid, "chkCompress", conf.save_compress);

   /* Faders. */
   window_faderSetBoundedValue(wid, "fadGameSpeed", conf.dt_mod);
   window_faderSetBoundedValue(wid, "fadTCVelocity", conf.compression_velocity);
   window_faderSetBoundedValue(wid, "fadTCMax", conf.compression_mult);
   window_faderSetBoundedValue(wid, "fadResetThreshold",
         conf.autonav_reset_speed);
}


/**
 * @brief Callback to set base game speed (conf.dt_mod).
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setGameSpeed(unsigned int wid, char *str)
{
   char buf[STRMAX_SHORT];
   double dt_mod;

   /* Get fader value. */
   dt_mod = window_getFaderValue(wid, str);

   snprintf(buf, sizeof(buf), _("Base Game Speed: %.0f%%"), dt_mod * 100);

   window_modifyText(wid, "txtGameSpeed", buf);
}


/**
 * @brief Callback to set TC Velocity (conf.compression_velocity).
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setTCVelocity(unsigned int wid, char *str)
{
   char buf[STRMAX_SHORT];
   double tc_vel;

   /* Get fader value. */
   tc_vel = window_getFaderValue(wid, str);
   /* Adjust in increments of 25. */
   tc_vel = round(tc_vel/25.) * 25.;

   /* Translators: "TC" is short for "Time Compression". */
   snprintf(buf, sizeof(buf), _("TC Velocity: %.0f mAU/s"), tc_vel);

   window_modifyText(wid, "txtTCVelocity", buf);
}


/**
 * @brief Callback to set TC Max (conf.compression_mult).
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setTCMax(unsigned int wid, char *str)
{
   char buf[STRMAX_SHORT];
   double tc_max;

   /* Get fader value. */
   tc_max = window_getFaderValue(wid, str);
   /* Adjust in increments of 100%. */
   tc_max = round(tc_max/1.) * 1.;

   /* Translators: "TC" is short for "Time Compression". */
   snprintf(buf, sizeof(buf), _("TC Max: %+.0f%%"), (tc_max-1.) * 100);

   window_modifyText(wid, "txtTCMax", buf);
}


/**
 * @brief Callback to set autonav abort threshold.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setAutonavResetSpeed( unsigned int wid, char *str )
{
   char buf[STRMAX_SHORT];
   double autonav_reset_speed;

   /* Set fader. */
   autonav_reset_speed = window_getFaderValue(wid, str);

   /* Generate message. */
   if (autonav_reset_speed >= 1.)
      /* Translators: "TC" is short for "Time Compression". */
      snprintf(buf, sizeof(buf), _("TC Reset Threshold: Enemy Presence"));
   else if (autonav_reset_speed > 0.)
      /* Translators: "TC" is short for "Time Compression". */
      snprintf(buf, sizeof(buf), _("TC Reset Threshold: %.0f%% Shield"),
            autonav_reset_speed * 100);
   else
      /* Translators: "TC" is short for "Time Compression". */
      snprintf(buf, sizeof(buf), _("TC Reset Threshold: Armor Damage"));

   window_modifyText(wid, "txtResetThreshold", buf);
}


/**
 * @brief Gets the keybind menu dimensions.
 */
static void menuKeybinds_getDim( unsigned int wid, int *w, int *h,
      int *lw, int *lh, int *bw, int *bh )
{
   /* Get window dimensions. */
   window_dimWindow( wid, w, h );

   /* Get button dimensions. */
   if (bw != NULL)
      *bw = BUTTON_WIDTH;
   if (bh != NULL)
      *bh = BUTTON_HEIGHT;

   /* Get list dimensions. */
   if (lw != NULL)
      *lw = *w - BUTTON_WIDTH - 60;
   if (lh != NULL)
      *lh = *h - 60;
}


/**
 * @brief Opens the keybindings menu.
 */
static void opt_keybinds( unsigned int wid )
{
   int w, h, lw, bw, bh;

   /* Get dimensions. */
   menuKeybinds_getDim( wid, &w, &h, &lw, NULL, &bw, &bh );

   /* Close button. */
   window_addButton( wid, -20, 20, bw, bh,
         "btnClose", _("OK"), opt_OK );
   /* Restore deafaults button. */
   window_addButton( wid, -20, 40 + bh, bw, bh,
         "btnDefaults", _("Defaults"), opt_keyDefaults );
   /* Set button. */
   window_addButton( wid, -20, 60 + 2*bh, bw, bh,
         "btnSet", _("Set Key"), opt_setKey );

   /* Text stuff. */
   window_addText( wid, 20+lw+20, -40, w-(20+lw+20), 30, 1, "txtName",
         NULL, NULL, NULL );
   window_addText( wid, 20+lw+20, -90, w-(20+lw+20), h-170-3*bh,
         0, "txtDesc", &gl_smallFont, NULL, NULL );

   /* Generate the list. */
   menuKeybinds_genList( wid );
}


/**
 * @brief Generates the keybindings list.
 *
 *    @param wid Window to update.
 */
static void menuKeybinds_genList( unsigned int wid )
{
   int         j, l, p;
   char **str, mod_text[64];
   SDL_Keycode key;
   KeybindType type;
   SDL_Keymod mod;
   int w, h;
   int lw, lh;
   int regen, pos, off;

   /* Get dimensions. */
   menuKeybinds_getDim( wid, &w, &h, &lw, &lh, NULL, NULL );

   /* Create the list. */
   str = malloc( sizeof( char * ) * input_numbinds );
   for ( j = 0; j < input_numbinds; j++ ) {
      l = 128; /* GCC deduces 68 because we have a format string "%s <%s%c>"
                * where "char mod_text[64]" is one of the "%s" args.
                * (that plus brackets plus %c + null gets to 68.
                * Just set to 128 as it's a power of two. */
      str[j] = malloc(l);
      key = input_getKeybind( keybind_info[j][0], &type, &mod );
      switch (type) {
         case KEYBIND_KEYBOARD:
            /* Generate mod text. */
            if (mod == NMOD_ANY)
               snprintf( mod_text, sizeof(mod_text), "any+" );
            else {
               p = 0;
               mod_text[0] = '\0';
               if (mod & NMOD_SHIFT)
                  p += scnprintf( &mod_text[p], sizeof(mod_text)-p, "shift+" );
               if (mod & NMOD_CTRL)
                  p += scnprintf( &mod_text[p], sizeof(mod_text)-p, "ctrl+" );
               if (mod & NMOD_ALT)
                  p += scnprintf( &mod_text[p], sizeof(mod_text)-p, "alt+" );
               if (mod & NMOD_META)
                  p += scnprintf( &mod_text[p], sizeof(mod_text)-p, "meta+" );
               (void)p;
            }

            /* Print key. Special-case ASCII letters (use uppercase, unlike SDL_GetKeyName.). */
            if (key < 0x100 && isalpha(key))
               snprintf(str[j], l, "%s <%s%c>", keybind_info[j][1], mod_text, toupper(key) );
            else
               snprintf(str[j], l, "%s <%s%s>", keybind_info[j][1], mod_text,
                     SDL_GetKeyName(key));
            break;
         case KEYBIND_JAXISPOS:
            snprintf(str[j], l, "%s <ja+%d>", keybind_info[j][1], key);
            break;
         case KEYBIND_JAXISNEG:
            snprintf(str[j], l, "%s <ja-%d>", keybind_info[j][1], key);
            break;
         case KEYBIND_JBUTTON:
            snprintf(str[j], l, "%s <jb%d>", keybind_info[j][1], key);
            break;
         case KEYBIND_JHAT_UP:
            snprintf(str[j], l, "%s <jh%d-up>", keybind_info[j][1], key);
            break;
         case KEYBIND_JHAT_DOWN:
            snprintf(str[j], l, "%s <jh%d-down>", keybind_info[j][1], key);
            break;
         case KEYBIND_JHAT_LEFT:
            snprintf(str[j], l, "%s <jh%d-left>", keybind_info[j][1], key);
            break;
         case KEYBIND_JHAT_RIGHT:
            snprintf(str[j], l, "%s <jh%d-right>", keybind_info[j][1], key);
            break;
         default:
            snprintf(str[j], l, "%s", keybind_info[j][1]);
            break;
      }
   }

   regen = widget_exists( wid, "lstKeybinds" );
   if (regen) {
      pos = toolkit_getListPos( wid, "lstKeybinds" );
      off = toolkit_getListOffset( wid, "lstKeybinds" );
      window_destroyWidget( wid, "lstKeybinds" );
   }

   window_addList( wid, 20, -40, lw, lh, "lstKeybinds", str, input_numbinds, 0, menuKeybinds_update, opt_setKey );

   if (regen) {
      toolkit_setListPos( wid, "lstKeybinds", pos );
      toolkit_setListOffset( wid, "lstKeybinds", off );
   }
}


/**
 * @brief Updates the keybindings menu.
 *
 *    @param wid Window to update.
 *    @param name Unused.
 */
static void menuKeybinds_update( unsigned int wid, char *name )
{
   (void) name;
   int selected;
   const char *keybind;
   const char *desc;
   SDL_Keycode key;
   KeybindType type;
   SDL_Keymod mod;
   char buf[1024];
   char binding[64];

   /* Get the keybind. */
   selected = toolkit_getListPos( wid, "lstKeybinds" );

   /* Remove the excess. */
   keybind = keybind_info[selected][0];
   opt_selectedKeybind = keybind;
   window_modifyText( wid, "txtName", keybind );

   /* Get information. */
   desc = input_getKeybindDescription( keybind );
   key = input_getKeybind( keybind, &type, &mod );

   /* Create the text. */
   switch (type) {
      case KEYBIND_NULL:
         snprintf(binding, sizeof(binding), _("Not bound"));
         break;
      case KEYBIND_KEYBOARD:
         /* Print key. Special-case ASCII letters (use uppercase, unlike SDL_GetKeyName.). */
         if (key < 0x100 && isalpha(key))
            snprintf(binding, sizeof(binding), _("keyboard:   %s%s%c"),
                  (mod != KMOD_NONE) ? input_modToText(mod) : "",
                  (mod != KMOD_NONE) ? " + " : "",
                  toupper(key));
         else
            snprintf(binding, sizeof(binding), _("keyboard:   %s%s%s"),
                  (mod != KMOD_NONE) ? input_modToText(mod) : "",
                  (mod != KMOD_NONE) ? " + " : "",
                  SDL_GetKeyName(key));
         break;
      case KEYBIND_JAXISPOS:
         snprintf(binding, sizeof(binding), _("joy axis pos:   <%d>"), key );
         break;
      case KEYBIND_JAXISNEG:
         snprintf(binding, sizeof(binding), _("joy axis neg:   <%d>"), key );
         break;
      case KEYBIND_JBUTTON:
         snprintf(binding, sizeof(binding), _("joy button:   <%d>"), key);
         break;
      case KEYBIND_JHAT_UP:
         snprintf(binding, sizeof(binding), _("joy hat up:   <%d>"), key);
         break;
      case KEYBIND_JHAT_DOWN:
         snprintf(binding, sizeof(binding), _("joy hat down: <%d>"), key);
         break;
      case KEYBIND_JHAT_LEFT:
         snprintf(binding, sizeof(binding), _("joy hat left: <%d>"), key);
         break;
      case KEYBIND_JHAT_RIGHT:
         snprintf(binding, sizeof(binding), _("joy hat right:<%d>"), key);
         break;
   }

   /* Update text. */
   snprintf(buf, sizeof(buf), "%s\n\n%s\n", desc, binding);
   window_modifyText( wid, "txtDesc", buf );
}


/**
 * @brief Restores the key defaults.
 */
static void opt_keyDefaults( unsigned int wid, char *str )
{
   (void) str;
   const char *title, *caption;
   char *ret;
   int i, ind, layout;

   const int n = 4;
   const char *opts[] = {
      _("WASD"),
      _("Arrow Keys"),
      _("IJKL"),
      _("ZQSD"),
      _("Cancel")
   };

   title = _("Restore Defaults");
   caption = _("Which layout do you want to use?");

   dialogue_makeChoice( title, caption, n );

   for (i=0; i<n; i++)
      dialogue_addChoice( title, caption, opts[i] );

   ret = dialogue_runChoice();
   if (ret == NULL)
      return;

   /* Find the index of the matched option. */
   ind = 0;
   for (i=0; i<n; i++) {
      if (strcmp(ret, opts[i]) == 0) {
         ind = i;
         break;
      }
   }
   free(ret);

   layout = LAYOUT_ARROWS;
   switch (ind) {
      case 0:
         layout = LAYOUT_WASD;
         break;

      case 1:
         layout = LAYOUT_ARROWS;
         break;

      case 2:
         layout = LAYOUT_IJKL;
         break;

      case 3:
         layout = LAYOUT_ZQSD;
         break;

      default:
         return;
   }

   /* Restore defaults. */
   input_setDefault(layout);

   /* Regenerate list widget. */
   menuKeybinds_genList( wid );

   /* Alert user it worked. */
   dialogue_msgRaw( _("Defaults Restored"), _("Keybindings restored to defaults."));
}


/**
 * @brief Callback to set the sound or music level.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setAudioLevel( unsigned int wid, char *str )
{
   char *widget;
   char buf[STRMAX_SHORT];
   char *vol_text;
   double vol;

   vol = window_getFaderValue(wid, str);
   if (strcmp(str, "fadSound") == 0) {
      sound_volume(vol);
      widget = "txtSound";
      opt_audioLevelStr(buf, sizeof(buf), 0, vol);
      asprintf(&vol_text, _("Sound: %s"), buf);
   }
   else {
      music_volume(vol);
      widget = "txtMusic";
      opt_audioLevelStr(buf, sizeof(buf), 1, vol);
      asprintf(&vol_text, _("Music: %s"), buf);
   }

   if (vol_text != NULL)
      window_modifyText(wid, widget, vol_text);

   free(vol_text);
}


/**
 * @brief Sets the sound or music volume string based on level.
 *
 *    @param[out] buf Buffer to use.
 *    @param max Maximum length of the buffer.
 *    @param type 0 for sound, 1 for audio.
 *    @param pos Position of the fader calling the function.
 */
static void opt_audioLevelStr( char *buf, int max, int type, double pos )
{
   double vol, magic;

   vol = type ? music_getVolumeLog() : sound_getVolumeLog();

   if (vol == 0.)
      snprintf(buf, max, _("Muted"));
   else {
      magic = -48. / log(0.00390625); /* -48 dB minimum divided by logarithm of volume floor. */
      snprintf(buf, max, _("%.0f%% (%.0f dB)"), pos * 100., log(vol) * magic);
   }
}


/**
 * @brief Opens the audio settings menu.
 */
static void opt_audio( unsigned int wid )
{
   (void) wid;
   int cw;
   int w, h, y, x;

   /* Get size. */
   window_dimWindow( wid, &w, &h );

   /* Close button */
   window_addButton( wid, -20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnClose", _("OK"), opt_OK );
   window_addButton( wid, -20 - 1*(BUTTON_WIDTH+20), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnCancel", _("Cancel"), opt_close );
   window_addButton( wid, -20 - 2*(BUTTON_WIDTH+20), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnDefaults", _("Defaults"), opt_audioDefaults );

   cw = (w-60)/2;
   x = 20;
   y = -60;
   window_addCheckbox( wid, x, y, cw, 20,
         "chkNosound", _("Disable all sound/music"), NULL, conf.nosound );
   y -= 25;

   window_addCheckbox( wid, x, y, cw, 20,
         "chkEFX", _("EFX (More CPU)"), NULL, conf.al_efx );


   /* Sound levels. */
   x = 20 + cw + 20;
   y = -60;

   window_addText(wid, x, y, cw-40, 20, 0, "txtSSoundVolume",
         NULL, NULL, _("Volume Levels"));
   y -= 30;
   /* Sound fader. */
   window_addText(wid, x, y, cw, 20, 1, "txtSound",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw, 20, "fadSound", 0., 1.,
         sound_getVolume(), opt_setAudioLevel);
   window_faderScrollDone(wid, "fadSound", opt_beep);
   y -= 30;
   /* Music fader. */
   window_addText(wid, x, y, cw, 20, 1, "txtMusic",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw, 20, "fadMusic", 0., 1.,
         music_getVolume(), opt_setAudioLevel);
   y -= 50;

   /* Restart text. */
   window_addText(wid, 20, 20 + BUTTON_HEIGHT,
         w - 40, 30, 0, "txtRestart", &gl_smallFont, NULL, NULL);

   opt_audioUpdate(wid);
}


static void opt_beep( unsigned int wid, char *str )
{
   (void) wid;
   (void) str;
   player_soundPlayGUI( snd_target, 1 );
}


/**
 * @brief Saves the audio stuff.
 */
static int opt_audioSave( unsigned int wid, char *str )
{
   (void) str;
   int f;

   f = window_checkboxState( wid, "chkNosound" );
   if (conf.nosound != f) {
      conf.nosound = f;
      opt_needRestart();
   }

   f = window_checkboxState( wid, "chkEFX" );
   if (conf.al_efx != f) {
      conf.al_efx = f;
      opt_needRestart();
   }

   /* Faders. */
   conf.sound = window_getFaderValue(wid, "fadSound");
   conf.music = window_getFaderValue(wid, "fadMusic");

   return 0;
}


/**
 * @brief Sets the audio defaults.
 */
static void opt_audioDefaults( unsigned int wid, char *str )
{
   (void) str;

   /* Set defaults. */
   /* Faders. */
   window_faderValue( wid, "fadSound", SOUND_VOLUME_DEFAULT );
   window_faderValue( wid, "fadMusic", MUSIC_VOLUME_DEFAULT );

   /* Checkboxes. */
   window_checkboxSet( wid, "chkNosound", MUTE_SOUND_DEFAULT );
   window_checkboxSet( wid, "chkEFX", USE_EFX_DEFAULT );
}


/**
 * @brief Updates the gameplay options.
 */
static void opt_audioUpdate( unsigned int wid )
{
   /* Checkboxes. */
   window_checkboxSet( wid, "chkNosound", conf.nosound );
   window_checkboxSet( wid, "chkEFX", conf.al_efx );

   /* Faders. */
   window_faderValue( wid, "fadSound", conf.sound );
   window_faderValue( wid, "fadMusic", conf.music );
}


/**
 * @brief Tries to set the key from an event.
 */
static int opt_setKeyEvent( unsigned int wid, SDL_Event *event )
{
   unsigned int parent;
   KeybindType type;
   int key, test_key_event;
   SDL_Keymod mod, ev_mod;
   const char *str;

   /* See how to handle it. */
   switch (event->type) {
      case SDL_KEYDOWN:
         key  = event->key.keysym.sym;
         /* If control key make player hit twice. */
         test_key_event = (key == SDLK_NUMLOCKCLEAR) ||
                          (key == SDLK_CAPSLOCK) ||
                          (key == SDLK_SCROLLLOCK) ||
                          (key == SDLK_RSHIFT) ||
                          (key == SDLK_LSHIFT) ||
                          (key == SDLK_RCTRL) ||
                          (key == SDLK_LCTRL) ||
                          (key == SDLK_RALT) ||
                          (key == SDLK_LALT) ||
                          (key == SDLK_RGUI) ||
                          (key == SDLK_LGUI);
         if (test_key_event  && (opt_lastKeyPress != key)) {
            opt_lastKeyPress = key;
            return 0;
         }
         type = KEYBIND_KEYBOARD;
         if (window_checkboxState( wid, "chkAny" ))
            mod = NMOD_ANY;
         else {
            ev_mod = event->key.keysym.mod;
            mod    = 0;
            if (ev_mod & (KMOD_LSHIFT | KMOD_RSHIFT))
               mod |= NMOD_SHIFT;
            if (ev_mod & (KMOD_LCTRL | KMOD_RCTRL))
               mod |= NMOD_CTRL;
            if (ev_mod & (KMOD_LALT | KMOD_RALT))
               mod |= NMOD_ALT;
            if (ev_mod & (KMOD_LGUI | KMOD_RGUI))
               mod |= NMOD_META;
         }
         /* Set key. */
         opt_lastKeyPress = key;
         break;

      case SDL_JOYAXISMOTION:
         if (event->jaxis.value > 0)
            type = KEYBIND_JAXISPOS;
         else if (event->jaxis.value < 0)
            type = KEYBIND_JAXISNEG;
         else
            return 0; /* Not handled. */
         key  = event->jaxis.axis;
         mod  = NMOD_ANY;
         break;

      case SDL_JOYBUTTONDOWN:
         type = KEYBIND_JBUTTON;
         key  = event->jbutton.button;
         mod  = NMOD_ANY;
         break;

      case SDL_JOYHATMOTION:
         switch (event->jhat.value) {
            case SDL_HAT_UP:
               type = KEYBIND_JHAT_UP;
               break;
            case SDL_HAT_DOWN:
               type = KEYBIND_JHAT_DOWN;
               break;
            case SDL_HAT_LEFT:
               type = KEYBIND_JHAT_LEFT;
               break;
            case SDL_HAT_RIGHT:
               type = KEYBIND_JHAT_RIGHT;
               break;
            default:
               return 0; /* Not handled. */
         }
         key  = event->jhat.hat;
         mod  = NMOD_ANY;
         break;

      /* Not handled. */
      default:
         return 0;
   }

   /* Warn if already bound. */
   str = input_keyAlreadyBound( type, key, mod );
   if ((str != NULL) && strcmp(str, opt_selectedKeybind))
      dialogue_alert( _("Key '%s' overlaps with key '%s' that was just set. "
            "You may want to correct this."),
            str, opt_selectedKeybind );

   /* Set keybinding. */
   input_setKeybind( opt_selectedKeybind, type, key, mod );

   /* Close window. */
   window_close( wid, NULL );

   /* Update parent window. */
   parent = window_getParent( wid );
   menuKeybinds_genList( parent );

   return 0;
}


/**
 * @brief Rebinds a key.
 */
static void opt_setKey( unsigned int wid, char *str )
{
   (void) wid;
   (void) str;
   unsigned int new_wid;
   int w, h;

   /* Reset key. */
   opt_lastKeyPress = 0;

   /* Create new window. */
   w = 20 + 2*(BUTTON_WIDTH + 20);
   h = 20 + BUTTON_HEIGHT + 20 + 20 + 80 + 40;
   new_wid = window_create( "wdwSetKey", _("Set Keybinding"), -1, -1, w, h );
   window_handleEvents( new_wid, opt_setKeyEvent );
   window_setParent( new_wid, wid );

   /* Set text. */
   window_addText( new_wid, 20, -40, w-40, 60, 0, "txtInfo",
         &gl_smallFont, NULL,
         _("To use a modifier key hit that key twice in a row, otherwise it "
         "will register as a modifier. To set with any modifier click the checkbox.") );

   /* Create button to cancel. */
   window_addButton( new_wid, -20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnCancel", _("Cancel"), window_close );

   /* Button to unset. */
   window_addButton( new_wid,  20, 20, BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnUnset",  _("Unset"), opt_unsetKey );

   /* Checkbox to set any modifier. */
   window_addCheckbox( new_wid, -20, 20 + BUTTON_HEIGHT + 20, w-40, 20,
         "chkAny", _("Set any modifier"), NULL, 0 );
}


/**
 * @brief Unsets the key.
 */
static void opt_unsetKey( unsigned int wid, char *str )
{
   (void) str;
   unsigned int parent;

   /* Unsets the keybind. */
   input_setKeybind( opt_selectedKeybind, KEYBIND_NULL, 0, 0 );

   /* Close window. */
   window_close( wid, NULL );

   /* Update parent window. */
   parent = window_getParent( wid );
   menuKeybinds_genList( parent );
}


/**
 * @brief Initializes the video window.
 */
static void opt_video( unsigned int wid )
{
   (void) wid;
   int i, k, n;
   int display_index;
   int def_missing;
   int duplicate_res;
   int res_def;
   char buf[STRMAX_SHORT];
   int cw;
   int w, h, y, x, l;
   char **res;
   int nres;
   char **colorblind_modes;
   int ncolorblind_modes;
   const char *s;

   /* Save originals. */
   opt_orig_colorblind = conf.colorblind;
   opt_orig_colorblind_mode = conf.colorblind_mode;
   opt_orig_scalefactor = conf.scalefactor;
   opt_orig_bg_brightness = conf.bg_brightness;
   opt_orig_gamma_correction = conf.gamma_correction;
   opt_orig_zoom_far = conf.zoom_far;
   opt_orig_zoom_near = conf.zoom_near;

   /* Get size. */
   window_dimWindow( wid, &w, &h );

   /* Close button */
   window_addButton( wid, -20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnClose", _("OK"), opt_OK );
   window_addButton( wid, -20 - 1*(BUTTON_WIDTH+20), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnCancel", _("Cancel"), opt_close );
   window_addButton( wid, -20 - 2*(BUTTON_WIDTH+20), 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnDefaults", _("Defaults"), opt_videoDefaults );

   /* Resolution bits. */
   cw = (w-60)/2;
   x = 20;
   y = -60;
   window_addText( wid, x, y, 100, 20, 0, "txtSRes",
         NULL, NULL, _("Resolution") );
   y -= 30;
   window_addInput( wid, x, y, 100, 20, "inpRes", 16, 1, &gl_smallFont );
   window_setInputFilter( wid, "inpRes", INPUT_FILTER_RESOLUTION );
   y -= 30;
   SDL_DisplayMode mode;
   display_index = SDL_GetWindowDisplayIndex(gl_screen.window);
   n = SDL_GetNumDisplayModes( display_index );
   def_missing = 1;
   for (i=0; i<n; i++) {
      SDL_GetDisplayMode( display_index, i, &mode  );
      if ((mode.w == RESOLUTION_W_DEFAULT) && (mode.h == RESOLUTION_H_DEFAULT))
         def_missing = 0;
   }
   res = malloc(sizeof(char*) * (i+def_missing));
   nres = 0;
   duplicate_res = 0;
   res_def = 0;
   if (def_missing) {
      asprintf(&res[0], "%dx%d", RESOLUTION_W_DEFAULT, RESOLUTION_H_DEFAULT);
      nres = 1;
   }
   for (i=0; i<n; i++) {
      SDL_GetDisplayMode(display_index, i, &mode);
      asprintf(&res[nres], "%dx%d", mode.w, mode.h);

      /* Make sure the mode doesn't already exist. If it does, count
       * the duplicate resolution so the index we use for setting the
       * default list position doesn't get downshifted. */
      for (k=0; k<nres; k++)
         if (strcmp(res[k], res[nres]) == 0)
            break;
      if (k < nres) {
         free(res[nres]);
         ++duplicate_res;
         continue;
      }

      /* Add as default if necessary and increment. */
      if ((mode.w == conf.width) && (mode.h == conf.height))
         res_def = i+def_missing - duplicate_res;
      nres++;
   }
   window_addList(wid, x, y, 140, 100, "lstRes",
         res, nres, -1, opt_videoRes, NULL);
   toolkit_setListPos(wid, "lstRes", res_def);

   y -= 120;

   window_addCheckbox( wid, x, y, 100, 20,
         "chkFullscreen", _("Fullscreen"), NULL, conf.fullscreen );
   y -= 25;

   /* Sets inpRes to current resolution, must be after lstRes is added
    * and after its initial selection is set, to prevent it from
    * overriding the real window size. */
   opt_resize();

   /* Checkboxes. */
   window_addCheckbox( wid, x, y, cw, 20,
         "chkVSync", _("Vertical Sync"), NULL, conf.vsync );
   y -= 25;
   window_addCheckbox(wid, x, y, cw, 20,
         "chkMinimize", _("Minimize on fullscreen focus loss"),
         NULL, conf.minimize);
   y -= 40;

   /* Colorblind simulator settings. */
   window_addCheckbox( wid, x, y, cw, 20,
         "chkColorblind", _("Colorblind simulator"), opt_checkColorblind,
         conf.colorblind );
   y -= 25;

   ncolorblind_modes = CBMODE_SENTINEL;
   colorblind_modes = malloc(sizeof(char*) * ncolorblind_modes);
   for (i=0; i<CBMODE_SENTINEL; i++) {
      switch (i) {
         case ROD_MONOCHROMACY:
            colorblind_modes[i] = strdup(_("Rod monochromacy"));
            break;

         case PROTANOPIA:
            colorblind_modes[i] = strdup(_("Protanopia"));
            break;

         case DEUTERANOPIA:
            colorblind_modes[i] = strdup(_("Deuteranopia"));
            break;

         case TRITANOPIA:
            colorblind_modes[i] = strdup(_("Tritanopia"));
            break;

         case CONE_MONOCHROMACY:
            colorblind_modes[i] = strdup(_("Cone monochromacy"));
            break;

         default:
            WARN("Failed to identify colorblind mode %d.", i);
            asprintf(&colorblind_modes[i], "%d", i);
      }
   }
   window_addList(wid, x, y, cw, 100, "lstColorblindMode",
         colorblind_modes, ncolorblind_modes, conf.colorblind_mode,
         opt_videoColorblindMode, NULL);
   y -= 100 + 20;

   /* FPS stuff. */
   s = _("FPS Limit");
   l = gl_printWidthRaw( &gl_smallFont, s );
   window_addText( wid, x, y, l, 20, 1, "txtSFPS",
         &gl_smallFont, NULL, s );
   window_addInput( wid, x+l+20, y, 60, 20, "inpFPS", 4, 1, &gl_smallFont );
   window_setInputFilter( wid, "inpFPS", INPUT_FILTER_NUMBER );
   snprintf( buf, sizeof(buf), "%d", conf.fps_max );
   window_setInput( wid, "inpFPS", buf );
   y -= 30;
   window_addCheckbox( wid, x, y, cw, 20,
         "chkFPS", _("Show FPS"), NULL, conf.fps_show );
   y -= 40;

   /* Faders. */
   x = 20+cw+20;
   y = -60;

   window_addText(wid, x, y, cw-20, 20, 1, "txtScale",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw-20, 20, "fadScale", 1., 3.,
         conf.scalefactor, opt_setScalefactor);
   opt_setScalefactor(wid, "fadScale");
   y -= 40;

   window_addText(wid, x, y, cw-20, 20, 1, "txtGamma",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw-20, 20, "fadGamma", 0.25, 3.,
         conf.gamma_correction, opt_setGamma);
   /* Not calling opt_setGamma since that would override values outside
    * of the slider's bounds (which are not an indication of any strict
    * limit). */
   snprintf(buf, sizeof(buf), _("Gamma: %.0f%%"), conf.gamma_correction * 100.);
   window_modifyText(wid, "txtGamma", buf);
   y -= 40;

   window_addText(wid, x, y-3, cw-20, 20, 1, "txtBGBrightness",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw-20, 20, "fadBGBrightness", 0., 1.,
         conf.bg_brightness, opt_setBGBrightness);
   opt_setBGBrightness(wid, "fadBGBrightness");
   y -= 40;

   window_addText(wid, x, y, cw-20, 20, 1, "txtMOpacity",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw-20, 20, "fadMapOverlayOpacity", 0., 1.,
         conf.map_overlay_opacity, opt_setMapOverlayOpacity);
   opt_setMapOverlayOpacity(wid, "fadMapOverlayOpacity");
   y -= 40;

   window_addText(wid, x, y, cw-20, 20, 1, "txtZoomFar",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw-20, 20, "fadZoomFar", 0.1, 2.,
         conf.zoom_far, opt_setZoomFar);
   opt_setZoomFar(wid, "fadZoomFar");
   y -= 40;

   window_addText(wid, x, y, cw-20, 20, 1, "txtZoomNear",
         &gl_smallFont, NULL, NULL);
   y -= 20;
   window_addFader(wid, x, y, cw-20, 20, "fadZoomNear", 0.1, 2.,
         conf.zoom_near, opt_setZoomNear);
   opt_setZoomNear(wid, "fadZoomNear");
   y -= 40;

   /* Restart text. */
   window_addText(wid, 20, 20 + BUTTON_HEIGHT,
         w - 40, 30, 0, "txtRestart", &gl_smallFont, NULL, NULL);
}

/**
 * @brief Marks that needs restart.
 */
static void opt_needRestart (void)
{
   const char *s;

   /* Values. */
   opt_restart = 1;
   s           = _("Restart Naikari for changes to take effect.");

   /* Modify widgets. */
   window_modifyText( opt_windows[ OPT_WIN_GAMEPLAY ], "txtRestart", s );
   window_modifyText( opt_windows[ OPT_WIN_VIDEO ], "txtRestart", s );
   window_modifyText( opt_windows[ OPT_WIN_AUDIO ], "txtRestart", s );
}


/**
 * @brief Callback when resolution changes.
 */
static void opt_videoRes( unsigned int wid, char *str )
{
   char *buf;
   buf = toolkit_getList( wid, str );
   window_setInput( wid, "inpRes", buf );
}


/**
 * @brief Saves the video settings.
 */
static int opt_videoSave( unsigned int wid, char *str )
{
   (void) str;
   char *inp;
   int ret, w, h, f, fullscreen;

   /* Handle resolution. */
   inp = window_getInput( wid, "inpRes" );
   ret = sscanf( inp, " %d %*[^0-9] %d", &w, &h );
   if (ret != 2 || w <= 0 || h <= 0) {
      dialogue_alert( _("Height/Width invalid. Should be formatted like 1024x768.") );
      return 1;
   }

   /* Fullscreen. */
   fullscreen = window_checkboxState( wid, "chkFullscreen" );

   /* Scale factor must be updated before the video mode is set. */
   conf.scalefactor = window_getFaderValue(wid, "fadScale");

   ret = opt_setVideoMode( w, h, fullscreen, 1 );
   window_checkboxSet( wid, "chkFullscreen", conf.fullscreen );
   if (ret != 0)
      return ret;

   /* FPS. */
   conf.fps_show = window_checkboxState( wid, "chkFPS" );
   inp = window_getInput( wid, "inpFPS" );
   conf.fps_max = atoi(inp);

   /* OpenGL. */
   f = window_checkboxState( wid, "chkVSync" );
   if (conf.vsync != f) {
      conf.vsync = f;
      opt_needRestart();
   }

   /* Features. */
   f = window_checkboxState( wid, "chkMinimize" );
   if (conf.minimize != f) {
      conf.minimize = f;
      SDL_SetHint( SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS,
            conf.minimize ? "1" : "0" );
   }

   /* Faders. */
   conf.bg_brightness = window_getFaderValue(wid, "fadBGBrightness");
   conf.map_overlay_opacity = window_getFaderValue(wid, "fadMapOverlayOpacity");
   conf.zoom_far = window_getFaderValue(wid, "fadZoomFar");
   conf.zoom_near = window_getFaderValue(wid, "fadZoomNear");

   /* Round these values to the nearest 1%. */
   conf.scalefactor = round(conf.scalefactor*100.) / 100.;
   conf.zoom_far = round(conf.zoom_far*100.) / 100.;
   conf.zoom_near = round(conf.zoom_near*100.) / 100.;

   /* Reinitialize stars in case zoom changed. */
   background_initStars(cur_system->stars);
   background_initDust();

   return 0;
}


/**
 * @brief Handles the colorblind checkbox being checked.
 */
static void opt_checkColorblind(wid_t wid, char *str)
{
   conf.colorblind = window_checkboxState(wid, str);
   gl_colorblind(conf.colorblind, conf.colorblind_mode);
}


/**
 * @brief Callback when colorblind mode changes.
 */
static void opt_videoColorblindMode(wid_t wid, char *str)
{
   conf.colorblind_mode = toolkit_getListPos(wid, str);
   gl_colorblind(conf.colorblind, conf.colorblind_mode);
}


/**
 * @brief Applies new video-mode options.
 *
 *    @param w Width of the video mode (if fullscreen) or window in screen coordinates (otherwise).
 *    @param h Height of the video mode (if fullscreen) or window in screen coordinates (otherwise).
 *    @param fullscreen Whether it's a fullscreen mode.
 *    @param confirm Whether to confirm the new settings.
 *    @return 0 on success.
 */
int opt_setVideoMode( int w, int h, int fullscreen, int confirm )
{
   int status;
   int old_w, old_h, old_f, new_w, new_h, new_f;
   int change_size_attempted, changed_size;

   opt_getVideoMode(&old_w, &old_h, &old_f);
   change_size_attempted = (w != old_w) || (h != old_h);

   conf.width = w;
   conf.height = h;
   conf.fullscreen = fullscreen;

   status = gl_setupFullscreen();
   if (status == 0 && !fullscreen && change_size_attempted) {
      /* Un-maximize the window if it is maximized. */
      if (SDL_GetWindowFlags(gl_screen.window) & SDL_WINDOW_MAXIMIZED)
         SDL_RestoreWindow(gl_screen.window);

      SDL_SetWindowSize(gl_screen.window, w, h);
      SDL_SetWindowPosition(gl_screen.window, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED);
   }
   naev_resize(conf.scalefactor != opt_orig_scalefactor);

   opt_getVideoMode(&new_w, &new_h, &new_f);
   changed_size = (new_w != old_w) || (new_h != old_h);

   if (confirm && (status != 0 || new_f != fullscreen))
      opt_needRestart();

   if (confirm && (status != 0 || changed_size || new_f != old_f) && !dialogue_YesNo(_("Keep Video Settings"),
         _("Do you want to keep running at %d×%d %s?"),
         new_w, new_h, new_f ? _("fullscreen") : _("windowed"))) {

      opt_setVideoMode( old_w, old_h, old_f, 0 );

      dialogue_msg( _("Video Settings Restored"),
            _("Resolution reset to %d×%d %s."),
            old_w, old_h, conf.fullscreen ? _("fullscreen") : _("windowed") );

      return 1;
   }

   conf.explicit_dim = conf.explicit_dim || w != old_w || h != old_h;
   return 0;
}


/**
 * @brief Detects the video-mode options corresponding to the gl_screen we have set up.
 *
 *    @param[out] w Width of the video mode (if fullscreen) or window in screen coordinates (otherwise).
 *    @param[out] h Height of the video mode (if fullscreen) or window in screen coordinates (otherwise).
 *    @param[out] fullscreen Whether it's a fullscreen mode.
 */
static void opt_getVideoMode( int *w, int *h, int *fullscreen )
{
   SDL_DisplayMode mode;
   /* Warning: this test may be inadequate depending on our setup.
    * Example (Wayland): if I called SDL_SetWindowDisplayMode with an impossibly large size, then SDL_SetWindowFullscreen,
    * I see a window on my desktop whereas SDL2 window flags report a fullscreen mode.
    * Mitigation: be strict about how the setup is done in opt_setVideoMode / gl_setupFullscreen, and never bypass them. */
   *fullscreen = (SDL_GetWindowFlags(gl_screen.window) & SDL_WINDOW_FULLSCREEN) != 0;
   if (*fullscreen && conf.modesetting) {
      SDL_GetWindowDisplayMode(gl_screen.window, &mode);
      *w = mode.w;
      *h = mode.h;
   }
   else
      SDL_GetWindowSize(gl_screen.window, w, h);
}


/**
 * @brief Sets video defaults.
 */
static void opt_videoDefaults( unsigned int wid, char *str )
{
   (void) str;
   char buf[STRMAX_SHORT];

   /* Restore settings. */
   /* Inputs. */
   snprintf(buf, sizeof(buf), "%dx%d", RESOLUTION_W_DEFAULT, RESOLUTION_H_DEFAULT);
   window_setInput(wid, "inpRes", buf);
   snprintf(buf, sizeof(buf), "%d", FPS_MAX_DEFAULT);
   window_setInput(wid, "inpFPS", buf);

   /* Checkboxes. */
   window_checkboxSet(wid, "chkFullscreen", FULLSCREEN_DEFAULT);
   window_checkboxSet(wid, "chkVSync", VSYNC_DEFAULT);
   window_checkboxSet(wid, "chkFPS", SHOW_FPS_DEFAULT);
   window_checkboxSet(wid, "chkMinimize", MINIMIZE_DEFAULT);

   /* Colorblind mode. */
   conf.colorblind = COLORBLIND_DEFAULT;
   conf.colorblind_mode = COLORBLIND_MODE_DEFAULT;
   window_checkboxSet(wid, "chkColorblind", conf.colorblind);
   toolkit_setListPos(wid, "lstColorblindMode", conf.colorblind_mode);

   /* Faders. */
   window_faderSetBoundedValue(wid, "fadScale", SCALE_FACTOR_DEFAULT);
   window_faderSetBoundedValue(wid, "fadGamma", GAMMA_CORRECTION_DEFAULT);
   window_faderSetBoundedValue(wid, "fadBGBrightness", BG_BRIGHTNESS_DEFAULT);
   window_faderSetBoundedValue(wid, "fadMapOverlayOpacity",
         MAP_OVERLAY_OPACITY_DEFAULT);
   window_faderSetBoundedValue(wid, "fadZoomFar", ZOOM_FAR_DEFAULT);
   window_faderSetBoundedValue(wid, "fadZoomNear", ZOOM_NEAR_DEFAULT);
}


/**
 * @brief Callback to set the scaling factor.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setScalefactor( unsigned int wid, char *str )
{
   char buf[STRMAX_SHORT];
   double scale = window_getFaderValue(wid, str);

   conf.scalefactor = round(scale*100.) / 100.;
   snprintf(buf, sizeof(buf), _("Scaling: %.0f%%"), conf.scalefactor * 100.);
   window_modifyText(wid, "txtScale", buf);
}


/**
 * @brief Callback to set the far zoom.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setZoomFar( unsigned int wid, char *str )
{
   char buf[STRMAX_SHORT];
   double zoom = window_getFaderValue(wid, str);

   conf.zoom_far = round(zoom*100.) / 100.;
   snprintf(buf, sizeof(buf), _("Far Zoom: %.0f%%"), conf.zoom_far * 100.);
   window_modifyText(wid, "txtZoomFar", buf);

   if (conf.zoom_far > conf.zoom_near) {
      window_faderSetBoundedValue(wid, "fadZoomNear", conf.zoom_far);
      opt_setZoomNear(wid, "fadZoomNear");
   }

   /* Reinitialize stars and dust. */
   if (FABS(conf.zoom_far - zoom) > 1e-4) {
      background_initStars(cur_system->stars);
      background_initDust();
   }
}


/**
 * @brief Callback to set the far zoom.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setZoomNear( unsigned int wid, char *str )
{
   char buf[STRMAX_SHORT];
   double zoom = window_getFaderValue(wid, str);

   conf.zoom_near = round(zoom*100.) / 100.;
   snprintf(buf, sizeof(buf), _("Near Zoom: %.0f%%"), conf.zoom_near * 100.);
   window_modifyText(wid, "txtZoomNear", buf);

   if (conf.zoom_near < conf.zoom_far) {
      window_faderSetBoundedValue(wid, "fadZoomFar", conf.zoom_near);
      opt_setZoomFar(wid, "fadZoomFar");
   }
}


/**
 * @brief Callback to set the background brightness.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setBGBrightness( unsigned int wid, char *str )
{
   char buf[STRMAX_SHORT];

   conf.bg_brightness = window_getFaderValue(wid, str);
   snprintf(buf, sizeof(buf), _("Background Brightness: %.0f%%"),
         conf.bg_brightness * 100.);
   window_modifyText(wid, "txtBGBrightness", buf);
}


/**
 * @brief Callback to set map overlay opacity.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setMapOverlayOpacity( unsigned int wid, char *str )
{
   char buf[STRMAX_SHORT];
   double map_overlay_opacity;

   /* Set fader. */
   map_overlay_opacity = window_getFaderValue(wid, str);
   snprintf(buf, sizeof(buf), _("Overlay Map Opacity: %.0f%%"),
         map_overlay_opacity * 100);
   window_modifyText( wid, "txtMOpacity", buf );
}


/**
 * @brief Callback to set map overlay opacity.
 *
 *    @param wid Window calling the callback.
 *    @param str Name of the widget calling the callback.
 */
static void opt_setGamma(unsigned int wid, char *str)
{
   char buf[STRMAX_SHORT];
   double gamma;

   /* Set fader. */
   gamma = window_getFaderValue(wid, str);
   conf.gamma_correction = round(gamma*100.) / 100.;
   snprintf(buf, sizeof(buf), _("Gamma: %.0f%%"), conf.gamma_correction * 100.);
   window_modifyText(wid, "txtGamma", buf);

   render_setGamma(conf.gamma_correction);
}
