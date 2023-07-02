/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef CONF_H
#  define CONF_H


#define RESOLUTION_W_MIN 1280 /**< Min width (below which we downscale). */
#define RESOLUTION_H_MIN 720 /**< Min height (below which we downscale). */
#define AFTERBURNER_SENSITIVITY 250 /**< Doubletap afterburn sensitivity. */

/**
 * CONFIGURATION DEFAULTS
 */
/* Gameplay option defaults */
#define MOUSE_DOUBLECLICK_TIME 0.5 /**< conf.mouse_doubleclick */
#define MANUAL_ZOOM_DEFAULT 0 /**< conf.zoom_manual */
#define DOUBLETAP_AFTERBURN_DEFAULT 0 /**< conf.doubletap_afterburn */
#define SAVE_COMPRESSION_DEFAULT 1 /**< conf.save_compress */
#define INPUT_MESSAGES_DEFAULT 5 /**< conf.mesg_visible */
#define TIME_COMPRESSION_DEFAULT_MAX 5000. /**< conf.compression_velocity */
#define TIME_COMPRESSION_DEFAULT_MULT 200. /**< conf.compression_mult */
#define DT_MOD_DEFAULT 1. /**< conf.dt_mod */
#define AUTONAV_RESET_SPEED_DEFAULT 1. /**< conf.autonav_reset_speed */
/* Video option defaults */
#define RESOLUTION_W_DEFAULT RESOLUTION_W_MIN /**< conf.width */
#define RESOLUTION_H_DEFAULT RESOLUTION_H_MIN /**< conf.height */
#define RESIZABLE_DEFAULT 1 /**< conf.resizable */
#define FULLSCREEN_DEFAULT 0 /**< conf.fullscreen */
#define FULLSCREEN_MODESETTING 0 /**< conf.modesetting */
#define FSAA_DEFAULT 1 /**< conf.fsaa */
#define VSYNC_DEFAULT 0 /**< conf.vsync */
#define MINIMIZE_DEFAULT 1 /**< conf.minimize */
#define COLORBLIND_DEFAULT 0 /**< conf.colorblind */
#define FPS_MAX_DEFAULT 60 /**< conf.fps_max */
#define SHOW_FPS_DEFAULT 0 /**< conf.fps_show */
#define SHOW_PAUSE_DEFAULT 1 /**< conf.pause_show */
#define SCALE_FACTOR_DEFAULT 1. /**< conf.scalefactor */
#define NEBULA_SCALE_FACTOR_DEFAULT 4. /**< conf.nebu_scale */
#define GAMMA_CORRECTION_DEFAULT 1. /**< conf.gamma_correction */
#define BG_BRIGHTNESS_DEFAULT 1. /**< conf.bg_brightness */
#define MAP_OVERLAY_OPACITY_DEFAULT 0.55 /**< conf.map_overlay_opacity */
#define ZOOM_FAR_DEFAULT 0.5 /**< conf.zoom_far */
#define ZOOM_NEAR_DEFAULT 1. /**< conf.zoom_near */
/* Audio option defaults */
#define MUTE_SOUND_DEFAULT 0 /**< conf.nosound */
#define USE_EFX_DEFAULT 1 /**< conf.al_efx */
#define SOUND_VOLUME_DEFAULT 0.6 /**< conf.sound */
#define MUSIC_VOLUME_DEFAULT 0.8 /**< conf.music */
/* Font size defaults */
#define FONT_SIZE_CONSOLE_DEFAULT 10 /**< conf.font_size_console */
#define FONT_SIZE_INTRO_DEFAULT 18 /**< conf.font_size_intro */
#define FONT_SIZE_DEF_DEFAULT 14 /**< conf.font_size_def */
#define FONT_SIZE_SMALL_DEFAULT 11 /**< conf.font_size_small */
/* Debugging option defaults */
#define REDIRECT_FILE_DEFAULT 1 /**< conf.redirect_file */
/* Editor option defaults */
#define DEV_SAVE_SYSTEM_DEFAULT "../dat/ssys/" /**< conf.dev_save_sys */
#define DEV_SAVE_ASSET_DEFAULT "../dat/assets/" /**< conf.dev_save_asset */
#define DEV_SAVE_MAP_DEFAULT "../dat/outfits/maps/" /**< conf.dev_save_map */


/**
 * @brief Struct containing player options.
 *
 * @note Input is not handled here.
 */
typedef struct PlayerConf_s {

   /* ndata. */
   char *ndata; /**< Ndata path to use. */
   char *datapath; /**< Path for user data (saves, screenshots, etc.). */

   /* Language. */
   char *language; /**< Language to use. */

   /* Gameplay options */
   double mouse_doubleclick; /**< How long to consider double-clicks for. */
   int zoom_manual; /**< Whether zoom is under manual control. */
   int doubletap_afterburn; /**< Whether double-tapping thrust afterburns. */
   int save_compress; /**< Whether to compress saved games. */
   int mesg_visible; /**< Amount of visible messages. */
   double compression_velocity; /**< Velocity to compress to. */
   double compression_mult; /**< Maximum time multiplier. */
   double dt_mod; /**< Static modifier of dt applied to the game as a whole. */

   /**
    * Shield level (0-1) to reset autonav speed.
    * 1 means at enemy presence, 0 means at armor damage.
    */
   double autonav_reset_speed;

   /* Video options */
   int width; /**< Width of the window to use. */
   int height; /**< Height of the window to use. */
   int explicit_dim; /**< Dimension is explicit. */
   int resizable; /**< Whether or not window is resizable. */
   int borderless; /**< Whether to disable window decorations. */
   int fullscreen; /**< Whether or not game is fullscreen. */
   int modesetting; /**< Whether to use modesetting for fullscreen. */
   int fsaa; /**< Full Scene Anti-Aliasing to use. */
   int vsync; /**< Whether or not to use vsync. */
   int minimize; /**< Whether to minimize on focus loss. */
   int colorblind; /**< Whether to enable colorblindness simulation. */
   int fps_max; /**< Maximum FPS to limit to. */
   int fps_show; /**< Whether or not FPS should be shown */
   int pause_show; /**< Whether pause status should be shown. */
   double scalefactor; /**< Scale factor (for high DPI) */
   double nebu_scale; /**< Nebula scale factor (for reducing render expense) */
   double gamma_correction; /**< How much gamma correction to do. */
   double bg_brightness; /**< Background brightness. */
   double map_overlay_opacity; /**< Map overlay opacity. */
   double zoom_far; /**< Far zoom distance (smaller is further) */
   double zoom_near; /**< Near zoom distance (larger is closer) */

   /* Audio options */
   int nosound; /**< Whether to disable all audio. */
   int al_efx; /**< Whether to use EFX. */
   double sound; /**< Volume level for sound effects. */
   double music; /**< Volume level for music. */

   /* Joystick. */
   int joystick_ind; /**< Index of joystick to use. */
   char *joystick_nam; /**< Name of joystick to use. */

   /* Keyrepeat. */
   unsigned int repeat_delay; /**< Time in ms before start repeating. */
   unsigned int repeat_freq; /**< Time in ms between each repeat once started repeating. */

   /* Zoom. */
   double zoom_speed; /**< Maximum zoom speed change. */
   double zoom_stars; /**< How much stars can zoom (modulates zoom_[mix|max]). */

   /* Font sizes. */
   int font_size_console; /**< Console monospaced font size. */
   int font_size_intro; /**< Intro text font size. */
   int font_size_def; /**< Default (large) font size. */
   int font_size_small; /**< Small font size. */

   /* Misc. */
   int nosave; /**< Disables conf saving. */
   int devmode; /**< Developer mode. */
   int devautosave; /**< Developer mode autosave. */
   char *lastversion; /**< The last version the game was ran in. */

   /* Debugging. */
   int redirect_file; /**< Whether to redirect logs and errors to files. */
   int fpu_except; /**< Enable FPU exceptions? */

   /* Editor. */
   char *dev_save_sys; /**< Path to save systems to. */
   char *dev_save_asset; /**< Path to save assets to. */
   char *dev_save_map; /**< Path to save maps to. */

} PlayerConf_t;
extern PlayerConf_t conf; /**< Player configuration. */


/*
 * loading
 */
void conf_setDefaults (void);
void conf_setGameplayDefaults (void);
void conf_setAudioDefaults (void);
void conf_setVideoDefaults (void);
void conf_loadConfigPath( void );
int conf_loadConfig( const char* file );
void conf_parseCLI( int argc, char** argv );
void conf_cleanup (void);

/*
 * saving
 */
int conf_saveConfig( const char* file );


#endif /* CONF_H */
