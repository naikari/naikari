/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file input.c
 *
 * @brief Handles all the keybindings and input.
 */


/** @cond */
#include "naev.h"
/** @endcond */

#include "input.h"

#include "array.h"
#include "board.h"
#include "camera.h"
#include "conf.h"
#include "console.h"
#include "escort.h"
#include "gui.h"
#include "hook.h"
#include "info.h"
#include "land.h"
#include "log.h"
#include "map.h"
#include "map_overlay.h"
#include "menu.h"
#include "nstring.h"
#include "pause.h"
#include "pilot.h"
#include "player.h"
#include "toolkit.h"
#include "weapon.h"
#include "utf8.h"


#define MOUSE_HIDE   ( 3.) /**< Time in seconds to wait before hiding mouse again. */


/* keybinding structure */
/**
 * @brief Naev Keybinding.
 */
typedef struct Keybind_ {
   int disabled; /**< Whether or not it's disabled. */
   const char *name; /**< keybinding name, taken from keybind_info */
   KeybindType type; /**< type, defined in player.h */
   SDL_Keycode key; /**< key/axis/button event number */
   SDL_Keymod mod; /**< Key modifiers (where applicable). */
} Keybind;


/* name of each keybinding */
const char *keybind_info[][3] = {
   /* Movement */
   {"accel", N_("Accelerate"), N_("Makes your ship accelerate forward.")},
   {"left", N_("Turn Left"), N_("Makes your ship turn left.")},
   {"right", N_("Turn Right"), N_("Makes your ship turn right.")},
   {"reverse", N_("Reverse"),
      N_("Makes your ship face the direction you're moving from. Useful for"
         " braking.")},
   /* Targeting */
   {"target_next", N_("Target Next"), N_("Cycles thru ship targets.")},
   {"target_prev", N_("Target Previous"),
      N_("Cycles backwards thru ship targets.")},
   {"target_nearest", N_("Target Nearest"),
      N_("Targets the nearest non-disabled ship.")},
   {"target_nextHostile", N_("Target Next Hostile"),
      N_("Cycles thru hostile ship targets.")},
   {"target_prevHostile", N_("Target Previous Hostile"),
      N_("Cycles backwards thru hostile ship targets.")},
   {"target_hostile", N_("Target Nearest Hostile"),
      N_("Targets the nearest hostile ship.")},
   {"target_clear", N_("Clear Target"),
      N_("Clears the currently-targeted ship, planet or jump point.")},
   /* Fighting */
   {"primary", N_("Fire Primary Weapon"), N_("Fires primary weapons.")},
   {"face", N_("Face Target"),
      N_("Faces the targeted ship if one is targeted, otherwise faces targeted"
         " planet or jump point.")},
   {"follow", N_("Follow Target"), N_("Follows the targeted ship.")},
   {"board", N_("Board Target"), N_("Attempts to board the targeted ship.")},
   {"local_jump", N_("Escape Jump"),
      N_("Performs a local jump without entering hyperspace, to escape"
         " dangerous situations.")},
   /* Secondary Weapons */
   {"secondary", N_("Fire Secondary Weapon"), N_("Fires secondary weapons.")},
   {"weapset1", N_("Weapon Set 1"), N_("Activates weapon set 1.")},
   {"weapset2", N_("Weapon Set 2"), N_("Activates weapon set 2.")},
   {"weapset3", N_("Weapon Set 3"), N_("Activates weapon set 3.")},
   {"weapset4", N_("Weapon Set 4"), N_("Activates weapon set 4.")},
   {"weapset5", N_("Weapon Set 5"), N_("Activates weapon set 5.")},
   {"weapset6", N_("Weapon Set 6"), N_("Activates weapon set 6.")},
   {"weapset7", N_("Weapon Set 7"), N_("Activates weapon set 7.")},
   {"weapset8", N_("Weapon Set 8"), N_("Activates weapon set 8.")},
   {"weapset9", N_("Weapon Set 9"), N_("Activates weapon set 9.")},
   {"weapset0", N_("Weapon Set 0"), N_("Activates weapon set 0.")},
   /* Escorts */
   {"e_targetNext", N_("Target Next Escort"),
      N_("Cycles thru your escorts.")},
   {"e_targetPrev", N_("Target Previous Escort"),
      N_("Cycles backwards thru your escorts.")},
   {"e_attack", N_("Escort Attack Command"),
      N_("Orders escorts to attack your target.")},
   {"e_hold", N_("Escort Hold Command"),
      N_("Orders escorts to hold their positions in the formation.")},
   {"e_return", N_("Escort Return Command"),
      N_("Orders escorts to return to and (if applicable) dock onto your"
         " ship.")},
   {"e_clear", N_("Escort Clear Commands"),
      N_("Clears your escorts of commands.")},
   /* Space Navigation */
   {"autonav", N_("Autonavigation On"),
      N_("Initializes the autonavigation system.")},
   {"target_planet", N_("Target Planet"), N_("Cycles thru planet targets.")},
   {"land", N_("Land"),
      N_("Attempts to land on the targeted planet or targets the nearest"
         " landable planet. Requests permission if necessary.")},
   {"thyperspace", N_("Target Jumpgate"), N_("Cycles thru jump points.")},
   {"starmap", N_("Open Star Map"), N_("Opens the star map.")},
   {"jump", N_("Initiate Jump"), N_("Attempts to jump via a jump point.")},
   {"overlay", N_("Overlay Map"), N_("Opens the in-system overlay map.")},
   {"mousefly", N_("Mouse Flight"), N_("Toggles mouse flying.")},
   {"autobrake", N_("Active Cooldown"),
      N_("Automatically stops the ship and begins active cooldown.")},
   /* Communication */
   {"log_up", N_("Log Scroll Up"),
      N_("Scrolls the message log upwards.")},
   {"log_down", N_("Log Scroll Down"),
      N_("Scrolls the message log downwards.")},
   {"hail", N_("Hail Target"),
      N_("Attempts to initialize communication with the targeted ship.")},
   {"autohail", N_("Autohail"),
      N_("Automatically initializes communication with a ship that is hailing"
         " you.")},
   /* Misc. */
   {"mapzoomin", N_("Radar Zoom In"), N_("Zooms in on the radar.")},
   {"mapzoomout", N_("Radar Zoom Out"), N_("Zooms out on the radar.")},
   {"screenshot", N_("Screenshot"), N_("Takes a screenshot.")},
   {"togglefullscreen", N_("Toggle Fullscreen"),
      N_("Toggles between windowed and fullscreen mode.")},
   {"pause", N_("Pause"), N_("Pauses the game.")},
   {"speed", N_("Toggle Speed"), N_("Toggles speed modifier.")},
   {"menu", N_("Small Menu"), N_("Opens the small in-game menu.")},
   {"info", N_("Ship Computer"), N_("Opens the ship computer.")},
   {"console", N_("Lua Console"), N_("Opens the Lua console.")},
   {"switchtab1", N_("Switch Tab 1"), N_("Switches to tab 1.")},
   {"switchtab2", N_("Switch Tab 2"), N_("Switches to tab 2.")},
   {"switchtab3", N_("Switch Tab 3"), N_("Switches to tab 3.")},
   {"switchtab4", N_("Switch Tab 4"), N_("Switches to tab 4.")},
   {"switchtab5", N_("Switch Tab 5"), N_("Switches to tab 5.")},
   {"switchtab6", N_("Switch Tab 6"), N_("Switches to tab 6.")},
   {"switchtab7", N_("Switch Tab 7"), N_("Switches to tab 7.")},
   {"switchtab8", N_("Switch Tab 8"), N_("Switches to tab 8.")},
   {"switchtab9", N_("Switch Tab 9"), N_("Switches to tab 9.")},
   {"switchtab0", N_("Switch Tab 0"), N_("Switches to tab 0.")},
   /* Console-main. */
   {"paste", N_("Paste"), N_("Paste from the operating system's clipboard.")},
   /* Must terminate in NULL. */
   {NULL, NULL, NULL}
}; /**< Names of possible keybindings. */

static Keybind *input_keybinds; /**< contains the players keybindings */
const int input_numbinds = ( sizeof( keybind_info ) / sizeof( keybind_info[ 0 ] ) ) - 1; /**< Number of keybindings. */
static Keybind *input_paste;


/*
 * accel hacks
 */
static Uint32 input_accelLast = 0; /**< Used to see if double tap */
static int input_accelButton = 0; /**< Used to show whether accel is pressed. */


/*
 * Key repeat hack.
 */
static int repeat_key = -1; /**< Key to repeat. */
static Uint32 repeat_keyTimer = 0;  /**< Repeat timer. */
static unsigned int repeat_keyCounter = 0;  /**< Counter for key repeats. */


/*
 * Mouse.
 */
static double input_mouseTimer = -1.; /**< Timer for hiding again. */
static int input_mouseCounter = 1; /**< Counter for mouse display/hiding. */
static Uint32 input_mouseClickLast = 0; /**< Time of last click (in ms) */
static void *input_lastClicked = NULL; /**< Pointer to the last-clicked item. */


/*
 * from player.c
 */
extern double player_left;  /**< player.c */
extern double player_right; /**< player.c */


/*
 * Prototypes.
 */
static void input_key( int keynum, double value, double kabs, int repeat );
static void input_clickZoom( double modifier );
static void input_clickevent( SDL_Event* event );
static void input_mouseMove( SDL_Event* event );


/**
 * @brief Sets the default input keys.
 *
 *    @param layout The layout to assign.
 */
void input_setDefault(int layout)
{
   /* Movement */
   if (layout == LAYOUT_WASD) {
      input_setKeybind("accel", KEYBIND_KEYBOARD, SDLK_w, NMOD_ANY);
      input_setKeybind("left", KEYBIND_KEYBOARD, SDLK_a, NMOD_ANY);
      input_setKeybind("right", KEYBIND_KEYBOARD, SDLK_d, NMOD_ANY);
      input_setKeybind("reverse", KEYBIND_KEYBOARD, SDLK_s, NMOD_ANY);
   }
   else if (layout == LAYOUT_ZQSD) {
      input_setKeybind("accel", KEYBIND_KEYBOARD, SDLK_z, NMOD_ANY);
      input_setKeybind("left", KEYBIND_KEYBOARD, SDLK_q, NMOD_ANY);
      input_setKeybind("right", KEYBIND_KEYBOARD, SDLK_d, NMOD_ANY);
      input_setKeybind("reverse", KEYBIND_KEYBOARD, SDLK_s, NMOD_ANY);
   }
   else if (layout == LAYOUT_IJKL) {
      input_setKeybind("accel", KEYBIND_KEYBOARD, SDLK_i, NMOD_ANY);
      input_setKeybind("left", KEYBIND_KEYBOARD, SDLK_j, NMOD_ANY);
      input_setKeybind("right", KEYBIND_KEYBOARD, SDLK_l, NMOD_ANY);
      input_setKeybind("reverse", KEYBIND_KEYBOARD, SDLK_k, NMOD_ANY);
   }
   else {
      input_setKeybind("accel", KEYBIND_KEYBOARD, SDLK_UP, NMOD_ANY);
      input_setKeybind("left", KEYBIND_KEYBOARD, SDLK_LEFT, NMOD_ANY);
      input_setKeybind("right", KEYBIND_KEYBOARD, SDLK_RIGHT, NMOD_ANY);
      input_setKeybind("reverse", KEYBIND_KEYBOARD, SDLK_DOWN, NMOD_ANY);
   }

   /* Targeting */
   if (layout == LAYOUT_WASD) {
      input_setKeybind("target_next", KEYBIND_KEYBOARD, SDLK_t, NMOD_NONE);
      input_setKeybind("target_prev", KEYBIND_KEYBOARD, SDLK_t, NMOD_CTRL);
      input_setKeybind("target_nearest", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_nextHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_prevHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_hostile", KEYBIND_KEYBOARD, SDLK_r, NMOD_ANY);
      input_setKeybind("target_clear", KEYBIND_KEYBOARD, SDLK_c, NMOD_ANY);
   }
   else if (layout == LAYOUT_ZQSD) {
      input_setKeybind("target_next", KEYBIND_KEYBOARD, SDLK_t, NMOD_NONE);
      input_setKeybind("target_prev", KEYBIND_KEYBOARD, SDLK_t, NMOD_CTRL);
      input_setKeybind("target_nearest", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_nextHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_prevHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_hostile", KEYBIND_KEYBOARD, SDLK_r, NMOD_ANY);
      input_setKeybind("target_clear", KEYBIND_KEYBOARD, SDLK_c, NMOD_ANY);
   }
   else if (layout == LAYOUT_IJKL) {
      input_setKeybind("target_next", KEYBIND_KEYBOARD, SDLK_p, NMOD_NONE);
      input_setKeybind("target_prev", KEYBIND_KEYBOARD, SDLK_p, NMOD_CTRL);
      input_setKeybind("target_nearest", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_nextHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_prevHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_hostile", KEYBIND_KEYBOARD, SDLK_o, NMOD_ANY);
      input_setKeybind("target_clear", KEYBIND_KEYBOARD, SDLK_BACKSPACE, NMOD_ANY);
   }
   else {
      input_setKeybind("target_next", KEYBIND_KEYBOARD, SDLK_t, NMOD_NONE);
      input_setKeybind("target_prev", KEYBIND_KEYBOARD, SDLK_t, NMOD_CTRL);
      input_setKeybind("target_nearest", KEYBIND_KEYBOARD, SDLK_n, NMOD_ANY);
      input_setKeybind("target_nextHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_prevHostile", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE);
      input_setKeybind("target_hostile", KEYBIND_KEYBOARD, SDLK_r, NMOD_ANY);
      input_setKeybind("target_clear", KEYBIND_KEYBOARD, SDLK_BACKSPACE, NMOD_ANY);
   }

   /* Combat */
   input_setKeybind( "primary", KEYBIND_KEYBOARD, SDLK_SPACE, NMOD_ANY );

   if (layout == LAYOUT_WASD) {
      input_setKeybind("face", KEYBIND_KEYBOARD, SDLK_e, NMOD_ANY);
      input_setKeybind("local_jump", KEYBIND_KEYBOARD, SDLK_q, NMOD_ANY);
   }
   else if (layout == LAYOUT_ZQSD) {
      input_setKeybind("face", KEYBIND_KEYBOARD, SDLK_e, NMOD_ANY);
      input_setKeybind("local_jump", KEYBIND_KEYBOARD, SDLK_a, NMOD_ANY);
   }
   else if (layout == LAYOUT_IJKL) {
      input_setKeybind("face", KEYBIND_KEYBOARD, SDLK_u, NMOD_ANY);
      input_setKeybind("local_jump", KEYBIND_KEYBOARD, SDLK_h, NMOD_ANY);
   }
   else {
      input_setKeybind("face", KEYBIND_KEYBOARD, SDLK_a, NMOD_ANY);
      input_setKeybind("local_jump", KEYBIND_KEYBOARD, SDLK_e, NMOD_ANY);
   }

   input_setKeybind("follow", KEYBIND_KEYBOARD, SDLK_f, NMOD_NONE);
   input_setKeybind("board", KEYBIND_KEYBOARD, SDLK_b, NMOD_NONE);
   /* Secondary Weapons */
   input_setKeybind( "secondary", KEYBIND_KEYBOARD, SDLK_LSHIFT, NMOD_ANY );
   input_setKeybind( "weapset1", KEYBIND_KEYBOARD, SDLK_1, NMOD_ANY );
   input_setKeybind( "weapset2", KEYBIND_KEYBOARD, SDLK_2, NMOD_ANY );
   input_setKeybind( "weapset3", KEYBIND_KEYBOARD, SDLK_3, NMOD_ANY );
   input_setKeybind( "weapset4", KEYBIND_KEYBOARD, SDLK_4, NMOD_ANY );
   input_setKeybind( "weapset5", KEYBIND_KEYBOARD, SDLK_5, NMOD_ANY );
   input_setKeybind( "weapset6", KEYBIND_KEYBOARD, SDLK_6, NMOD_ANY );
   input_setKeybind( "weapset7", KEYBIND_KEYBOARD, SDLK_7, NMOD_ANY );
   input_setKeybind( "weapset8", KEYBIND_KEYBOARD, SDLK_8, NMOD_ANY );
   input_setKeybind( "weapset9", KEYBIND_KEYBOARD, SDLK_9, NMOD_ANY );
   input_setKeybind( "weapset0", KEYBIND_KEYBOARD, SDLK_0, NMOD_ANY );
   /* Escorts */
   input_setKeybind( "e_targetNext", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE );
   input_setKeybind( "e_targetPrev", KEYBIND_NULL, SDLK_UNKNOWN, NMOD_NONE );
   input_setKeybind( "e_attack", KEYBIND_KEYBOARD, SDLK_END, NMOD_ANY );
   input_setKeybind( "e_hold", KEYBIND_KEYBOARD, SDLK_INSERT, NMOD_ANY );
   input_setKeybind( "e_return", KEYBIND_KEYBOARD, SDLK_DELETE, NMOD_ANY );
   input_setKeybind( "e_clear", KEYBIND_KEYBOARD, SDLK_HOME, NMOD_ANY );
   /* Space Navigation */
   input_setKeybind( "starmap", KEYBIND_KEYBOARD, SDLK_m, NMOD_NONE );
   input_setKeybind( "overlay", KEYBIND_KEYBOARD, SDLK_TAB, NMOD_ANY );
   input_setKeybind( "mousefly", KEYBIND_KEYBOARD, SDLK_x, NMOD_CTRL );
   input_setKeybind( "autobrake", KEYBIND_KEYBOARD, SDLK_b, NMOD_CTRL );

   if (layout == LAYOUT_IJKL)
   {
      input_setKeybind("target_planet", KEYBIND_KEYBOARD, SDLK_s, NMOD_NONE);
      input_setKeybind("land", KEYBIND_KEYBOARD, SDLK_d, NMOD_NONE);
      input_setKeybind("thyperspace", KEYBIND_KEYBOARD, SDLK_w, NMOD_NONE);
      input_setKeybind("autonav", KEYBIND_KEYBOARD, SDLK_n, NMOD_CTRL);
      input_setKeybind("jump", KEYBIND_KEYBOARD, SDLK_n, NMOD_NONE);
   }
   else
   {
      input_setKeybind("target_planet", KEYBIND_KEYBOARD, SDLK_p, NMOD_NONE);
      input_setKeybind("land", KEYBIND_KEYBOARD, SDLK_l, NMOD_NONE);
      input_setKeybind("thyperspace", KEYBIND_KEYBOARD, SDLK_h, NMOD_NONE);
      input_setKeybind("autonav", KEYBIND_KEYBOARD, SDLK_j, NMOD_CTRL);
      input_setKeybind("jump", KEYBIND_KEYBOARD, SDLK_j, NMOD_NONE);
   }
   /* Communication */
   input_setKeybind("log_up", KEYBIND_KEYBOARD, SDLK_PAGEUP, NMOD_NONE);
   input_setKeybind("log_down", KEYBIND_KEYBOARD, SDLK_PAGEDOWN, NMOD_NONE);
   input_setKeybind("hail", KEYBIND_KEYBOARD, SDLK_y, NMOD_NONE);
   input_setKeybind("autohail", KEYBIND_KEYBOARD, SDLK_y, NMOD_CTRL);
   /* Misc. */
   input_setKeybind( "mapzoomin", KEYBIND_KEYBOARD, SDLK_KP_PLUS, NMOD_ANY );
   input_setKeybind( "mapzoomout", KEYBIND_KEYBOARD, SDLK_KP_MINUS, NMOD_ANY );
   input_setKeybind( "screenshot", KEYBIND_KEYBOARD, SDLK_KP_MULTIPLY, NMOD_ANY );
   input_setKeybind( "togglefullscreen", KEYBIND_KEYBOARD, SDLK_F11, NMOD_ANY );
   input_setKeybind( "pause", KEYBIND_KEYBOARD, SDLK_PAUSE, NMOD_ANY );

   input_setKeybind( "speed", KEYBIND_KEYBOARD, SDLK_BACKQUOTE, NMOD_ANY );
   input_setKeybind( "menu", KEYBIND_KEYBOARD, SDLK_ESCAPE, NMOD_ANY );
   input_setKeybind( "console", KEYBIND_KEYBOARD, SDLK_F2, NMOD_ANY );
   input_setKeybind( "switchtab1", KEYBIND_KEYBOARD, SDLK_1, NMOD_ALT );
   input_setKeybind( "switchtab2", KEYBIND_KEYBOARD, SDLK_2, NMOD_ALT );
   input_setKeybind( "switchtab3", KEYBIND_KEYBOARD, SDLK_3, NMOD_ALT );
   input_setKeybind( "switchtab4", KEYBIND_KEYBOARD, SDLK_4, NMOD_ALT );
   input_setKeybind( "switchtab5", KEYBIND_KEYBOARD, SDLK_5, NMOD_ALT );
   input_setKeybind( "switchtab6", KEYBIND_KEYBOARD, SDLK_6, NMOD_ALT );
   input_setKeybind( "switchtab7", KEYBIND_KEYBOARD, SDLK_7, NMOD_ALT );
   input_setKeybind( "switchtab8", KEYBIND_KEYBOARD, SDLK_8, NMOD_ALT );
   input_setKeybind( "switchtab9", KEYBIND_KEYBOARD, SDLK_9, NMOD_ALT );
   input_setKeybind( "switchtab0", KEYBIND_KEYBOARD, SDLK_0, NMOD_ALT );
   input_setKeybind( "paste", KEYBIND_KEYBOARD, SDLK_v, NMOD_CTRL );

   if (layout == LAYOUT_IJKL) {
      input_setKeybind("info", KEYBIND_KEYBOARD, SDLK_c, NMOD_NONE);
   }
   else {
      input_setKeybind("info", KEYBIND_KEYBOARD, SDLK_i, NMOD_NONE);
   }
}


/**
 * @brief Initializes the input subsystem (does not set keys).
 */
void input_init (void)
{
   Keybind *temp;
   int i;

   /* Window. */
   SDL_EventState( SDL_SYSWMEVENT,      SDL_DISABLE );

   /* Keyboard. */
   SDL_EventState( SDL_KEYDOWN,         SDL_ENABLE );
   SDL_EventState( SDL_KEYUP,           SDL_ENABLE );

   /* Mice. */
   SDL_EventState( SDL_MOUSEMOTION,     SDL_ENABLE );
   SDL_EventState( SDL_MOUSEBUTTONDOWN, SDL_ENABLE );
   SDL_EventState( SDL_MOUSEBUTTONUP,   SDL_ENABLE );

   /* Joystick, enabled in joystick.c if needed. */
   SDL_EventState( SDL_JOYAXISMOTION,   SDL_DISABLE );
   SDL_EventState( SDL_JOYHATMOTION,    SDL_DISABLE );
   SDL_EventState( SDL_JOYBUTTONDOWN,   SDL_DISABLE );
   SDL_EventState( SDL_JOYBUTTONUP,     SDL_DISABLE );

   /* Quit. */
   SDL_EventState( SDL_QUIT,            SDL_ENABLE );

   /* Window. */
   SDL_EventState( SDL_WINDOWEVENT,     SDL_ENABLE );

   /* Keyboard. */
   SDL_EventState( SDL_TEXTINPUT,       SDL_DISABLE); /* Enabled on a per-widget basis. */

   /* Mouse. */
   SDL_EventState( SDL_MOUSEWHEEL,      SDL_ENABLE );

   input_keybinds = malloc( input_numbinds * sizeof(Keybind) );

   /* Create safe null keybinding for each. */
   for (i=0; i<input_numbinds; i++) {
      temp = &input_keybinds[i];
      memset( temp, 0, sizeof(Keybind) );
      temp->name        = keybind_info[i][0];
      temp->type        = KEYBIND_NULL;
      temp->key         = SDLK_UNKNOWN;
      temp->mod         = NMOD_NONE;

      if (strcmp(temp->name,"paste")==0)
         input_paste = temp;
   }
}


/**
 * @brief exits the input subsystem.
 */
void input_exit (void)
{
   free(input_keybinds);
}


/**
 * @brief Enables all the keybinds.
 */
void input_enableAll (void)
{
   int i;
   for (i=0; keybind_info[i][0] != NULL; i++)
      input_keybinds[i].disabled = 0;
}


/**
 * @brief Disables all the keybinds.
 */
void input_disableAll (void)
{
   int i;
   for (i=0; keybind_info[i][0] != NULL; i++)
      input_keybinds[i].disabled = 1;
}


/**
 * @brief Enables or disables a keybind.
 */
void input_toggleEnable( const char *key, int enable )
{
   int i;
   for (i=0; i<input_numbinds; i++) {
      if (strcmp(key, input_keybinds[i].name)==0) {
         input_keybinds[i].disabled = !enable;
         break;
      }
   }
}


/**
 * @brief Shows the mouse.
 */
void input_mouseShow (void)
{
   SDL_ShowCursor( SDL_ENABLE );
   input_mouseCounter++;
}


/**
 * @brief Hides the mouse.
 */
void input_mouseHide (void)
{
   input_mouseCounter--;
   if (input_mouseCounter <= 0) {
      input_mouseTimer = MOUSE_HIDE;
      input_mouseCounter = 0;
   }
}


/**
 * @brief Gets the key id from its name.
 *
 *    @param name Name of the key to get id from.
 *    @return ID of the key.
 */
SDL_Keycode input_keyConv( const char *name )
{
   SDL_Keycode k;
   k = SDL_GetKeyFromName( name );

   if (k == SDLK_UNKNOWN)
      WARN(_("Keyname '%s' doesn't match any key."), name);

   return k;
}


/**
 * @brief Binds key of type type to action keybind.
 *
 *    @param keybind The name of the keybind defined above.
 *    @param type The type of the keybind.
 *    @param key The key to bind to.
 *    @param mod Modifiers to check for.
 */
void input_setKeybind( const char *keybind, KeybindType type, SDL_Keycode key, SDL_Keymod mod )
{
   int i;
   for (i=0; i<input_numbinds; i++) {
      if (strcmp(keybind, input_keybinds[i].name)==0) {
         input_keybinds[i].type = type;
         input_keybinds[i].key = key;
         /* Non-keyboards get mod NMOD_ANY to always match. */
         input_keybinds[i].mod = (type==KEYBIND_KEYBOARD) ? mod : NMOD_ANY;
         return;
      }
   }
   WARN(_("Unable to set keybinding '%s', that command doesn't exist"), keybind);
}


/**
 * @brief Gets the value of a keybind.
 *
 *    @param[in] keybind Name of the keybinding to get.
 *    @param[out] type Stores the type of the keybinding.
 *    @param[out] mod Stores the modifiers used with the keybinding.
 *    @return The key associated with the keybinding.
 */
SDL_Keycode input_getKeybind( const char *keybind, KeybindType *type, SDL_Keymod *mod )
{
   int i;
   for (i=0; i<input_numbinds; i++) {
      if (strcmp(keybind, input_keybinds[i].name)==0) {
         if (type != NULL)
            (*type) = input_keybinds[i].type;
         if (mod != NULL)
            (*mod) = input_keybinds[i].mod;
         return input_keybinds[i].key;
      }
   }
   WARN(_("Unable to get keybinding '%s', that command doesn't exist"), keybind);
   return (SDL_Keycode)-1;
}


/**
 * @brief Gets the display name (translated and human-readable) of a keybind
 *
 *    @param[in] keybind Name of the keybinding to get display name of.
 *    @param[out] buf Buffer to write the display name to.
 *    @param[in] len Length of buffer.
 */
void input_getKeybindDisplay( const char *keybind, char *buf, int len )
{
   int p;
   SDL_Keycode key;
   KeybindType type;
   SDL_Keymod mod;

   /* Get the keybinding. */
   type =  KEYBIND_NULL;
   mod = NMOD_NONE;
   key = input_getKeybind( keybind, &type, &mod );

   /* Handle type. */
   switch (type) {
      case KEYBIND_NULL:
         strncpy( buf, _("Not bound"), len );
         break;

      case KEYBIND_KEYBOARD:
         p = 0;
         /* Handle mod. */
         if ((mod != NMOD_NONE) && (mod != NMOD_ANY))
            p += scnprintf(&buf[p], len-p, "%s\xc2\xa0+\xc2\xa0",
                  input_modToText(mod));
         /* Print key. Special-case ASCII letters (use uppercase, unlike SDL_GetKeyName.). */
         if (key < 0x100 && isalpha(key))
            p += scnprintf( &buf[p], len-p, "%c", toupper(key) );
         else
            p += scnprintf( &buf[p], len-p, "%s", _(SDL_GetKeyName(key)) );
         (void)p;
         break;

      case KEYBIND_JBUTTON:
         snprintf( buf, len, _("joy button %d"), key );
         break;

      case KEYBIND_JHAT_UP:
         snprintf( buf, len, _("joy hat %d up"), key );
         break;

      case KEYBIND_JHAT_DOWN:
         snprintf( buf, len, _("joy hat %d down"), key );
         break;

      case KEYBIND_JHAT_LEFT:
         snprintf( buf, len, _("joy hat %d left"), key );
         break;

      case KEYBIND_JHAT_RIGHT:
         snprintf( buf, len, _("joy hat %d right"), key );
         break;

      case KEYBIND_JAXISPOS:
         snprintf( buf, len, _("joy axis %d-"), key );
         break;

      case KEYBIND_JAXISNEG:
         snprintf( buf, len, _("joy axis %d+"), key );
         break;
   }
}


/**
 * @brief Gets the human readable version of mod.
 *
 *    @param mod Mod to get human readable version from.
 *    @return Human readable version of mod.
 */
const char* input_modToText( SDL_Keymod mod )
{
   switch ((int)mod) {
      case NMOD_NONE:   return _("None");
      case NMOD_CTRL:   return _("Ctrl");
      case NMOD_SHIFT:  return _("Shift");
      case NMOD_ALT:    return _("Alt");
      case NMOD_META:   return _("Meta");
      case NMOD_ANY:    return _("Any");
      default:          return _("unknown");
   }
}


/**
 * @brief Checks to see if a key is already bound.
 *
 *    @param type Type of key.
 *    @param key Key.
 *    @param mod Key modifiers.
 *    @return Name of the key that is already bound to it.
 */
const char *input_keyAlreadyBound( KeybindType type, SDL_Keycode key, SDL_Keymod mod )
{
   int i;
   Keybind *k;
   for (i=0; i<input_numbinds; i++) {
      k = &input_keybinds[i];

      /* Type must match. */
      if (k->type != type)
         continue;

      /* Must match key. */
      if (key !=  k->key)
         continue;

      /* Handle per case. */
      switch (type) {
         case KEYBIND_KEYBOARD:
            if ((k->mod == NMOD_ANY) || (mod == NMOD_ANY) ||
                  (k->mod == mod))
               return keybind_info[i][0];
            break;

         case KEYBIND_JAXISPOS:
         case KEYBIND_JAXISNEG:
         case KEYBIND_JBUTTON:
         case KEYBIND_JHAT_UP:
         case KEYBIND_JHAT_DOWN:
         case KEYBIND_JHAT_LEFT:
         case KEYBIND_JHAT_RIGHT:
            return keybind_info[i][0];

         default:
            break;
      }
   }

   /* Not found. */
   return NULL;
}


/**
 * @brief Gets the description of the keybinding.
 *
 *    @param keybind Keybinding to get the description of.
 *    @return Description of the keybinding.
 */
const char* input_getKeybindDescription( const char *keybind )
{
   int i;
   for (i=0; keybind_info[i][0] != NULL; i++)
      if (strcmp(keybind, input_keybinds[i].name)==0)
         return _(keybind_info[i][2]);
   WARN(_("Unable to get keybinding description '%s', that command doesn't exist"), keybind);
   return NULL;
}


/**
 * @brief Translates SDL modifier to Naev modifier.
 *
 *    @param mod SDL modifier to translate.
 *    @return Naev modifier.
 */
SDL_Keymod input_translateMod( SDL_Keymod mod )
{
   SDL_Keymod mod_filtered = 0;
   if (mod & (KMOD_LSHIFT | KMOD_RSHIFT))
      mod_filtered |= NMOD_SHIFT;
   if (mod & (KMOD_LCTRL | KMOD_RCTRL))
      mod_filtered |= NMOD_CTRL;
   if (mod & (KMOD_LALT | KMOD_RALT))
      mod_filtered |= NMOD_ALT;
   if (mod & (KMOD_LGUI | KMOD_RGUI))
      mod_filtered |= NMOD_META;
   return mod_filtered;
}


/**
 * @brief Handles key repeating.
 */
void input_update( double dt )
{
   Uint32 t;

   if (input_mouseTimer > 0.) {
      input_mouseTimer -= dt;

      /* Hide if necessary. */
      if ((input_mouseTimer < 0.) && (input_mouseCounter <= 0))
         SDL_ShowCursor( SDL_DISABLE );
   }

   /* Key repeat if applicable. */
   if (conf.repeat_delay != 0) {

      /* Key must be repeating. */
      if (repeat_key == -1)
         return;

      /* Get time. */
      t = SDL_GetTicks();

      /* Should be repeating. */
      if (repeat_keyTimer + conf.repeat_delay + repeat_keyCounter*conf.repeat_freq > t)
         return;

      /* Key repeat. */
      repeat_keyCounter++;
      input_key( repeat_key, KEY_PRESS, 0., 1 );
   }
}


#define KEY(s)    (strcmp(input_keybinds[keynum].name,s)==0) /**< Shortcut for ease. */
#define INGAME()  (!toolkit_isOpen()) /**< Makes sure player is in game. */
#define NOHYP()   \
((player.p != NULL) && !pilot_isFlag(player.p,PILOT_HYP_PREP) &&\
!pilot_isFlag(player.p,PILOT_HYP_BEGIN) &&\
!pilot_isFlag(player.p,PILOT_HYPERSPACE)) /**< Make sure the player isn't jumping. */
#define NODEAD()  ((player.p != NULL) && !pilot_isFlag(player.p,PILOT_DEAD)) /**< Player isn't dead. */
#define NOLAND()  ((player.p != NULL) && (!landed && !pilot_isFlag(player.p,PILOT_LANDING))) /**< Player isn't landed. */
/**
 * @brief Runs the input command.
 *
 *    @param keynum The index of the keybind.
 *    @param value The value of the keypress (defined above).
 *    @param kabs The absolute value.
 *    @param repeat Whether the key is still held down, rather than newly pressed.
 */
static void input_key( int keynum, double value, double kabs, int repeat )
{
   Uint32 t;
   HookParam hparam[3];
   Planet *pnt;
   int nav;
   int silent;
   int ret;

   /* Repetition stuff. */
   if (conf.repeat_delay != 0) {
      if ((value == KEY_PRESS) && !repeat) {
         repeat_key = keynum;
         repeat_keyTimer = SDL_GetTicks();
         repeat_keyCounter = 0;
      }
      else if (value == KEY_RELEASE) {
         repeat_key = -1;
         repeat_keyTimer = 0;
         repeat_keyCounter = 0;
      }
   }

   /*
    * movement
    */
   /* accelerating */
   if (KEY("accel") && !repeat) {
      if (kabs >= 0.) {
         player_restoreControl(PINPUT_MOVEMENT, NULL);
         player_accel(kabs);
         input_accelButton = 1;
      }
      else { /* prevent it from getting stuck */
         if (value == KEY_PRESS) {
            player_restoreControl(PINPUT_MOVEMENT, NULL);
            player_setFlag(PLAYER_ACCEL);
            player_accel(1.);
            input_accelButton = 1;
         }
         else if (value == KEY_RELEASE) {
            player_accelOver();
            player_rmFlag(PLAYER_ACCEL);
            input_accelButton = 0;
         }

         /* double tap accel = afterburn! */
         t = SDL_GetTicks();
         if (conf.doubletap_afterburn && (value == KEY_PRESS)
               && INGAME() && NOHYP() && NODEAD()
               && (t-input_accelLast <= AFTERBURNER_SENSITIVITY))
            pilot_afterburn( player.p );
         else if (value == KEY_RELEASE)
            pilot_afterburnOver( player.p );

         if (value == KEY_PRESS)
            input_accelLast = t;
      }
   }

   /* reversing */
   if (KEY("reverse") && !repeat) {
      if (value == KEY_PRESS) {
         player_restoreControl(PINPUT_MOVEMENT, NULL);
         player_setFlag(PLAYER_REVERSE);
      }
      else if ((value == KEY_RELEASE) && player_isFlag(PLAYER_REVERSE)) {
         player_rmFlag(PLAYER_REVERSE);

         if (!player_isFlag(PLAYER_ACCEL))
            player_accelOver();
      }
   }

   /* turning */
   if (KEY("left") && !repeat) {
      if (kabs >= 0.) {
         player_restoreControl(PINPUT_MOVEMENT, NULL);
         player_setFlag(PLAYER_TURN_LEFT);
         player_left = kabs;
      }
      else {
         /* set flags for facing correction */
         if (value == KEY_PRESS) {
            player_restoreControl(PINPUT_MOVEMENT, NULL);
            player_setFlag(PLAYER_TURN_LEFT);
            player_left = 1.;
         }
         else if (value == KEY_RELEASE) {
            player_rmFlag(PLAYER_TURN_LEFT);
            player_left = 0.;
         }
      }
   }
   else if (KEY("right") && !repeat) {
      if (kabs >= 0.) {
         player_restoreControl(PINPUT_MOVEMENT, NULL);
         player_setFlag(PLAYER_TURN_RIGHT);
         player_right = kabs;
      }
      else {
         /* set flags for facing correction */
         if (value == KEY_PRESS) {
            player_restoreControl(PINPUT_MOVEMENT, NULL);
            player_setFlag(PLAYER_TURN_RIGHT);
            player_right = 1.;
         }
         else if (value == KEY_RELEASE) {
            player_rmFlag(PLAYER_TURN_RIGHT);
            player_right = 0.;
         }
      }
   }
   else if (KEY("face") && !repeat) {
      if (value == KEY_PRESS) {
         player_restoreControl( PINPUT_MOVEMENT, NULL );
         player_setFlag(PLAYER_FACE);
      }
      else if ((value == KEY_RELEASE) && player_isFlag(PLAYER_FACE))
         player_rmFlag(PLAYER_FACE);
   }


   /*
    * Combat
    */
   /* shooting primary weapon */
   if (KEY("primary") && NODEAD() && !repeat) {
      if (value == KEY_PRESS) {
         player_setFlag(PLAYER_PRIMARY);
      }
      else if (value == KEY_RELEASE)
         player_rmFlag(PLAYER_PRIMARY);
   }

   /* shooting secondary weapon */
   if (KEY("secondary") && NOHYP() && NODEAD() && !repeat) {
      if (value == KEY_PRESS) {
         player_setFlag(PLAYER_SECONDARY);
      }
      else if (value == KEY_RELEASE)
         player_rmFlag(PLAYER_SECONDARY);
   }

   /* Weapon sets. */
   if (KEY("weapset1") && NODEAD())
      player_weapSetPress(0, value, repeat);
   if (KEY("weapset2") && NODEAD())
      player_weapSetPress(1, value, repeat);
   if (KEY("weapset3") && NODEAD())
      player_weapSetPress(2, value, repeat);
   if (KEY("weapset4") && NODEAD())
      player_weapSetPress(3, value, repeat);
   if (KEY("weapset5") && NODEAD())
      player_weapSetPress(4, value, repeat);
   if (KEY("weapset6") && NODEAD())
      player_weapSetPress(5, value, repeat);
   if (KEY("weapset7") && NODEAD())
      player_weapSetPress(6, value, repeat);
   if (KEY("weapset8") && NODEAD())
      player_weapSetPress(7, value, repeat);
   if (KEY("weapset9") && NODEAD())
      player_weapSetPress(8, value, repeat);
   if (KEY("weapset0") && NODEAD())
      player_weapSetPress(9, value, repeat);

   /* targeting */
   if (KEY("target_next") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetNext(0);
   else if (KEY("target_prev") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetPrev(0);
   else if (KEY("target_nearest") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetNearest();
   else if (KEY("target_nextHostile") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetNext(1);
   else if (KEY("target_prevHostile") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetPrev(1);
   else if (KEY("target_hostile") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetHostile();
   else if (KEY("target_clear") && INGAME() && NODEAD()
         && (value == KEY_PRESS))
      player_targetClear();

   /* follow target */
   if (KEY("follow") && INGAME() && NOHYP() && NODEAD()
         && (value == KEY_PRESS)) {
      if (player.p->target == PLAYER_ID)
         player_targetNearest();

      if (player.p->target != PLAYER_ID) {
         player_restoreControl(0, NULL);
         player_autonavPil(player.p->target);
      }
      else {
         player_message(_("#rNo targets available to follow."));
      }
   }

   /* board them ships */
   if (KEY("board") && INGAME() && NOHYP() && NODEAD() && !repeat
         && (value == KEY_PRESS)) {
      player_restoreControl(0, NULL);
      if (player_board() == PLAYER_BOARD_RETRY)
         player_autonavBoard(player.p->target);
   }

   /*
    * Escorts.
    */
   /* escort targeting */
   if (KEY("e_targetNext") && INGAME() && NODEAD() && !repeat
         && (value == KEY_PRESS))
      player_targetEscort(0);
   else if (KEY("e_targetPrev") && INGAME() && NODEAD() && !repeat
         && (value == KEY_PRESS))
      player_targetEscort(1);

   /* escort orders */
   if (INGAME() && NODEAD() && KEY("e_attack") && !repeat
         && (value == KEY_PRESS))
      escorts_attack(player.p);
   else if (INGAME() && NODEAD() && KEY("e_hold") && !repeat
         && (value == KEY_PRESS))
      escorts_hold(player.p);
   else if (INGAME() && NODEAD() && KEY("e_return") && !repeat
         && (value == KEY_PRESS))
      escorts_return(player.p);
   else if (INGAME() && NODEAD() && KEY("e_clear") && !repeat
         && (value == KEY_PRESS))
      escorts_clear(player.p);


   /*
    * Space
    */
   /* local jump */
   if (KEY("local_jump") && INGAME() && NOHYP() && NODEAD()
         && (value == KEY_PRESS)) {
      if (pilot_canLocalJump(player.p, 1)) {
         player_restoreControl(PINPUT_MOVEMENT, NULL);
         player_localJump();
      }
   }

   /* continue autonav */
   if (KEY("autonav") && INGAME() && NOHYP() && NODEAD()
         && (value == KEY_PRESS))
      player_autonavStart();

   /* target planet (cycles like target) */
   if (KEY("target_planet") && INGAME() && NOHYP() && NOLAND() && NODEAD()
         && (value == KEY_PRESS))
      player_targetPlanet(0);

   /* land */
   if (KEY("land") && INGAME() && NOHYP() && NOLAND() && NODEAD()
         && (value == KEY_PRESS)) {
      /* We have a somewhat delecate balance here to ensure that the
       * targeting sound is only played once, and only if needed. This
       * variable, silent, keeps track of whether or not any further
       * sounds should be prevented. This is largely because of the
       * rather complicated conditions for being able to land which the
       * auto-land code has to navigate. */
      silent = 0;

      /* If already attempting to auto-land, target next landable
       * planet. */
      if (player_isFlag(PLAYER_AUTONAV)
            && ((player.autonav == AUTONAV_PNT_APPROACH)
               || (player.autonav == AUTONAV_PNT_BRAKE))
            && !player_isFlag(PLAYER_BASICAPPROACH)) {
         /* Attempt to cycle thru targets until either we come back to
          * the original targeted planet or we find another planet that
          * can possibly be landed on. */
         nav = player.p->nav_planet;
         do {
            player_targetPlanet(1);
            ret = player_checkLand(0, 1);
         } while ((player.p->nav_planet != nav) && (player.p->nav_planet != -1)
               && (ret == PLAYER_LAND_IMPOSSIBLE));

         if ((player.p->nav_planet != nav) && (player.p->nav_planet != -1)) {
            player_soundPlayGUI(snd_nav, 1);
            silent = 1;
         }
      }

      /* Try player_land() in case no planet is selected. */
      ret = player_land(0, silent);
      if ((ret == PLAYER_LAND_IMPOSSIBLE) || (player.p->nav_planet == -1)) {
         /* Cannot land no matter what; report the result. */
         player_land(1, silent);
      }
      else if (ret != PLAYER_LAND_OK) {
         pnt = cur_system->planets[player.p->nav_planet];

         if (ret == PLAYER_LAND_AGAIN) {
            /* Second player_land() attempt now using the planet
             * selected by the previous player_land() call. */
            ret = player_land(0, silent);
         }

         if (((ret == PLAYER_LAND_AGAIN) || (ret == PLAYER_LAND_DENIED))
               && planet_hasService(pnt, PLANET_SERVICE_LAND)) {
            player_rmFlag(PLAYER_BASICAPPROACH);
            player_autonavPnt(pnt->name);
            player_message(
                  _("#oAutonav: auto-landing sequence engaged."));
         }
      }
   }

   /* target jump */
   if (KEY("thyperspace") && NOHYP() && NOLAND() && NODEAD() && !repeat
         && (value == KEY_PRESS))
      player_targetHyperspace();

   /* open starmap */
   if (KEY("starmap") && NOHYP() && NODEAD() && !repeat
         && (value == KEY_PRESS))
      map_open();

   /* jump */
   if (KEY("jump") && INGAME() && !repeat
         && (value == KEY_PRESS)) {
      /* If already attempting to auto-hyperspace, target next jump. */
      if (player_isFlag(PLAYER_AUTONAV)
            && ((player.autonav == AUTONAV_JUMP_APPROACH)
               || (player.autonav == AUTONAV_JUMP_BRAKE))) {
         player_targetHyperspace();
      }

      /* Try player_jump() in case no jump is selected. */
      if (!player_jump(0)) {
         if (player.p->nav_hyperspace != -1) {
            player_hyperspacePreempt(1);
            player_autonavStart();
         }
         else {
            player_restoreControl(0, NULL);
            player_jump(1);
         }
      }
   }

   /* open/close overlay */
   if (KEY("overlay") && NODEAD() && INGAME() && !repeat)
      ovr_key(value);

   /* toggle mouse flying */
   if (KEY("mousefly") && NODEAD() && !repeat && (value == KEY_PRESS))
      player_toggleMouseFly();

   /* autobrake */
   if (KEY("autobrake") && NOHYP() && NOLAND() && NODEAD() && !repeat
         && (value == KEY_PRESS)) {
      player_restoreControl(PINPUT_BRAKING, NULL);
      player_brake();
   }


   /*
    * Communication.
    */
   /* scroll messages */
   if (KEY("log_up") && INGAME() && NODEAD() && (value == KEY_PRESS))
      gui_messageScrollUp(5);
   else if (KEY("log_down") && INGAME() && NODEAD() && (value == KEY_PRESS))
      gui_messageScrollDown(5);

   /* hailing */
   if (KEY("autohail") && INGAME() && NOHYP() && NODEAD() && !repeat
         && (value == KEY_PRESS))
      player_autohail();
   else if (KEY("hail") && INGAME() && NOHYP() && NODEAD() && !repeat
         && (value == KEY_PRESS))
      player_hail();

   /*
    * misc
    */
   /* radar zoom */
   if (KEY("mapzoomin") && INGAME() && NODEAD() && (value == KEY_PRESS))
      gui_setRadarRel(-1);
   else if (KEY("mapzoomout") && INGAME() && NODEAD() && (value == KEY_PRESS))
      gui_setRadarRel(1);

   /* take a screenshot */
   if (KEY("screenshot") && (value == KEY_PRESS))
      player_screenshot();

   /* toggle fullscreen */
   if (KEY("togglefullscreen") && !repeat && (value == KEY_PRESS))
      naev_toggleFullscreen();

   /* pause the games */
   if (KEY("pause") && !repeat && (value == KEY_PRESS)) {
      if (!toolkit_isOpen()) {
         if (paused)
            unpause_game();
         else
            pause_player();
      }
   }

   /* toggle speed mode */
   if (KEY("speed") && !repeat && (value == KEY_PRESS)
         && !player_isFlag(PLAYER_CINEMATICS_2X)) {
      if (player.speed < 4.)
         player.speed *= 2.;
      else
         player.speed = 1.;
      player_autonavResetSpeed();
   }

   /* opens a small menu */
   if (KEY("menu") && NODEAD() && !repeat && (value == KEY_PRESS))
      menu_small();

   /* open ship computer */
   if (KEY("info") && NOHYP() && NODEAD() && !repeat && (value == KEY_PRESS))
      menu_info(INFO_MAIN);

   /* Opens the Lua console. */
   if (KEY("console") && NODEAD() && !repeat && (value == KEY_PRESS))
      cli_open();

   /* Run the hook. */
   hparam[0].type = HOOK_PARAM_STRING;
   hparam[0].u.str = input_keybinds[keynum].name;
   hparam[1].type = HOOK_PARAM_BOOL;
   hparam[1].u.b = (value > 0.);
   hparam[2].type = HOOK_PARAM_SENTINEL;
   hooks_runParam("input", hparam);
}
#undef KEY


/*
 * events
 */
/* prototypes */
static void input_joyaxis( const SDL_Keycode axis, const int value );
static void input_joyevent( const int event, const SDL_Keycode button );
static void input_keyevent( const int event, const SDL_Keycode key, const SDL_Keymod mod, const int repeat );

/*
 * joystick
 */
/**
 * @brief Filters a joystick axis event.
 *    @param axis Axis generated by the event.
 *    @param value Value of the axis.
 */
static void input_joyaxis( const SDL_Keycode axis, const int value )
{
   int i, k;
   for (i=0; i<input_numbinds; i++) {
      if (input_keybinds[i].key == axis) {
         /* Positive axis keybinding. */
         if ((input_keybinds[i].type == KEYBIND_JAXISPOS)
               && (value >= 0)) {
            k = (value > 0) ? KEY_PRESS : KEY_RELEASE;
            if ((k == KEY_PRESS) && input_keybinds[i].disabled)
               continue;
            input_key( i, k, FABS(((double)value)/32767.), 0 );
         }

         /* Negative axis keybinding. */
         if ((input_keybinds[i].type == KEYBIND_JAXISNEG)
               && (value <= 0)) {
            k = (value < 0) ? KEY_PRESS : KEY_RELEASE;
            if ((k == KEY_PRESS) && input_keybinds[i].disabled)
               continue;
            input_key( i, k, FABS(((double)value)/32767.), 0 );
         }
      }
   }
}
/**
 * @brief Filters a joystick button event.
 *    @param event Event type (down/up).
 *    @param button Button generating the event.
 */
static void input_joyevent( const int event, const SDL_Keycode button )
{
   int i;
   for (i=0; i<input_numbinds; i++) {
      if ((event == KEY_PRESS) && input_keybinds[i].disabled)
         continue;
      if ((input_keybinds[i].type == KEYBIND_JBUTTON) &&
            (input_keybinds[i].key == button))
         input_key(i, event, -1., 0);
   }
}

/**
 * @brief Filters a joystick hat event.
 *    @param value Direction on hat.
 *    @param hat Hat generating the event.
 */
static void input_joyhatevent( const Uint8 value, const Uint8 hat )
{
   int i, event;
   for (i=0; i<input_numbinds; i++) {
      if (input_keybinds[i].key != hat)
         continue;

      if (input_keybinds[i].type == KEYBIND_JHAT_UP) {
         event = (value & SDL_HAT_UP) ? KEY_PRESS : KEY_RELEASE;
         if (!((event == KEY_PRESS) && input_keybinds[i].disabled))
            input_key(i, event, -1., 0);
      } else if (input_keybinds[i].type == KEYBIND_JHAT_DOWN) {
         event = (value & SDL_HAT_DOWN) ? KEY_PRESS : KEY_RELEASE;
         if (!((event == KEY_PRESS) && input_keybinds[i].disabled))
            input_key(i, event, -1., 0);
      } else if (input_keybinds[i].type == KEYBIND_JHAT_LEFT) {
         event = (value & SDL_HAT_LEFT) ? KEY_PRESS : KEY_RELEASE;
         if (!((event == KEY_PRESS) && input_keybinds[i].disabled))
            input_key(i, event, -1., 0);
      } else if (input_keybinds[i].type == KEYBIND_JHAT_RIGHT) {
         event = (value & SDL_HAT_RIGHT) ? KEY_PRESS : KEY_RELEASE;
         if (!((event == KEY_PRESS) && input_keybinds[i].disabled))
            input_key(i, event, -1., 0);
      }
   }
}


/*
 * keyboard
 */
/**
 * @brief Filters a keyboard event.
 *    @param event Event type (down/up).
 *    @param key Key generating the event.
 *    @param mod Modifiers active when event was generated.
 *    @param repeat Whether the key is still held down, rather than newly pressed.
 */
static void input_keyevent( const int event, SDL_Keycode key, const SDL_Keymod mod, const int repeat )
{
   int i;
   SDL_Keymod mod_filtered;

   /* Filter to "Naev" modifiers. */
   mod_filtered = input_translateMod(mod);

   for (i=0; i<input_numbinds; i++) {
      if ((event == KEY_PRESS) && input_keybinds[i].disabled)
         continue;
      if ((input_keybinds[i].type == KEYBIND_KEYBOARD) &&
            (input_keybinds[i].key == key)) {
         if ((input_keybinds[i].mod == mod_filtered) ||
               (input_keybinds[i].mod == NMOD_ANY) ||
               (event == KEY_RELEASE)) /**< Release always gets through. */
            input_key(i, event, -1., repeat);
            /* No break so all keys get pressed if needed. */
      }
   }
}


/**
 * @brief Handles zoom.
 */
static void input_clickZoom( double modifier )
{
   if (player.p != NULL)
      cam_setZoomTarget( cam_getZoomTarget() * modifier );
}

/**
 * @brief Provides mouse X and Y coordinates for mouse flying.
 */
static void input_mouseMove( SDL_Event* event )
{
   int mx, my;

   gl_windowToScreenPos( &mx, &my, event->button.x, event->button.y );
   player.mousex = mx;
   player.mousey = my;
}

/**
 * @brief Handles a click event.
 */
static void input_clickevent( SDL_Event* event )
{
   Uint32 t;
   pilotId_t pid;
   int mx, my, pntid, jpid, astid, fieid;
   int res;
   int autonav;
   double x, y, zoom, px, py;
   double ang, angp, mouseang;
   HookParam hparam[2];

   /* Generate hook. */
   hparam[0].type    = HOOK_PARAM_NUMBER;
   hparam[0].u.num   = event->button.button;
   hparam[1].type    = HOOK_PARAM_SENTINEL;
   hooks_runParam( "mouse", hparam );

   /* Player must not be NULL. */
   if ((player.p == NULL) || player_isFlag(PLAYER_DESTROYED))
      return;

   /* Player must not be dead. */
   if (pilot_isFlag(player.p, PILOT_DEAD))
      return;

   /* Handle mouse thrust. */
   if (player_isFlag(PLAYER_MFLY)) {
      if ((event->button.button == SDL_BUTTON_MIDDLE)
            || (event->button.button == SDL_BUTTON_X1)
            || (event->button.button == SDL_BUTTON_X2)) {
         if (event->type == SDL_MOUSEBUTTONDOWN) {
            player_restoreControl( PINPUT_MOVEMENT, NULL );
            player_setFlag(PLAYER_ACCEL);
            player_accel(1.);
            input_accelButton = 1;
         }

         else if (event->type == SDL_MOUSEBUTTONUP) {
            player_accelOver();
            player_rmFlag(PLAYER_ACCEL);
            input_accelButton = 0;
         }

         /* double tap accel = afterburn! */
         t = SDL_GetTicks();
         if (conf.doubletap_afterburn && (event->type == SDL_MOUSEBUTTONDOWN)
               && INGAME() && NOHYP() && NODEAD()
               && (t-input_accelLast <= AFTERBURNER_SENSITIVITY))
            pilot_afterburn( player.p );
         else if (event->type == SDL_MOUSEBUTTONUP)
            pilot_afterburnOver( player.p );

         if (event->type == SDL_MOUSEBUTTONDOWN)
            input_accelLast = t;
         return;
      }
   }

   /* Mouse targeting only uses left and right buttons. */
   if (event->button.button != SDL_BUTTON_LEFT &&
            event->button.button != SDL_BUTTON_RIGHT)
      return;

   /* Mouse targeting only uses mouse button down. */
   if (event->type != SDL_MOUSEBUTTONDOWN)
      return;

   autonav = (event->button.button == SDL_BUTTON_RIGHT) ? 1 : 0;

   px = player.p->solid->pos.x;
   py = player.p->solid->pos.y;
   gl_windowToScreenPos( &mx, &my, event->button.x, event->button.y );
   if ((mx <= 15 || my <= 15 ) || (my >= gl_screen.h - 15 || mx >= gl_screen.w - 15)) {
      /* Border targeting is handled as a special case, as it uses angles,
       * not coordinates. */
      x = (mx - (gl_screen.w / 2.)) + px;
      y = (my - (gl_screen.h / 2.)) + py;
      mouseang = atan2(py - y, px -  x);
      angp = pilot_getNearestAng( player.p, &pid, mouseang, 1 );
      ang  = system_getClosestAng( cur_system, &pntid, &jpid, &astid, &fieid, x, y, mouseang );

      if  ((ABS(angle_diff(mouseang, angp)) > M_PI / 64) ||
            ABS(angle_diff(mouseang, ang)) < ABS(angle_diff(mouseang, angp)))
         pid = PLAYER_ID; /* Pilot angle is too great, or planet/jump is closer. */
      if  (ABS(angle_diff(mouseang, ang)) > M_PI / 64 )
         jpid = pntid = astid = fieid = -1; /* Asset angle difference is too great. */

      if (pid != PLAYER_ID) {
         if (input_clickedPilot(pid, autonav))
            return;
      }
      else if (pntid >= 0) { /* Planet is closest. */
         if (input_clickedPlanet(pntid, autonav))
            return;
      }
      else if (jpid >= 0) { /* Jump point is closest. */
         if (input_clickedJump(jpid, autonav))
            return;
      }
      else if (astid >= 0) { /* Asteroid is closest. */
         if (input_clickedAsteroid(fieid, astid))
            return;
      }

      /* Fall-through and handle as a normal click. */
   }

   if (gui_radarClickEvent( event ))
      return;

   /* Visual (on-screen) */
   gl_screenToGameCoords( &x, &y, (double)mx, (double)my );
   zoom = res = 1. / cam_getZoom();
   if (input_clickPos(event, x, y, zoom, 10. * res, 15. * res))
      return;

   /* Click was unused, so use it to clear player's target. */
   player_targetClear();
}


/**
 * @brief Handles a click at a position in the current system
 *
 *    @brief event The click event itself, used for button information.
 *    @brief x X coordinate within the system.
 *    @brief y Y coordinate within the system.
 *    @brief zoom Camera zoom (mostly for on-screen targeting).
 *    @brief minpr Minimum radius to assign to pilots.
 *    @brief minr Minimum radius to assign to planets and jumps.
 *    @return Whether the click was used to trigger an action.
 */
int input_clickPos( SDL_Event *event, double x, double y, double zoom, double minpr, double minr )
{
   pilotId_t pid;
   Pilot *p;
   double r, rp;
   double d, dp;
   Planet *pnt;
   JumpPoint *jp;
   Asteroid *ast;
   AsteroidAnchor *field;
   AsteroidType *at;
   int pntid, jpid, astid, fieid;

   dp = pilot_getNearestPos(player.p, &pid, x, y, 1);
   p = pilot_get(pid);

   d = system_getClosest(cur_system, &pntid, &jpid, &astid, &fieid, x, y);
   rp = MAX(1.5 * PILOT_SIZE_APPROX * (p->ship->gfx_space->sw/2.) * zoom,
         minpr);

   if (pntid >=0) { /* Planet is closer. */
      pnt = cur_system->planets[ pntid ];
      r  = MAX( 1.5 * pnt->radius * zoom, minr );
   }
   else if (jpid >= 0) {
      jp = &cur_system->jumps[ jpid ];
      r  = MAX( 1.5 * jp->radius * zoom, minr );
   }
   else if (astid >= 0) {
      field = &cur_system->asteroids[fieid];
      ast   = &field->asteroids[astid];

      /* Recover the right gfx */
      at = space_getType( ast->type );
      if (ast->gfxID >= array_size(at->gfxs))
         WARN(_("Gfx index out of range"));
      r  = MAX( MAX( at->gfxs[ast->gfxID]->w * zoom, minr ),
                at->gfxs[ast->gfxID]->h * zoom );
   }
   else
      r  = 0.;

   /* Reject pilot if it's too far or a valid asset is closer. */
   if ((dp > pow2(rp)) || ((d < pow2(r)) && (dp >  d)))
      pid = PLAYER_ID;

   if (d > pow2(r)) /* Planet or jump point is too far. */
      jpid = pntid = astid = fieid =  -1;

   /* Target a pilot, planet or jump, and/or perform an appropriate action. */
   if (event->button.button == SDL_BUTTON_LEFT) {
      if (pid != PLAYER_ID) {
         return input_clickedPilot(pid, 0);
      }
      else if (pntid >= 0) { /* Planet is closest. */
         return input_clickedPlanet(pntid, 0);
      }
      else if (jpid >= 0) { /* Jump point is closest. */
         return input_clickedJump(jpid, 0);
      }
      else if (astid >= 0) { /* Asteroid is closest. */
         return input_clickedAsteroid(fieid, astid);
      }
   }
   /* Right click only controls autonav. */
   else if (event->button.button == SDL_BUTTON_RIGHT) {
      if ((pid != PLAYER_ID) && input_clickedPilot(pid, 1))
         return 1;
      else if ((pntid >= 0) && input_clickedPlanet(pntid, 1))
         return 1;
      else if ((jpid >= 0) && input_clickedJump(jpid, 1))
         return 1;

      /* Go to position, if the position is >= 1500 px away. */
      if ((pow2(x - player.p->solid->pos.x) + pow2(y - player.p->solid->pos.y))
            >= pow2(1500))

      player_autonavPos( x, y );
      return 1;
   }

   return 0;
}


/**
 * @brief Performs an appropriate action when a jump point is clicked.
 *
 *    @param jump Index of the jump point.
 *    @param autonav Whether to autonav to the target.
 *    @return Whether the click was used.
 */
int input_clickedJump( int jump, int autonav )
{
   JumpPoint *jp;
   jp = &cur_system->jumps[ jump ];

   if (!jp_isUsable(jp))
      return 0;

   /* Update map path. */
   if (player.p->nav_hyperspace != jump)
      map_select( jp->target, 0 );

   if ((jump == player.p->nav_hyperspace)
            && input_isDoubleClick((void*)jp)) {
      player_targetHyperspaceSet(jump);
      player_autonavStart();
      return 1;
   }
   else {
      player_targetHyperspaceSet(jump);
      if (autonav)
         return 0;
   }

   input_clicked((void*)jp);
   return 1;
}

/**
 * @brief Performs an appropriate action when a planet is clicked.
 *
 *    @param planet Index of the planet.
 *    @param autonav Whether to autonav to the target.
 *    @return Whether the click was used.
 */
int input_clickedPlanet( int planet, int autonav )
{
   Planet *pnt;
   int ret;
   pnt = cur_system->planets[ planet ];

   if (!planet_isKnown(pnt))
      return 0;

   if (autonav) {
      /* Ensure the player is informed when auto-landing is aborted. */
      if (player_isFlag(PLAYER_AUTONAV) && !player_isFlag(PLAYER_BASICAPPROACH)
            && ((player.autonav == AUTONAV_PNT_APPROACH)
               || (player.autonav == AUTONAV_PNT_BRAKE)))
         player_message(_("#oAutonav: auto-landing sequence aborted."));

      player_setFlag(PLAYER_BASICAPPROACH);
      player_targetPlanetSet(planet, 0);
      player_autonavPnt(pnt->name);
      return 1;
   }

   if (planet == player.p->nav_planet && input_isDoubleClick((void*)pnt)) {
      player_hyperspacePreempt(0);
      ret = player_land(0, 0);
      if (ret == PLAYER_LAND_IMPOSSIBLE) {
         player_setFlag(PLAYER_BASICAPPROACH);
         player_autonavPnt(pnt->name);
         return 1;
      }
      else if (ret != PLAYER_LAND_OK) {
         if (planet_hasService(pnt, PLANET_SERVICE_LAND)) {
            player_rmFlag(PLAYER_BASICAPPROACH);
            player_autonavPnt(pnt->name);
            player_message(_("#oAutonav: auto-landing sequence engaged."));
         }
         else {
            player_setFlag(PLAYER_BASICAPPROACH);
            player_autonavPnt(pnt->name);
         }
      }
   }
   else
      player_targetPlanetSet(planet, 0);

   input_clicked( (void*)pnt );
   return 1;
}

/**
 * @brief Performs an appropriate action when an asteroid is clicked.
 *
 *    @param field Index of the parent field of the asteoid.
 *    @param asteroid Index of the oasteoid in the field.
 *    @return Whether the click was used.
 */
int input_clickedAsteroid( int field, int asteroid )
{
   Asteroid *ast;
   AsteroidAnchor *anchor;

   anchor = &cur_system->asteroids[ field ];
   ast = &anchor->asteroids[ asteroid ];

   player_targetAsteroidSet( field, asteroid );

   input_clicked( (void*)ast );
   return 1;
}

/**
 * @brief Performs an appropriate action when a pilot is clicked.
 *
 *    @param pilot Index of the pilot.
 *    @param autonav Whether this is an autonav action.
 *    @return Whether the click was used.
 */
int input_clickedPilot(pilotId_t pilot, int autonav)
{
   Pilot *p;

   if (pilot == PLAYER_ID)
      return 0;

   if (autonav && !conf.rightclick_follow)
      return 0;

   if (autonav) {
      player_targetSet( pilot );
      player_autonavPil( pilot );
      return 1;
   }

   p = pilot_get(pilot);
   if (pilot == player.p->target && input_isDoubleClick( (void*)p )) {
      if (pilot_isDisabled(p) || pilot_isFlag(p, PILOT_BOARDABLE)) {
         if (player_board() == PLAYER_BOARD_RETRY)
            player_autonavBoard(pilot);
      }
      else
         player_hail();
   }
   else
      player_targetSet( pilot );

   input_clicked( (void*)p );
   return 1;
}


/**
 * @brief Sets the last-clicked item, for double-click detection.
 *    @param clicked Pointer to the clicked item.
 */
void input_clicked( void *clicked )
{
   if (conf.mouse_doubleclick <= 0.)
      return;

   input_lastClicked = clicked;
   input_mouseClickLast = SDL_GetTicks();
}


/**
 * @brief Checks whether a clicked item is the same as the last-clicked.
 *    @param clicked Pointer to the clicked item.
 */
int input_isDoubleClick( void *clicked )
{
   Uint32 threshold;

   if (conf.mouse_doubleclick <= 0.)
      return 1;

   /* Most recent time that constitutes a valid double-click. */
   threshold = input_mouseClickLast + (int)(conf.mouse_doubleclick * 1000);

   if ((SDL_GetTicks() <= threshold) && (clicked == input_lastClicked))
      return 1;

   return 0;
}


/**
 * @brief Handles global input.
 *
 * Basically separates the event types
 *
 *    @param event Incoming SDL_Event.
 */
void input_handle( SDL_Event* event )
{
   int ismouse;
   SDL_Event evt;
   char *txt;
   size_t i;
   uint32_t ch;
   size_t e;

   /* Special case mouse stuff. */
   if ((event->type == SDL_MOUSEMOTION)  ||
         (event->type == SDL_MOUSEBUTTONDOWN) ||
         (event->type == SDL_MOUSEBUTTONUP)) {
      input_mouseTimer = MOUSE_HIDE;
      SDL_ShowCursor( SDL_ENABLE );
      ismouse = 1;
   }
   else
      ismouse = 0;

   /* Special case paste. */
   if ((event->type == SDL_KEYDOWN) && SDL_HasClipboardText() &&
         (SDL_EventState(SDL_TEXTINPUT, SDL_QUERY) == SDL_ENABLE)) {
      SDL_Keymod mod = input_translateMod( event->key.keysym.mod );
      if ((input_paste->key == event->key.keysym.sym) &&
            (input_paste->mod & mod)) {
         txt = SDL_GetClipboardText();
         evt.type = SDL_TEXTINPUT;
         i = 0;
         while ((ch = u8_nextchar(txt, &i))) {
            e = u8_wc_toutf8(evt.text.text, ch);
            evt.text.text[e] = '\0';
            SDL_PushEvent(&evt);
         }
         SDL_free(txt);
         return;
      }
   }

   if (toolkit_isOpen()) { /* toolkit handled completely separately */
      /* We set the viewport to fullscreen, ignoring the GUI setting. */
      gl_viewport(0, 0, gl_screen.nw, gl_screen.nh);

      if (toolkit_input(event))
         return; /* we don't process it if toolkit grabs it */
      if (ismouse)
         return; /* Toolkit absorbs everything mousy. */

      /* Restore viewport so it doesn't mess anything else up. */
      gl_defViewport();
   }

   if (ovr_isOpen())
      if (ovr_input(event))
         return; /* Don't process if the map overlay wants it. */

   /* GUI gets event. */
   if (gui_handleEvent(event))
      return;

   switch (event->type) {

      /*
       * game itself
       */
      case SDL_JOYAXISMOTION:
         input_joyaxis(event->jaxis.axis, event->jaxis.value);
         break;

      case SDL_JOYBUTTONDOWN:
         input_joyevent(KEY_PRESS, event->jbutton.button);
         break;

      case SDL_JOYBUTTONUP:
         input_joyevent(KEY_RELEASE, event->jbutton.button);
         break;

      case SDL_JOYHATMOTION:
         input_joyhatevent(event->jhat.value, event->jhat.hat);
         break;

      case SDL_KEYDOWN:
         if (event->key.repeat != 0)
            return;
         input_keyevent(KEY_PRESS, event->key.keysym.sym, event->key.keysym.mod, 0);
         break;

      case SDL_KEYUP:
         if (event->key.repeat !=0)
            return;
         input_keyevent(KEY_RELEASE, event->key.keysym.sym, event->key.keysym.mod, 0);
         break;


      /* Mouse stuff. */
      case SDL_MOUSEBUTTONDOWN:
      case SDL_MOUSEBUTTONUP:
         input_clickevent( event );
         break;

      case SDL_MOUSEWHEEL:
         if (event->wheel.y > 0)
            input_clickZoom( 1.1 );
         else if (event->wheel.y < 0)
            input_clickZoom( 0.9 );
         break;

      case SDL_MOUSEMOTION:
         input_mouseMove( event );
         break;

      default:
         break;
   }
}


/**
 * @brief Clears all input to ensure no phantom control of player's ship.
 */
void input_clearAll(void)
{
   /* Turn off acceleration. */
   player_accelOver();
   player_rmFlag(PLAYER_ACCEL);
   input_accelButton = 0;

   /* Turn off afterburner. */
   pilot_afterburnOver(player.p);

   /* Turn off turning. */
   player_rmFlag(PLAYER_TURN_LEFT);
   player_left = 0.;
   player_rmFlag(PLAYER_TURN_RIGHT);
   player_right = 0.;
   player_rmFlag(PLAYER_FACE);

   /* Turn off weapons firing. */
   player_rmFlag(PLAYER_PRIMARY);
   player_rmFlag(PLAYER_SECONDARY);
}

