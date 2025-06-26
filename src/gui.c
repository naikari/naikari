/*

 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file gui.c
 *
 * @brief Contains the GUI stuff for the player.
 */


/** @cond */
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "gui.h"

#include "ai.h"
#include "camera.h"
#include "comm.h"
#include "conf.h"
#include "dialogue.h"
#include "economy.h"
#include "font.h"
#include "gui_omsg.h"
#include "gui_osd.h"
#include "hook.h"
#include "input.h"
#include "intro.h"
#include "land.h"
#include "log.h"
#include "map.h"
#include "menu.h"
#include "mission.h"
#include "music.h"
#include "ndata.h"
#include "nebula.h"
#include "nfile.h"
#include "nlua.h"
#include "nlua_gfx.h"
#include "nlua_gui.h"
#include "nlua_misn.h"
#include "nlua_tex.h"
#include "nlua_tk.h"
#include "nluadef.h"
#include "nmath.h"
#include "nstring.h"
#include "ntime.h"
#include "nxml.h"
#include "opengl.h"
#include "pause.h"
#include "perlin.h"
#include "pilot.h"
#include "pilot.h"
#include "player.h"
#include "render.h"
#include "rng.h"
#include "sound.h"
#include "space.h"
#include "spfx.h"
#include "toolkit.h"
#include "unidiff.h"


#define XML_GUI_ID   "GUIs" /**< XML section identifier for GUI document. */
#define XML_GUI_TAG  "gui" /**<  XML Section identifier for GUI tags. */

#define RADAR_BLINK_PILOT        0.5 /**< Blink rate of the pilot target on radar. */
#define RADAR_BLINK_PLANET       1. /**< Blink rate of the planet target on radar. */


/* some blinking stuff. */
static double blink_pilot     = 0.; /**< Timer on target blinking on radar. */
static double blink_planet    = 0.; /**< Timer on planet blinking on radar. */
static double animation_dt    = 0.; /**< Used for animations. */

/* for VBO. */
static gl_vbo *gui_radar_select_vbo = NULL;

static int gui_getMessage     = 1; /**< Whether or not the player should receive messages. */
static char *gui_name         = NULL; /**< Name of the GUI (for errors and such). */


extern unsigned int land_wid; /**< From land.c */


/**
 * GUI Lua stuff.
 */
static nlua_env gui_env = LUA_NOREF; /**< Current GUI Lua environment. */
static int gui_L_mclick = 0; /**< Use mouse click callback. */
static int gui_L_mmove = 0; /**< Use mouse movement callback. */


/**
 * Cropping.
 */
static double gui_viewport_x = 0.; /**< GUI Viewport X offset. */
static double gui_viewport_y = 0.; /**< GUI Viewport Y offset. */
static double gui_viewport_w = 0.; /**< GUI Viewport width. */
static double gui_viewport_h = 0.; /**< GUI Viewport height. */

/**
 * Map overlay
 */
/**
 * @struct MapOverlay
 *
 * @brief Represents map overlay config values
 */
typedef struct MapOverlay_ {
   /* GUI parameters */
   int boundTop;
   int boundRight;
   int boundBottom;
   int boundLeft;
} MapOverlay;
static MapOverlay map_overlay = {
  .boundTop = 0,
  .boundRight = 0,
  .boundBottom = 0,
  .boundLeft = 0,
};
int map_overlay_height(void)
{
   return SCREEN_H - map_overlay.boundTop - map_overlay.boundBottom;
}
int map_overlay_width(void)
{
   return SCREEN_W - map_overlay.boundLeft - map_overlay.boundRight;
}
int map_overlay_center_x(void)
{
   return map_overlay_width() / 2 + map_overlay.boundLeft;
}
int map_overlay_center_y(void)
{
   return map_overlay_height() / 2 + map_overlay.boundBottom;
}
double map_overlay_scale_x(void)
{
  return (double)map_overlay_width() / (double)SCREEN_W;
}
double map_overlay_scale_y(void)
{
  return (double)map_overlay_height() / (double)SCREEN_H;
}

/**
 * @struct Radar
 *
 * @brief Represents the player's radar.
 */
typedef struct Radar_ {
   double w; /**< Width. */
   double h; /**< Height. */
   double x; /**< X position. */
   double y; /**< Y position. */
   RadarShape shape; /**< Shape */
   double res; /**< Resolution */
   int closed; /**< Whether the radar is closed. */
} Radar;
/* radar resolutions */
#define RADAR_RES_MAX      300. /**< Maximum radar resolution. */
#define RADAR_RES_REF      100. /**< Reference radar resolution. */
#define RADAR_RES_MIN      10. /**< Minimum radar resolution. */
#define RADAR_RES_INTERVAL 10. /**< Steps used to increase/decrease resolution. */
static Radar gui_radar;

/* needed to render properly */
static double gui_xoff = 0.; /**< X Offset that GUI introduces. */
static double gui_yoff = 0.; /**< Y offset that GUI introduces. */

/* messages */
static const int mesg_max        = 128; /**< Maximum messages onscreen */
static int mesg_pointer    = 0; /**< Current pointer message is at (for when scrolling). */
static int mesg_viewpoint  = -1; /**< Position of viewing. */
static const double mesg_timeout = 45.; /**< Timeout length. */
/**
 * @struct Mesg
 *
 * @brief On screen player message.
 */
typedef struct Mesg_ {
   char *str; /**< The message (allocated). */
   double t; /**< Time to live for the message. */
   glFontRestore restore; /**< Hack for font restoration. */
} Mesg;
static Mesg* mesg_stack = NULL; /**< Stack of messages, will be of mesg_max size. */
static int gui_mesg_w = 0; /**< Width of messages. */
static int gui_mesg_x = 0; /**< X positioning of messages. */
static int gui_mesg_y = 0; /**< Y positioning of messages. */
static int gui_mesg_lines = 5; /**< Number of message lines visible at once. */

/* Calculations to speed up borders. */
static double gui_tr = 0.; /**< Border top-right. */
static double gui_br = 0.; /**< Border bottom-right. */
static double gui_tl = 0.; /**< Border top-left. */
static double gui_bl = 0.; /**< Border bottom-left. */

/* Intrinsic graphical stuff. */
static glTexture *gui_ico_hail      = NULL; /**< Hailing icon. */


/*
 * prototypes
 */
/*
 * external
 */
extern void weapon_minimap( const double res, const double w, const double h,
      const RadarShape shape, double alpha ); /**< from weapon.c */
/*
 * internal
 */
/* gui */
static void gui_renderTargetReticles( const SimpleShader *shd, double x, double y, double radius, double angle, const glColour* c );
static void gui_borderIntersection( double *cx, double *cy, double rx, double ry, double hw, double hh );
/* Render GUI. */
static void gui_renderPilotTarget (void);
static void gui_renderPlanetTarget (void);
static void gui_renderBorder( double dt );
static void gui_renderMessages( double dt );
static const glColour *gui_getPlanetColour( int i );
static void gui_renderRadarOutOfRange( RadarShape sh, int w, int h, int cx, int cy, const glColour *col );
static void gui_blink( double cx, double cy, double vr, const glColour *col, double blinkInterval, double blinkVar );
static const glColour* gui_getPilotColour( const Pilot* p );
static void gui_calcBorders (void);
/* Lua GUI. */
static int gui_doFunc( const char* func );
static int gui_prepFunc( const char* func );
static int gui_runFunc( const char* func, int nargs, int nret );



/**
 * Sets the GUI to defaults.
 */
void gui_setDefaults (void)
{
   gui_setRadarResolution( player.radar_res );
   gui_clearMessages();
}


/**
 * @brief Initializes the message system.
 *
 *    @param width Message width.
 *    @param x X position to set at.
 *    @param y Y position to set at.
 *    @param lines Number of lines displayed at once.
 */
void gui_messageInit(int width, int x, int y, int lines)
{
   gui_mesg_w = width;
   gui_mesg_x = x;
   gui_mesg_y = y;
   gui_mesg_lines = lines;
}


/**
 * @brief Scrolls up the message box.
 *
 *    @param lines Number of lines to scroll up.
 */
void gui_messageScrollUp( int lines )
{
   int o;

   /* Handle hacks. */
   if (mesg_viewpoint == -1) {
      mesg_viewpoint = mesg_pointer;
      return;
   }

   /* Get offset. */
   o  = mesg_pointer - mesg_viewpoint;
   if (o < 0)
      o += mesg_max;
   o = mesg_max - 2*gui_mesg_lines - o;


   /* Calculate max line movement. */
   if (lines > o)
      lines = o;

   /* Move viewpoint. */
   mesg_viewpoint = (mesg_viewpoint - lines) % mesg_max;
}


/**
 * @brief Scrolls up the message box.
 *
 *    @param lines Number of lines to scroll up.
 */
void gui_messageScrollDown( int lines )
{
   int o;

   /* Handle hacks. */
   if (mesg_viewpoint == mesg_pointer) {
      mesg_viewpoint = -1;
      return;
   }
   else if (mesg_viewpoint == -1)
      return;

   /* Get offset. */
   o  = mesg_pointer - mesg_viewpoint;
   if (o < 0)
      o += mesg_max;

   /* Calculate max line movement. */
   if (lines > o)
      lines = o;

   /* Move viewpoint. */
   mesg_viewpoint = (mesg_viewpoint + lines) % mesg_max;
}


/**
 * @brief Toggles if player should receive messages.
 *
 *    @param enable Whether or not to enable player receiving messages.
 */
void player_messageToggle( int enable )
{
   gui_getMessage = enable;
}


/**
 * @brief Adds a mesg to the queue to be displayed on screen.
 *
 *    @param str Message to add.
 */
void player_messageRaw( const char *str )
{
   glPrintLineIterator iter;

   /* Must be receiving messages. */
   if (!gui_getMessage)
      return;

   gl_printLineIteratorInit( &iter, NULL, str, gui_mesg_w - ((str[0] == '\t') ? 45 : 15) );
   while (gl_printLineIteratorNext( &iter )) {
      /* Move pointer. */
      mesg_pointer   = (mesg_pointer + 1) % mesg_max;
      if (mesg_viewpoint != -1)
         mesg_viewpoint++;

      /* Add the new one */
      free( mesg_stack[mesg_pointer].str );
      if (iter.l_begin == 0) {
         mesg_stack[mesg_pointer].str = strndup( &str[iter.l_begin], iter.l_end - iter.l_begin );
         gl_printRestoreInit( &mesg_stack[mesg_pointer].restore );
      }
      else {
         mesg_stack[mesg_pointer].str = malloc( iter.l_end - iter.l_begin + 2 );
         snprintf( mesg_stack[mesg_pointer].str, iter.l_end - iter.l_begin + 2, "\t%s", &str[iter.l_begin] );
         gl_printStoreMax( &mesg_stack[mesg_pointer].restore, str, iter.l_begin );
      }
      mesg_stack[mesg_pointer].t = mesg_timeout;

      iter.width = gui_mesg_w - 45; /* Remaining lines are tabbed so it's shorter. */
   }
}

/**
 * @brief Adds a mesg to the queue to be displayed on screen.
 *
 *    @param fmt String with formatting like printf.
 */
void player_message( const char *fmt, ... )
{
   va_list ap;
   char *buf;

   /* Must be receiving messages. */
   if (!gui_getMessage)
      return;

   /* Add the new one */
   va_start( ap, fmt );
   vasprintf( &buf, fmt, ap );
   va_end( ap );
   player_messageRaw( buf );
   free( buf );
}


/**
 * @brief Sets up rendering of planet and jump point targeting reticles.
 */
static void gui_renderPlanetTarget (void)
{
   double x,y, r;
   const glColour *c;
   Planet *planet;
   JumpPoint *jp;
   AsteroidAnchor *field;
   Asteroid *ast;
   AsteroidType *at;

   /* no need to draw if pilot is dead */
   if (player_isFlag(PLAYER_DESTROYED) || player_isFlag(PLAYER_CREATING)
         || (player.p == NULL) || pilot_isFlag(player.p,PILOT_DEAD))
      return;

   /* Make sure target exists. */
   if ((player.p->nav_planet < 0) && (player.p->nav_hyperspace < 0)
       && (player.p->nav_asteroid < 0))
      return;

   /* Draw planet and jump point target graphics. */
   if (player.p->nav_hyperspace >= 0) {
      jp = &cur_system->jumps[player.p->nav_hyperspace];

      c = &cFontJump;

      x = jp->pos.x;
      y = jp->pos.y;
      r = jumppoint_gfx->sw * 0.5;
      gui_renderTargetReticles( &shaders.targetplanet, x, y, r, 0., c );
   }
   if (player.p->nav_planet >= 0) {
      planet = cur_system->planets[player.p->nav_planet];
      c = planet_getColour( planet );

      x = planet->pos.x;
      y = planet->pos.y;
      r = planet->gfx_space->w * 0.5;
      gui_renderTargetReticles( &shaders.targetplanet, x, y, r, 0., c );
   }
   if (player.p->nav_asteroid >= 0) {
      field = &cur_system->asteroids[player.p->nav_anchor];
      ast   = &field->asteroids[player.p->nav_asteroid];
      c     = &cWhite;

      /* Recover the right gfx */
      at = space_getType( ast->type );
      if (ast->gfxID >= array_size(at->gfxs)) {
         WARN(_("Gfx index out of range"));
         return;
      }

      x = ast->pos.x;
      y = ast->pos.y;
      r = at->gfxs[ast->gfxID]->w * 0.5;
      gui_renderTargetReticles( &shaders.targetship, x, y, r, 0., c );
   }
}


/**
 * @brief Renders planet and jump point targeting reticles.
 *
 *    @param shd Shader to use to render.
 *    @param x X position of reticle segment.
 *    @param y Y position of reticle segment.
 *    @param radius Radius.
 *    @param angle Angle to rotate.
 *    @param c Colour.
 */
static void gui_renderTargetReticles( const SimpleShader *shd, double x, double y, double radius, double angle, const glColour* c )
{
   double rx, ry, r;

   gl_gameToScreenCoords( &rx, &ry, x, y );
   r = (double)radius *  1.2 * cam_getZoom();

   glUseProgram(shd->program);
   glUniform1f(shd->dt, animation_dt);
   glUniform1f(shd->paramf, radius);
   gl_renderShader( rx, ry, r, r, angle, shd, c, 1 );
}


/**
 * @brief Renders the players pilot target.
 */
static void gui_renderPilotTarget (void)
{
   Pilot *p;
   const glColour *c;

   /* Player has no target. */
   if (player.p->target == PLAYER_ID)
      return;

   /* Get the target. */
   p = pilot_get(player.p->target);

   /* Make sure pilot exists and is still alive. */
   if ((p == NULL) || pilot_isFlag(p, PILOT_DEAD)) {
      pilot_setTarget( player.p, player.p->id );
      gui_setTarget();
      return;
   }

   /* Make sure target is still valid and in range. */
   if (!pilot_validTarget( player.p, p )) {
      pilot_setTarget( player.p, player.p->id );
      gui_setTarget();
      return;
   }

   /* Draw the pilot target. */
   if (pilot_isDisabled(p))
      c = &cInert;
   else if (pilot_isHostile(p))
      c = &cHostile;
   else if (pilot_isFriendly(p))
      c = &cFriend;
   else
      c = &cNeutral;

   gui_renderTargetReticles( &shaders.targetship, p->solid->pos.x, p->solid->pos.y, p->ship->gfx_space->sw * 0.5, p->solid->dir, c );
}


/**
 * @brief Gets the intersection with the border.
 *
 * http://en.wikipedia.org/wiki/Intercept_theorem
 *
 *    @param[out] cx X intersection.
 *    @param[out] cy Y intersection.
 *    @param rx Center X position of intersection.
 *    @param ry Center Y position of intersection.
 *    @param hw Screen half-width.
 *    @param hh Screen half-height.
 */
static void gui_borderIntersection( double *cx, double *cy, double rx, double ry, double hw, double hh )
{
   double a;
   double w, h;

   /* Get angle. */
   a = atan2( ry, rx );
   if (a < 0.)
      a += 2.*M_PI;

   /* Helpers. */
   w = hw-7.;
   h = hh-7.;

   /* Handle by quadrant. */
   if ((a > gui_tr) && (a < gui_tl)) { /* Top. */
      *cx = h * (rx/ry);
      *cy = h;
   }
   else if ((a > gui_tl) && (a < gui_bl)) { /* Left. */
      *cx = -w;
      *cy = -w * (ry/rx);
   }
   else if ((a > gui_bl) && (a < gui_br)) { /* Bottom. */
      *cx = -h * (rx/ry);
      *cy = -h;
   }
   else { /* Right. */
      *cx = w;
      *cy = w * (ry/rx);
   }

   /* Translate. */
   *cx += hw;
   *cy += hh;
}


/**
 * @brief Renders the ships/planets in the border.
 *
 *    @param dt Current delta tick.
 */
static void gui_renderBorder( double dt )
{
   (void) dt;
   int i;
   Pilot *plt;
   Planet *pnt;
   JumpPoint *jp;
   int hw, hh;
   double rx,ry;
   double cx,cy;
   const glColour *col;
   Pilot * const *pilot_stack;

   /* Get player position. */
   hw    = SCREEN_W/2;
   hh    = SCREEN_H/2;

   /* Render borders to enhance contrast. */
   gl_renderRect(0., 0., 15., SCREEN_H, &cTransBack);
   gl_renderRect(SCREEN_W - 15., 0., 15., SCREEN_H, &cTransBack);
   gl_renderRect(15., 0., SCREEN_W - 30., 15., &cTransBack);
   gl_renderRect(15., SCREEN_H - 15., SCREEN_W - 30., 15., &cTransBack);

   /* Draw planets. */
   for (i=0; i<array_size(cur_system->planets); i++) {
      /* Check that it's real. */
      if (cur_system->planets[i]->real != ASSET_REAL)
         continue;

      pnt = cur_system->planets[i];

      /* Skip if unknown. */
      if (!planet_isKnown( pnt ))
         continue;

      /* Check if out of range. */
      if (!gui_onScreenAsset( &rx, &ry, NULL, pnt )) {

         /* Get border intersection. */
         gui_borderIntersection( &cx, &cy, rx, ry, hw, hh );

         col = gui_getPlanetColour(i);
         gl_drawCircle(cx, cy, 5, col, 0);
      }
   }

   /* Draw jump routes. */
   for (i=0; i<array_size(cur_system->jumps); i++) {
      jp  = &cur_system->jumps[i];

      /* Skip if unknown or exit-only. */
      if (!jp_isKnown( jp ) || jp_isFlag( jp, JP_EXITONLY ))
         continue;

      /* Check if out of range. */
      if (!gui_onScreenAsset( &rx, &ry, jp, NULL )) {

         /* Get border intersection. */
         gui_borderIntersection( &cx, &cy, rx, ry, hw, hh );

         if (i==player.p->nav_hyperspace)
            col = &cRadar_tPlanet;
         else if (jp_isFlag(jp, JP_HIDDEN))
            col = &cFontHiddenJump;
         else
            col = &cFontJump;

         gl_renderTriangleEmpty( cx, cy, -jp->angle, 10., 1., col );
      }
   }

   /* Draw pilots. */
   pilot_stack = pilot_getAll();
   for (i=1; i<array_size(pilot_stack); i++) { /* skip the player */
      plt = pilot_stack[i];

      /* See if in sensor range. */
      if (!pilot_inRangePilot(player.p, plt, NULL))
         continue;

      /* Check if out of range. */
      if (!gui_onScreenPilot( &rx, &ry, plt )) {

         /* Get border intersection. */
         gui_borderIntersection( &cx, &cy, rx, ry, hw, hh );

         col = gui_getPilotColour(plt);
         gl_renderRectEmpty(cx-5, cy-5, 10, 10, col);
      }
   }
}


/**
 * @brief Takes a pilot and returns whether it's on screen, plus its relative position.
 *
 * @param[out] rx Relative X position (factoring in viewport offset)
 * @param[out] ry Relative Y position (factoring in viewport offset)
 * @param pilot Pilot to determine the visibility and position of
 * @return Whether or not the pilot is on-screen.
 */
int gui_onScreenPilot( double *rx, double *ry, Pilot *pilot )
{
   double z;
   int cw, ch;
   glTexture *tex;

   z = cam_getZoom();

   tex = pilot->ship->gfx_space;

   /* Get relative positions. */
   *rx = (pilot->solid->pos.x - player.p->solid->pos.x)*z;
   *ry = (pilot->solid->pos.y - player.p->solid->pos.y)*z;

   /* Correct for offset. */
   *rx -= gui_xoff;
   *ry -= gui_yoff;

   /* Compare dimensions. */
   cw = SCREEN_W/2 + tex->sw/2;
   ch = SCREEN_H/2 + tex->sh/2;

   if ((ABS(*rx) > cw) || (ABS(*ry) > ch))
      return  0;

   return 1;
}


/**
 * @brief Takes a planet or jump point and returns whether it's on screen, plus its relative position.
 *
 * @param[out] rx Relative X position (factoring in viewport offset)
 * @param[out] ry Relative Y position (factoring in viewport offset)
 * @param jp Jump point to determine the visibility and position of
 * @param pnt Planet to determine the visibility and position of
 * @return Whether or not the given asset is on-screen.
 */
int gui_onScreenAsset( double *rx, double *ry, JumpPoint *jp, Planet *pnt )
{
   double z;
   int cw, ch;
   glTexture *tex;

   z = cam_getZoom();

   if (jp == NULL) {
      tex = pnt->gfx_space;
      *rx = (pnt->pos.x - player.p->solid->pos.x)*z;
      *ry = (pnt->pos.y - player.p->solid->pos.y)*z;
   }
   else {
      tex = jumppoint_gfx;
      *rx = (jp->pos.x - player.p->solid->pos.x)*z;
      *ry = (jp->pos.y - player.p->solid->pos.y)*z;
   }

   /* Correct for offset. */
   *rx -= gui_xoff;
   *ry -= gui_yoff;

   /* Compare dimensions. */
   cw = SCREEN_W/2 + tex->sw/2;
   ch = SCREEN_H/2 + tex->sh/2;

   if ((ABS(*rx) > cw) || (ABS(*ry) > ch))
      return  0;

   return 1;
}


/**
 * @brief Renders the gui targeting reticles.
 *
 * @param dt Current deltatick.
 */
void gui_renderReticles( double dt )
{
   (void) dt;

   /* Player must be alive. */
   if (player.p == NULL)
      return;

   gui_renderPlanetTarget();
   gui_renderPilotTarget();
}


static int can_jump = 0; /**< Stores whether or not the player is able to jump. */
/**
 * @brief Renders the player's GUI.
 *
 *    @param dt Current delta tick.
 */
void gui_render( double dt )
{
   int i;
   gl_Matrix4 projection;
   double fade, direction;

   /* If player is dead just render the cinematic mode. */
   if (!menu_isOpen(MENU_MAIN) &&
         (player_isFlag(PLAYER_DESTROYED) || player_isFlag(PLAYER_CREATING) ||
            ((player.p != NULL) && pilot_isFlag(player.p,PILOT_DEAD)))) {
      spfx_cinematic();
      return;
   }

   /* Make sure player is valid. */
   if (player.p == NULL)
      return;

   /* Cinematics mode. */
   if (player_isFlag( PLAYER_CINEMATICS_GUI ))
      return;

   /*
    * Countdown timers.
    */
   animation_dt   += dt / dt_mod;
   blink_pilot    -= dt / dt_mod;
   if (blink_pilot < 0.)
      blink_pilot += RADAR_BLINK_PILOT;
   blink_planet   -= dt / dt_mod;
   if (blink_planet < 0.)
      blink_planet += RADAR_BLINK_PLANET;

   /* Render the border ships and targets. */
   gui_renderBorder(dt);

   /* Set viewport. */
   gl_viewport( 0., 0., gl_screen.rw, gl_screen.rh );

   /* Run Lua. */
   if (gui_env != LUA_NOREF) {
      if (gui_prepFunc( "render" )==0) {
         lua_pushnumber( naevL, dt );
         lua_pushnumber( naevL, dt_mod );
         gui_runFunc( "render", 2, 0 );
      }
      if (pilot_isFlag(player.p, PILOT_COOLDOWN)) {
         if (gui_prepFunc( "render_cooldown" )==0) {
            lua_pushnumber( naevL, player.p->ctimer / player.p->cdelay  );
            lua_pushnumber( naevL, player.p->ctimer );
            gui_runFunc( "render_cooldown", 2, 0 );
         }
      }
   }

   /* Messages. */
   gui_renderMessages(dt);


   /* OSD. */
   osd_render();

   /* Noise when getting near a jump. */
   if (player.p->nav_hyperspace >= 0) { /* hyperspace target */

      /* Determine if we have to play the "enter hyperspace range" sound. */
      i = space_canHyperspace(player.p);
      if ((i != 0) && (i != can_jump))
         if (!pilot_isFlag(player.p, PILOT_HYPERSPACE))
            player_soundPlayGUI(snd_jump, 1);
      can_jump = i;
   }

   /* Determine if we need to fade in/out. */
   fade = direction = 0.;
   if (pilot_isFlag(player.p, PILOT_HYPERSPACE)
         && !pilot_isFlag(player.p, PILOT_LOCALJUMP)
         && (player.p->ptimer < HYPERSPACE_FADEOUT)) {
      fade = (HYPERSPACE_FADEOUT-player.p->ptimer) / HYPERSPACE_FADEOUT;
      direction = VANGLE(player.p->solid->vel);
   }
   else if (pilot_isFlag(player.p, PILOT_HYP_END)
         && !pilot_isFlag(player.p, PILOT_LOCALJUMP)
         && player.p->ptimer > 0.) {
      fade = player.p->ptimer / HYPERSPACE_FADEIN;
      direction = VANGLE(player.p->solid->vel) + M_PI;
   }
   /* Perform the fade. */
   if (fade > 0.) {
      /* Set up the program. */
      glUseProgram( shaders.jump.program );
      glEnableVertexAttribArray( shaders.jump.vertex );
      gl_vboActivateAttribOffset( gl_squareVBO, shaders.jump.vertex, 0, 2, GL_FLOAT, 0 );

      /* Set up the projection. */
      projection = gl_view_matrix;
      gl_Matrix4_Scale(&projection, gl_screen.nw, gl_screen.nh, 1.);

      /* Pass stuff over. */
      gl_Matrix4_Uniform( shaders.jump.projection, projection );
      glUniform1f( shaders.jump.progress, fade );
      glUniform1f( shaders.jump.direction, direction );
      glUniform2f( shaders.jump.dimensions, gl_screen.nw, gl_screen.nh );

      /* Set the subroutine. */
      if (gl_has( OPENGL_SUBROUTINES )) {
         if (cur_system->nebu_density > 0.)
            glUniformSubroutinesuiv( GL_FRAGMENT_SHADER, 1, &shaders.jump.jump_func.jump_nebula );
         else
            glUniformSubroutinesuiv( GL_FRAGMENT_SHADER, 1, &shaders.jump.jump_func.jump_wind );
      }

      /* Draw. */
      glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

      /* Clear state. */
      glDisableVertexAttribArray( shaders.jump.vertex );
      glUseProgram(0);

      /* Check errors. */
      gl_checkErr();
   }

   /* Reset viewport. */
   gl_defViewport();

   /* Render messages. */
   omsg_render( dt );
}


/**
 * @brief Notifies GUI scripts that the player broke out of cooldown.
 */
void gui_cooldownEnd (void)
{
   if (gui_env != LUA_NOREF)
      gui_doFunc( "end_cooldown" );
}


/**
 * @brief Sets map overlay bounds.
 *
 *    @param top Top boundary in pixels
 *    @param right Right boundary in pixels
 *    @param bottom Bottom boundary in pixels
 *    @param left Left boundary in pixels
 */
void gui_setMapOverlayBounds( int top, int right, int bottom, int left )
{
   map_overlay.boundTop = top;
   map_overlay.boundRight = right;
   map_overlay.boundBottom = bottom;
   map_overlay.boundLeft = left;
}

/**
 * @brief Gets map overlay bound (top)
 *
 *    @return Map overlay bound (top) in px
 */
int gui_getMapOverlayBoundTop(void)
{
  return map_overlay.boundTop;
}

/**
 * @brief Gets map overlay bound (right)
 *
 *    @return Map overlay bound (right) in px
 */
int gui_getMapOverlayBoundRight(void)
{
  return map_overlay.boundRight;
}

/**
 * @brief Gets map overlay bound (bottom)
 *
 *    @return Map overlay bound (bottom) in px
 */
int gui_getMapOverlayBoundBottom(void)
{
  return map_overlay.boundBottom;
}

/**
 * @brief Gets map overlay bound (left)
 *
 *    @return Map overlay bound (left) in px
 */
int gui_getMapOverlayBoundLeft(void)
{
  return map_overlay.boundLeft;
}


/**
 * @brief Initializes the radar.
 *
 *    @param circle Whether or not the radar is circular.
 *    @param w Radar width.
 *    @param h Radar height.
 */
int gui_radarInit( int circle, int w, int h )
{
   gui_radar.shape = circle ? RADAR_CIRCLE : RADAR_RECT;
   gui_radar.w = w;
   gui_radar.h = h;
   gui_radar.closed = 0;
   gui_setRadarResolution( player.radar_res );
   return 0;
}


/**
 * @brief Opens (un-closes) the radar.
 */
void gui_radarOpen(void)
{
   gui_radar.closed = 0;
}


/**
 * @brief Disables the radar.
 */
void gui_radarClose(void)
{
   gui_radar.closed = 1;
}


/**
 * @brief Renders the GUI radar.
 *
 *    @param x X position to render at.
 *    @param y Y position to render at.
 */
void gui_radarRender( double x, double y )
{
   int i, j;
   Radar *radar;
   gl_Matrix4 view_matrix_prev;
   Pilot * const *pilot_stack;
   const Pilot *p;
   const Pilot *target;
   Planet *planet;
   AsteroidAnchor *ast;

   /* The global radar. */
   radar = &gui_radar;
   gui_radar.x = x;
   gui_radar.y = y;

   if (gui_radar.closed)
      return;

   /* Get pilot stack for pilot rendering. */
   pilot_stack = pilot_getAll();

   /* TODO: modifying gl_view_matrix like this is a bit of a hack */
   /* TODO: use stensil test for RADAR_CIRCLE */
   view_matrix_prev = gl_view_matrix;
   if (radar->shape == RADAR_RECT) {
      gl_clipRect( x, y, radar->w, radar->h );
      gl_Matrix4_Translate(&gl_view_matrix,
            x + radar->w/2., y + radar->h/2., 0);
   }
   else if (radar->shape == RADAR_CIRCLE)
      gl_Matrix4_Translate(&gl_view_matrix, x, y, 0);

   /* Render planet hilights. */
   for (i=0; i<array_size(cur_system->planets); i++) {
      planet = cur_system->planets[i];
      if (planet->real != ASSET_REAL)
         continue;

      gui_renderPlanetHilight(i, radar->shape, radar->w, radar->h,
            radar->res, 0);
   }

   /* Render pilot hilights. */
   for (i=0; i<array_size(pilot_stack); i++) { /* skip the player */
      p = pilot_stack[i];
      if (p->id == PLAYER_ID)
         continue;

      gui_renderPilotHilight(p, radar->shape, radar->w, radar->h, radar->res, 0);
   }

   /*
    * Jump points.
    */
   for (i=0; i<array_size(cur_system->jumps); i++)
      if (i != player.p->nav_hyperspace && jp_isUsable(&cur_system->jumps[i]))
         gui_renderJumpPoint( i, radar->shape, radar->w, radar->h, radar->res, 0 );
   if (player.p->nav_hyperspace >= 0) {
      gui_renderJumpPoint( player.p->nav_hyperspace, radar->shape, radar->w, radar->h, radar->res, 0 );
   }

   /* Render the planets. Target (if any) is rendered separately so it's
    * always on top. */
   for (i=0; i<array_size(cur_system->planets); i++) {
      planet = cur_system->planets[i];
      if ((planet->real == ASSET_REAL) && (i != player.p->nav_planet))
         gui_renderPlanet(i, radar->shape, radar->w, radar->h, radar->res, 0);
   }
   if (player.p->nav_planet >= 0) {
      
      gui_renderPlanet(player.p->nav_planet, radar->shape, radar->w, radar->h,
            radar->res, 0);
   }

   /*
    * weapons
    */
   weapon_minimap( radar->res, radar->w, radar->h, radar->shape, 1. );

   /* Render the asteroids. */
   for (i=0; i<array_size(cur_system->asteroids); i++) {
      ast = &cur_system->asteroids[i];
      for (j=0; j<ast->nb; j++)
         gui_renderAsteroid(&ast->asteroids[j], radar->shape,
               radar->w, radar->h, radar->res, 0);
   }

   /* Render the pilots. Target (if any) is rendered separately so it's
    * always on top. */
   target = NULL;
   for (i=1; i<array_size(pilot_stack); i++) { /* skip the player */
      p = pilot_stack[i];
      if (p->id == PLAYER_ID)
         continue;

      if (p->id == player.p->target)
         target = p;
      else
         gui_renderPilot(p, radar->shape, radar->w, radar->h, radar->res, 0);
   }
   if (target != NULL)
      gui_renderPilot(target, radar->shape, radar->w, radar->h, radar->res, 0);

   /* Render the player cross. */
   gui_renderPlayer(radar->w, radar->h, radar->res, 0);

   gl_view_matrix = view_matrix_prev;
   if (radar->shape==RADAR_RECT)
      gl_unclipRect();
}


/**
 * @brief Outputs the radar's resolution.
 *
 *    @param[out] res Current zoom ratio.
 */
void gui_radarGetRes( double* res )
{
   *res = gui_radar.res;
}


/**
 * @brief Clears the GUI messages.
 */
void gui_clearMessages (void)
{
   for (int i = 0; i < mesg_max; i++)
      free( mesg_stack[i].str );
   memset( mesg_stack, 0, sizeof(Mesg)*mesg_max );
}


/**
 * @brief Renders the player's messages on screen.
 *
 *    @param dt Current delta tick.
 */
static void gui_renderMessages( double dt )
{
   double x, y, h, hs, vx, vy, dy;
   int v, i, m, o;
   glColour c, msgc;

   /* Coordinate translation. */
   x = gui_mesg_x;
   y = gui_mesg_y;

   /* Handle viewpoint hacks. */
   v = mesg_viewpoint;
   if (v == -1)
      v = mesg_pointer;

   /* Colour. */
   c.r = 1.;
   c.g = 1.;
   c.b = 1.;
   msgc.r = 0.;
   msgc.g = 0.;
   msgc.b = 0.;
   msgc.a = 0.6;

   /* Render background. */
   h = 0;

   /* Set up position. */
   vx = x;
   vy = y;

   /* Must be run here. */
   hs = 0.;
   o = 0;
   if (mesg_viewpoint != -1) {
      /* Data. */
      hs = h * (double)gui_mesg_lines / (double)mesg_max;
      o  = mesg_pointer - mesg_viewpoint;
      if (o < 0)
         o += mesg_max;
   }

   /* Render text. */
   for (i=0; i<gui_mesg_lines; i++) {
      /* Reference translation. */
      m  = (v - i) % mesg_max;
      if (m < 0)
         m += mesg_max;

      /* Timer handling. */
      if ((mesg_viewpoint != -1) || (mesg_stack[m].t >= 0.)) {
         /* Decrement timer. */
         if (mesg_viewpoint == -1)
            mesg_stack[m].t -= dt / dt_mod;

         /* Only handle non-NULL messages. */
         if (mesg_stack[m].str != NULL) {
            if (mesg_stack[m].str[0] == '\t') {
               gl_printRestore( &mesg_stack[m].restore );
               dy = gl_printHeightRaw( NULL, gui_mesg_w, &mesg_stack[m].str[1]) + 6;
               gl_renderRect( x-4., y-1., gui_mesg_w-13., dy, &msgc );
               gl_printMaxRaw( NULL, gui_mesg_w - 45., x + 30, y + 3, &cFontWhite, -1., &mesg_stack[m].str[1] );
            } else {
               dy = gl_printHeightRaw( NULL, gui_mesg_w, mesg_stack[m].str) + 6;
               gl_renderRect( x-4., y-1., gui_mesg_w-13., dy, &msgc );
               gl_printMaxRaw( NULL, gui_mesg_w - 15., x, y + 3, &cFontWhite, -1., mesg_stack[m].str );
            }
            h += dy;
            y += dy;
         }
      }

      /* Increase position. */
   }

   /* Render position. */
   if (mesg_viewpoint != -1) {
      /* Border. */
      c.a = 0.2;
      gl_renderRect( vx + gui_mesg_w-10., vy, 10, h, &c );

      /* Inside. */
      c.a = 0.5;
      gl_renderRect(vx + gui_mesg_w-10.,
            vy + hs/2. + (h-hs)*((double)o/(double)(mesg_max-gui_mesg_lines)),
            10, hs, &c);
   }
}


/**
 * @brief Gets a pilot's colour, with a special colour for targets.
 *
 *    @param p Pilot to get colour of.
 *    @return The colour of the pilot.
 *
 * @sa pilot_getColour
 */
static const glColour* gui_getPilotColour( const Pilot* p )
{
   const glColour *col;

   if (p->id == player.p->target)
      col = &cRadar_tPilot;
   else
      col = pilot_getColour(p);

   return col;
}


/**
 * @brief Renders a pilot in the GUI radar.
 *
 *    @param p Pilot to render.
 *    @param shape Shape of the radar (RADAR_RECT or RADAR_CIRCLE).
 *    @param w Width.
 *    @param h Height.
 *    @param res Radar resolution.
 *    @param overlay Whether to render onto the overlay.
 */
void gui_renderPilot(const Pilot* p, RadarShape shape, double w, double h,
      double res, int overlay)
{
   double x, y;
   double scale;
   const glColour *col;

   /* Make sure is in range. */
   if (!pilot_validTarget( player.p, p ))
      return;

   /* Get position. */
   if (overlay) {
      x = (p->solid->pos.x / res);
      y = (p->solid->pos.y / res);
   }
   else {
      x = ((p->solid->pos.x-player.p->solid->pos.x) / res);
      y = ((p->solid->pos.y-player.p->solid->pos.y) / res);
   }
   /* Get size. */
   scale = p->ship->rdr_scale * (1. + RADAR_RES_REF/res);

   /* Check if within radar bounds. */
   if (((shape == RADAR_RECT)
            && ((ABS(x) > (w-scale) / 2.) || (ABS(y) > (h-scale) / 2.)))
         || ((shape == RADAR_CIRCLE)
            && (pow2(x) + pow2(y) > pow2(w)))) {
      /* Draw little targeted symbol. */
      if (p->id == player.p->target && !overlay)
         gui_renderRadarOutOfRange(shape, w, h, x, y, &cRadar_tPilot);
      return;
   }

   /* Transform coordinates into the 0,0 -> SCREEN_W, SCREEN_H range. */
   if (overlay) {
      x += map_overlay_center_x();
      y += map_overlay_center_y();
      w *= 2.;
      h *= 2.;
   }

   /* Compensate scale for outline. */
   scale = MAX(scale + 2., 4.);

   if (p->id == player.p->target)
      col = &cRadar_tPilot;
   else
      col = gui_getPilotColour(p);

   glUseProgram(shaders.pilotmarker.program);
   gl_renderShader(x, y, scale, scale, p->solid->dir, &shaders.pilotmarker,
         col, 1);

   /* Draw selection if targeted. */
   if (p->id == player.p->target)
      gui_blink(x, y, MAX(scale * 2., 7.), &cRadar_tPilot, RADAR_BLINK_PILOT,
            blink_pilot);
}


/**
 * @brief Renders a pilot's hilight in the GUI radar.
 *
 *    @param p Pilot to render hilight of.
 *    @param shape Shape of the radar (RADAR_RECT or RADAR_CIRCLE).
 *    @param w Width.
 *    @param h Height.
 *    @param res Radar resolution.
 *    @param overlay Whether to render onto the overlay.
 */
void gui_renderPilotHilight(const Pilot* p, RadarShape shape,
      double w, double h, double res, int overlay)
{
   double x, y;
   double scale;
   glColour col_hilight;

   /* Make sure is in range. */
   if (!pilot_validTarget(player.p, p))
      return;

   /* Skip if not hilighted. */
   if (!pilot_isFlag(p, PILOT_HILIGHT))
      return;

   /* Get position. */
   if (overlay) {
      x = (p->solid->pos.x / res);
      y = (p->solid->pos.y / res);
   }
   else {
      x = ((p->solid->pos.x-player.p->solid->pos.x) / res);
      y = ((p->solid->pos.y-player.p->solid->pos.y) / res);
   }
   /* Get size. */
   scale = p->ship->rdr_scale * (1. + RADAR_RES_REF/res);

   /* Check if within radar bounds. */
   if (((shape == RADAR_RECT)
            && ((ABS(x) > (w-scale) / 2.) || (ABS(y) > (h-scale) / 2.)))
         || ((shape == RADAR_CIRCLE)
            && (pow2(x) + pow2(y) > pow2(w)))) {
      return;
   }

   /* Transform coordinates into the 0,0 -> SCREEN_W, SCREEN_H range. */
   if (overlay) {
      x += map_overlay_center_x();
      y += map_overlay_center_y();
      w *= 2.;
      h *= 2.;
   }

   /* Compensate scale for outline. */
   scale = MAX(scale + 2., 4.);

   col_hilight = cRadar_hilight;
   col_hilight.a = 0.3;

   glUseProgram(shaders.hilight.program);
   glUniform1f(shaders.hilight.dt, animation_dt);
   gl_renderShader(x, y, MAX(scale * 2., 7.), MAX(scale * 2., 7.), 0.,
         &shaders.hilight, &col_hilight, 1);
}


/**
 * @brief Renders an asteroid in the GUI radar.
 *
 *    @param a Asteroid to render.
 *    @param shape Shape of the radar (RADAR_RECT or RADAR_CIRCLE).
 *    @param w Width.
 *    @param h Height.
 *    @param res Radar resolution.
 *    @param overlay Whether to render onto the overlay.
 */
void gui_renderAsteroid(const Asteroid* a, RadarShape shape,
      double w, double h, double res, int overlay)
{
   int i, j, targeted;
   double x, y, r, sx, sy;
   double px, py;
   const glColour *col;

   /* Skip invisible asteroids */
   if (a->appearing == ASTEROID_INVISIBLE)
      return;

   /* Recover the asteroid and field IDs. */
   i = a->id;
   j = a->parent;

   /* Make sure is in range. */
   if (!pilot_inRangeAsteroid( player.p, i, j ))
      return;

   targeted = ((i == player.p->nav_asteroid) && (j == player.p->nav_anchor));

   /* Get position. */
   if (overlay) {
      x = (a->pos.x / res);
      y = (a->pos.y / res);
   }
   else {
      x = ((a->pos.x - player.p->solid->pos.x) / res);
      y = ((a->pos.y - player.p->solid->pos.y) / res);
   }

   /* Get size. */
   sx = 1.;
   sy = 1.;

   /* Check if within radar bounds. */
   if (((shape == RADAR_RECT)
            && ((ABS(x) > w / 2.) || (ABS(y) > h / 2.)))
         || ((shape == RADAR_CIRCLE)
            && (pow2(x) + pow2(y) > pow2(w)))) {
      /* Draw little targeted symbol. */
      if (targeted && !overlay)
         gui_renderRadarOutOfRange(shape, w, h, x, y, &cWhite);
      return;
   }

   /* Transform coordinates into the 0,0 -> SCREEN_W, SCREEN_H range. */
   if (overlay) {
      x += map_overlay_center_x();
      y += map_overlay_center_y();
      w *= 2.;
      h *= 2.;
   }

   /* Draw square. */
   px     = MAX(x-sx, -w);
   py     = MAX(y-sy, -h);

   /* Colour depends if the asteroid is selected. */
   if (targeted)
      col = &cWhite;
   else
      col = &cGrey70;

   r = (sx+sy)/2.0+1.5;
   glUseProgram(shaders.asteroidmarker.program);
   gl_renderShader( px, py, r, r, 0., &shaders.asteroidmarker, col, 1 );

   if (targeted)
      gui_blink( px, py, MAX(7., 2.0*r), col, RADAR_BLINK_PILOT, blink_pilot );
}


/**
 * @brief Renders the player cross on the radar or whatever.
 */
void gui_renderPlayer(double w, double h, double res, int overlay)
{
   double x, y;
   double r;

   if (overlay) {
      x = player.p->solid->pos.x / res;
      y = player.p->solid->pos.y / res;
      r = MAX(14., 1.5 * player.p->ship->rdr_scale * (1. + RADAR_RES_REF/res));

      /* Check if within radar bounds. */
      if ((ABS(x) > (w-r) / 2.) || (ABS(y) > (h-r) / 2.))
         return;

      /* Transform coordinates into the 0,0 → SCREEN_W,SCREEN_H range. */
      x += map_overlay_center_x();
      y += map_overlay_center_y();
   }
   else {
      x = 0.;
      y = 0.;
      r = MAX(12., 1.25 * player.p->ship->rdr_scale * (1. + RADAR_RES_REF/res));
   }

   glUseProgram(shaders.playermarker.program);
   gl_renderShader(x, y, r, r, player.p->solid->dir, &shaders.playermarker,
         &cRadar_player, 1);
}


/**
 * @brief Gets the colour of a planet.
 *
 *    @param i Index of the planet to get colour of.
 *    @return Colour of the planet.
 */
static const glColour *gui_getPlanetColour( int i )
{
   const glColour *col;
   Planet *planet;

   planet = cur_system->planets[i];

   if (i == player.p->nav_planet)
      col = &cRadar_tPlanet;
   else
      col = planet_getColour( planet );

   return col;
}


/**
 * @brief Force sets the planet and pilot radar blink.
 */
void gui_forceBlink (void)
{
   blink_pilot  = 0.;
   blink_planet = 0.;
}


/**
 * @brief Renders the planet blink around a position on the minimap.
 */
static void gui_blink( double cx, double cy, double vr, const glColour *col, double blinkInterval, double blinkVar )
{
   if (blinkVar > blinkInterval/2.)
      return;
   glUseProgram(shaders.blinkmarker.program);
   gl_renderShader( cx, cy, vr, vr, 0., &shaders.blinkmarker, col, 1 );
}


/**
 * @brief Renders an out of range marker for the planet.
 */
static void gui_renderRadarOutOfRange( RadarShape sh, int w, int h, int cx, int cy, const glColour *col )
{
   double a, x, y, x2, y2;

   /* Draw a line like for pilots. */
   a = ANGLE(cx,cy);
   if (sh == RADAR_CIRCLE) {
      x = w * cos(a);
      y = w * sin(a);
   }
   else {
      int cxa, cya;
      cxa = ABS(cx);
      cya = ABS(cy);
      /* Determine position. */
      if (cy >= cxa) { /* Bottom */
         x = w/2. * (cx*1./cy);
         y = h/2.;
      } else if (cx >= cya) { /* Left */
         x = w/2.;
         y = h/2. * (cy*1./cx);
      } else if (cya >= cxa) { /* Top */
         x = -w/2. * (cx*1./cy);
         y = -h/2.;
      } else { /* Right */
         x = -w/2.;
         y = -h/2. * (cy*1./cx);
      }
   }
   x2 = x - .15 * w * cos(a);
   y2 = y - .15 * w * sin(a);

   gl_drawLine( x, y, x2, y2, col );
}


/**
 * @brief Draws a position marker in the minimap.
 */
void gui_renderMarker(double x, double y)
{
   glUseProgram(shaders.hilight_pos.program);
   glUniform1f(shaders.hilight_pos.dt, animation_dt);
   gl_renderShader(x, y, 18., 18., 0., &shaders.hilight_pos, &cRadar_hilight, 1);
}


/**
 * @brief Draws the planets in the minimap.
 *
 *    @param planet_ind Planet to render (index of cur_system->planets).
 *    @param shape Shape of the radar (RADAR_RECT or RADAR_CIRCLE).
 *    @param w Width.
 *    @param h Height.
 *    @param res Radar resolution.
 *    @param overlay Whether to render onto the overlay.
 */
void gui_renderPlanet(int planet_ind, RadarShape shape, double w, double h,
      double res, int overlay)
{
   GLfloat cx, cy, x, y, r, vr;
   const glColour *col;
   Planet *planet;
   char buf[STRMAX_SHORT];

   planet = cur_system->planets[planet_ind];

   /* Make sure is known. */
   if (!planet_isKnown(planet))
      return;

   /* Default values. */
   r = planet->radius / res;
   vr = overlay ? planet->mo.radius : MAX(r, 7.5);

   if (overlay) {
      cx = planet->pos.x / res;
      cy = planet->pos.y / res;
   }
   else {
      cx = (planet->pos.x-player.p->solid->pos.x) / res;
      cy = (planet->pos.y-player.p->solid->pos.y) / res;
   }

   /* Check if in range. */
   if (shape == RADAR_CIRCLE) {
      x = ABS(cx) - r;
      y = ABS(cy) - r;
      /* Out of range. */
      if (x*x + y*y > pow2(w - 2*r)) {
         if ((planet_ind == player.p->nav_planet) && !overlay)
            gui_renderRadarOutOfRange(RADAR_CIRCLE, w, w, cx, cy,
                  &cRadar_tPlanet);
         return;
      }
   }
   else {
      if (shape == RADAR_RECT) {
         /* Out of range. */
         if ((ABS(cx) - r > w / 2.) || (ABS(cy) - r  > h / 2.)) {
            if ((planet_ind == player.p->nav_planet) && !overlay)
               gui_renderRadarOutOfRange(RADAR_RECT, w, h, cx, cy,
                     &cRadar_tPlanet);
            return;
         }
      }
   }

   if (overlay) {
      /* Transform coordinates. */
      cx += map_overlay_center_x();
      cy += map_overlay_center_y();
      w *= 2.;
      h *= 2.;
   }

   /* Get the colour. */
   col = gui_getPlanetColour(planet_ind);

   /* Do the blink. */
   if (planet_ind == player.p->nav_planet)
      gui_blink(cx, cy, vr*2., col, RADAR_BLINK_PLANET, blink_planet);

   glUseProgram(shaders.planetmarker.program);
   glUniform1i(shaders.planetmarker.parami,
         planet_hasService(planet, PLANET_SERVICE_LAND));
   gl_renderShader(cx, cy, vr, vr, 0., &shaders.planetmarker, col, 1);

   if (overlay) {
      snprintf(buf, sizeof(buf), "%s%s",
            planet_getSymbol(planet), _(planet->name));
      gl_printMarkerRaw(&gl_smallFont, cx + planet->mo.text_offx,
            cy + planet->mo.text_offy, col, buf);
   }
}


/**
 * @brief Draws planet hilights in the minimap.
 *
 *    @param planet_ind Planet to render hilight of.
 *    @param shape Shape of the radar (RADAR_RECT or RADAR_CIRCLE).
 *    @param w Width.
 *    @param h Height.
 *    @param res Radar resolution.
 *    @param overlay Whether to render onto the overlay.
 */
void gui_renderPlanetHilight(int planet_ind, RadarShape shape,
      double w, double h, double res, int overlay)
{
   GLfloat cx, cy, x, y, r, vr;
   Planet *planet;
   glColour col_hilight;

   planet = cur_system->planets[planet_ind];

   /* Make sure is known. */
   if (!planet_isKnown(planet))
      return;

   /* Skip if not hilighted. */
   if (!planet_isFlag(planet, PLANET_HILIGHT) && (planet->hilights <= 0))
      return;

   /* Default values. */
   r = planet->radius / res;
   vr = overlay ? planet->mo.radius : MAX(r, 7.5);

   if (overlay) {
      cx = planet->pos.x / res;
      cy = planet->pos.y / res;
   }
   else {
      cx = (planet->pos.x-player.p->solid->pos.x) / res;
      cy = (planet->pos.y-player.p->solid->pos.y) / res;
   }

   /* Check if in range. */
   if (shape == RADAR_CIRCLE) {
      x = ABS(cx) - r;
      y = ABS(cy) - r;
      /* Out of range. */
      if (x*x + y*y > pow2(w - 2*r)) {
         if ((planet_ind == player.p->nav_planet) && !overlay)
            gui_renderRadarOutOfRange(RADAR_CIRCLE, w, w, cx, cy,
                  &cRadar_tPlanet);
         return;
      }
   }
   else {
      if (shape == RADAR_RECT) {
         /* Out of range. */
         if ((ABS(cx) - r > w / 2.) || (ABS(cy) - r  > h / 2.)) {
            if ((planet_ind == player.p->nav_planet) && !overlay)
               gui_renderRadarOutOfRange(RADAR_RECT, w, h, cx, cy,
                     &cRadar_tPlanet);
            return;
         }
      }
   }

   if (overlay) {
      /* Transform coordinates. */
      cx += map_overlay_center_x();
      cy += map_overlay_center_y();
      w *= 2.;
      h *= 2.;
   }

   col_hilight = cRadar_hilight;
   col_hilight.a = 0.3;

   glUseProgram(shaders.hilight.program);
   glUniform1f(shaders.hilight.dt, animation_dt);
   gl_renderShader(cx, cy, vr * 3., vr * 3., 0., &shaders.hilight,
         &col_hilight, 1);
}


/**
 * @brief Renders a jump point on the minimap.
 *
 *    @param ind Jump point to render.
 *    @param shape Shape of the radar (RADAR_RECT or RADAR_CIRCLE).
 *    @param w Width.
 *    @param h Height.
 *    @param res Radar resolution.
 *    @param overlay Whether to render onto the overlay.
 */
void gui_renderJumpPoint( int ind, RadarShape shape, double w, double h, double res, int overlay )
{
   GLfloat cx, cy, x, y, r, vr;
   const glColour *col;
   JumpPoint *jp;
   char buf[STRMAX_SHORT];
   glColour col_hilight;

   jp = &cur_system->jumps[ind];

   /* Check if known */
   if (!jp_isKnown(jp))
      return;

   r = jumppoint_gfx->sw/2. / res;
   vr = overlay ? jp->mo.radius : MAX(r, 5.);
   if (overlay) {
      cx = jp->pos.x / res;
      cy = jp->pos.y / res;
   }
   else {
      cx = (jp->pos.x-player.p->solid->pos.x) / res;
      cy = (jp->pos.y-player.p->solid->pos.y) / res;
   }

   /* Check if in range. */
   if (shape == RADAR_RECT) {
      /* Out of range. */
      if ((ABS(cx) - r > w/2.) || (ABS(cy) - r  > h/2.)) {
         if ((player.p->nav_hyperspace == ind) && !overlay)
            gui_renderRadarOutOfRange( RADAR_RECT, w, h, cx, cy, &cRadar_tPlanet );
         return;
      }
   }
   else if (shape == RADAR_CIRCLE) {
      x = ABS(cx)-r;
      y = ABS(cy)-r;
      /* Out of range. */
      if (x*x + y*y > pow2(w-2*r)) {
         if ((player.p->nav_hyperspace == ind) && !overlay)
            gui_renderRadarOutOfRange( RADAR_CIRCLE, w, w, cx, cy, &cRadar_tPlanet );
         return;
      }
   }

   if (overlay) {
      /* Transform coordinates. */
      cx += map_overlay_center_x();
      cy += map_overlay_center_y();
      w *= 2.;
      h *= 2.;
   }

   if (jp_isFlag(jp, JP_HILIGHT) || (jp->hilights > 0)) {
      col_hilight = cRadar_hilight;
      col_hilight.a = 0.3;
      glUseProgram(shaders.hilight.program);
      glUniform1f(shaders.hilight.dt, animation_dt);
      gl_renderShader(cx, cy, vr * 3., vr * 3., 0., &shaders.hilight,
            &col_hilight, 1);
   }

   if (ind == player.p->nav_hyperspace)
      col = &cRadar_tPlanet;
   else if (jp_isFlag(jp, JP_HIDDEN))
      col = &cFontHiddenJump;
   else
      col = &cFontJump;

   glUseProgram(shaders.jumpmarker.program);
   gl_renderShader(cx, cy, vr*1.5, vr*1.5, -jp->angle+M_PI,
         &shaders.jumpmarker, col, 1);

   /* Blink ontop. */
   if (ind == player.p->nav_hyperspace)
      gui_blink( cx, cy, vr*3., col, RADAR_BLINK_PLANET, blink_planet );

   /* Render name. */
   if (overlay) {
      snprintf(buf, sizeof(buf), "%s%s", jump_getSymbol(jp),
            (sys_isKnown(jp->target) || sys_isMarked(jp->target)) ?
               _(jp->target->name) : _("Unknown"));
      gl_printMarkerRaw( &gl_smallFont, cx+jp->mo.text_offx, cy+jp->mo.text_offy, col, buf );
   }
}


/**
 * @brief Sets the viewport.
 */
void gui_setViewport( double x, double y, double w, double h )
{
   gui_viewport_x = x;
   gui_viewport_y = y;
   gui_viewport_w = w;
   gui_viewport_h = h;

   /* We now set the viewport. */
   gl_setDefViewport( gui_viewport_x, gui_viewport_y, gui_viewport_w, gui_viewport_h );
   gl_defViewport();

   /* Run border calculations. */
   gui_calcBorders();
}


/**
 * @brief Resets the viewport.
 */
void gui_clearViewport (void)
{
   gui_setViewport(0., 0., gl_screen.nw, gl_screen.nh);
}


/**
 * @brief Calculates and sets the GUI borders.
 */
static void gui_calcBorders (void)
{
   double w,h;

   /* Precalculations. */
   w  = SCREEN_W/2.;
   h  = SCREEN_H/2.;

   /*
    * Borders.
    */
   gui_tl = atan2( +h, -w );
   if (gui_tl < 0.)
      gui_tl += 2*M_PI;
   gui_tr = atan2( +h, +w );
   if (gui_tr < 0.)
      gui_tr += 2*M_PI;
   gui_bl = atan2( -h, -w );
   if (gui_bl < 0.)
      gui_bl += 2*M_PI;
   gui_br = atan2( -h, +w );
   if (gui_br < 0.)
      gui_br += 2*M_PI;
}


/**
 * @brief Initializes the GUI system.
 *
 *    @return 0 on success;
 */
int gui_init (void)
{
   GLfloat vertex[16];

   /*
    * radar
    */
   gui_setRadarResolution( player.radar_res );

   /*
    * messages
    */
   gui_mesg_x = 20;
   gui_mesg_y = 30;
   gui_mesg_w = SCREEN_W - 400;
   if (mesg_stack == NULL) {
      mesg_stack = calloc(mesg_max, sizeof(Mesg));
      if (mesg_stack == NULL) {
         ERR(_("Out of Memory"));
         return -1;
      }
   }

   /*
    * VBO.
    */

   if (gui_radar_select_vbo == NULL) {
      vertex[0] = -1.5;
      vertex[1] = 1.5;
      vertex[2] = -3.3;
      vertex[3] = 3.3;
      vertex[4] = 1.5;
      vertex[5] = 1.5;
      vertex[6] = 3.3;
      vertex[7] = 3.3;
      vertex[8] = 1.5;
      vertex[9] = -1.5;
      vertex[10] = 3.3;
      vertex[11] = -3.3;
      vertex[12] = -1.5;
      vertex[13] = -1.5;
      vertex[14] = -3.3;
      vertex[15] = -3.3;
      gui_radar_select_vbo = gl_vboCreateStatic( sizeof(GLfloat) * 16, vertex );
   }

   /*
    * OSD
    */
   osd_setup( 30., SCREEN_H-90., 150., 300. );

   /*
    * Set viewport.
    */
   gui_setViewport( 0., 0., gl_screen.w, gl_screen.h );

   /*
    * Icons.
    */
   gui_ico_hail = gl_newSprite( GUI_GFX_PATH"hail.webp", 5, 2, 0 );

   return 0;
}


/**
 * @brief Runs a GUI Lua function.
 *
 *    @param func Name of the function to run.
 *    @return 0 on success.
 */
static int gui_doFunc( const char* func )
{
   int ret = gui_prepFunc( func );
   if (ret)
      return ret;
   return gui_runFunc( func, 0, 0 );
}


/**
 * @brief Prepares to run a function.
 */
static int gui_prepFunc( const char* func )
{
#if DEBUGGING
   if (gui_env == LUA_NOREF) {
      WARN( _("GUI '%s': Trying to run GUI func '%s' but no GUI is loaded!"), gui_name, func );
      return -1;
   }
#endif /* DEBUGGING */

   /* Set up function. */
   nlua_getenv( gui_env, func );
#if DEBUGGING
   if (lua_isnil( naevL, -1 )) {
      WARN(_("GUI '%s': no function '%s' defined!"), gui_name, func );
      lua_pop(naevL,1);
      return -1;
   }
#endif /* DEBUGGING */
   return 0;
}


/**
 * @brief Runs a function.
 * @note Function must be prepared beforehand.
 *    @param func Name of the function to run.
 *    @param nargs Arguments to the function.
 *    @param nret Parameters to get returned from the function.
 */
static int gui_runFunc( const char* func, int nargs, int nret )
{
   int ret;
   const char* err;

   /* Run the function. */
   ret = nlua_pcall( gui_env, nargs, nret );
   if (ret != 0) { /* error has occurred */
      err = (lua_isstring(naevL,-1)) ? lua_tostring(naevL,-1) : NULL;
      WARN(_("GUI '%s' Lua -> '%s': %s"), gui_name,
            func, (err) ? err : _("unknown error"));
      lua_pop(naevL,1);
      return ret;
   }

   return ret;
}


/**
 * @brief Reloads the GUI.
 */
void gui_reload (void)
{
   if (gui_env == LUA_NOREF)
      return;

   gui_load( gui_pick() );
}


/**
 * @brief Player just changed their cargo.
 */
void gui_setCargo (void)
{
   if (gui_env != LUA_NOREF)
      gui_doFunc( "update_cargo" );
}


/**
 * @brief Player just changed their nav computer target.
 */
void gui_setNav (void)
{
   if (gui_env != LUA_NOREF)
      gui_doFunc( "update_nav" );
}


/**
 * @brief Player just changed their pilot target.
 */
void gui_setTarget (void)
{
   if (gui_env != LUA_NOREF)
      gui_doFunc( "update_target" );
}


/**
 * @brief Player just upgraded their ship or modified it.
 */
void gui_setShip (void)
{
   if (gui_env != LUA_NOREF)
      gui_doFunc( "update_ship" );
}


/**
 * @brief Player just changed their system.
 */
void gui_setSystem (void)
{
   if (gui_env != LUA_NOREF)
      gui_doFunc( "update_system" );
}


/**
 * @brief Player's relationship with a faction was modified.
 */
void gui_updateFaction (void)
{
   if (gui_env != LUA_NOREF && player.p->nav_planet != -1)
      gui_doFunc( "update_faction" );
}


/**
 * @brief Calls trigger functions depending on who the pilot is.
 *
 *    @param pilot The pilot to act based upon.
 */
void gui_setGeneric( Pilot* pilot )
{
   if (gui_env == LUA_NOREF)
      return;

   if (player_isFlag(PLAYER_DESTROYED) || player_isFlag(PLAYER_CREATING) ||
      (player.p == NULL) || pilot_isFlag(player.p,PILOT_DEAD))
      return;

   if ((player.p->target != PLAYER_ID) && (pilot->id == player.p->target))
      gui_setTarget();
   else if (pilot_isPlayer(pilot)) {
      gui_setCargo();
      gui_setShip();
   }
}


/**
 * @brief Determines which GUI should be used.
 */
char* gui_pick (void)
{
   char* gui;

   /* Don't do set a gui if player is dead. This can be triggered through
    * naev_resize and can cause an issue if player is dead. */
   if ((player.p == NULL) || pilot_isFlag(player.p,PILOT_DEAD))
      gui = NULL;
   else if (player.gui && (player.guiOverride == 1 || strcmp(player.p->ship->gui,"default")==0))
      gui = player.gui;
   else
      gui = player.p->ship->gui;
   return gui;
}


/**
 * @brief Attempts to load the actual GUI.
 *
 *    @param name Name of the GUI to load.
 *    @return 0 on success.
 */
int gui_load( const char* name )
{
   char *buf, path[PATH_MAX];
   size_t bufsize;

   /* Set defaults. */
   gui_cleanup();
   if (name==NULL)
      return 0;
   gui_name = strdup(name);

   /* Open file. */
   snprintf( path, sizeof(path), GUI_PATH"%s.lua", name );
   buf = ndata_read( path, &bufsize );
   if (buf == NULL) {
      WARN(_("Unable to find GUI '%s'."), path );
      return -1;
   }

   /* Clean up. */
   if (gui_env != LUA_NOREF) {
      nlua_freeEnv(gui_env);
      gui_env = LUA_NOREF;
   }

   /* Create Lua state. */
   gui_env = nlua_newEnv(1);
   if (nlua_dobufenv( gui_env, buf, bufsize, path ) != 0) {
      WARN(_("Failed to load GUI Lua: %s\n"
            "%s\n"
            "Most likely Lua file has improper syntax, please check"),
            path, lua_tostring(naevL,-1));
      nlua_freeEnv( gui_env );
      gui_env = LUA_NOREF;
      free(buf);
      return -1;
   }
   free(buf);
   nlua_loadStandard( gui_env );
   nlua_loadGFX( gui_env );
   nlua_loadGUI( gui_env );
   nlua_loadTk( gui_env );

   /* Run create function. */
   if (gui_doFunc( "create" )) {
      nlua_freeEnv( gui_env );
      gui_env = LUA_NOREF;
   }

   /* Recreate land window if landed. */
   if (landed) {
      land_genWindows( 0, 1 );
      window_lower( land_wid );
   }

   /* Recreate map window if it's open. */
   if (map_isOpen()) {
      map_close();
      map_open();
   }

   return 0;
}


/**
 * @brief Cleans up the GUI.
 */
void gui_cleanup (void)
{
   /* Disable mouse voodoo. */
   gui_mouseClickEnable( 0 );
   gui_mouseMoveEnable( 0 );

   /* Set the viewport. */
   gui_clearViewport();

   /* Set overlay bounds. */
   gui_setMapOverlayBounds(0, 0, 0, 0);

   /* Reset FPS. */
   fps_setPos( 15., (double)(gl_screen.h-15-gl_defFont.h) );

   /* Destroy offset. */
   gui_xoff = 0.;
   gui_yoff = 0.;

   /* Destroy lua. */
   if (gui_env != LUA_NOREF) {
      nlua_freeEnv( gui_env );
      gui_env = LUA_NOREF;
   }

   /* OMSG */
   omsg_position( SCREEN_W/2., SCREEN_H*2./3., SCREEN_W*2./3. );

   /* Delete the name. */
   free(gui_name);
   gui_name = NULL;

   /* Clear timers. */
   animation_dt = 0.;
}


/**
 * @brief Frees the gui stuff.
 */
void gui_free (void)
{
   gui_cleanup();

   for (int i = 0; i < mesg_max; i++)
      free( mesg_stack[i].str );
   free(mesg_stack);
   mesg_stack = NULL;

   gl_vboDestroy( gui_radar_select_vbo );
   gui_radar_select_vbo = NULL;

   osd_exit();

   gl_freeTexture( gui_ico_hail );
   gui_ico_hail = NULL;

   omsg_cleanup();
}


/**
 * @brief Sets the radar resolution.
 *
 *    @param res Resolution to set to.
 */
void gui_setRadarResolution( double res )
{
   gui_radar.res = CLAMP( RADAR_RES_MIN, RADAR_RES_MAX, res );
}


/**
 * @brief Modifies the radar resolution.
 *
 *    @param mod Number of intervals to jump (up or down).
 */
void gui_setRadarRel( int mod )
{
   gui_radar.res += mod * RADAR_RES_INTERVAL;
   gui_setRadarResolution( gui_radar.res );
   player_message( _("#oRadar set to %d×."), (int)gui_radar.res );
}


/**
 * @brief Gets the GUI offset.
 *
 *    @param x X offset.
 *    @param y Y offset.
 */
void gui_getOffset( double *x, double *y )
{
   *x = gui_xoff;
   *y = gui_yoff;
}


/**
 * @brief Gets the hail icon texture.
 */
glTexture* gui_hailIcon (void)
{
   return gui_ico_hail;
}


/**
 * @brief Translates a mouse position from an SDL_Event to GUI coordinates.
 */
static void gui_eventToScreenPos( int* sx, int* sy, int ex, int ey )
{
   gl_windowToScreenPos( sx, sy, ex - gui_viewport_x, ey - gui_viewport_y );
}


/**
 * @brief Handles a click at a position in the current system
 *
 *    @brief event The click event.
 *    @return Whether the click was used to trigger an action.
 */
int gui_radarClickEvent( SDL_Event* event )
{
   int mxr, myr, in_bounds;
   double x, y, cx, cy;

   if (gui_radar.closed)
      return 0;

   gui_eventToScreenPos( &mxr, &myr, event->button.x, event->button.y );
   if (gui_radar.shape == RADAR_RECT) {
      cx = gui_radar.x + gui_radar.w / 2.;
      cy = gui_radar.y + gui_radar.h / 2.;
      in_bounds = (2*ABS( mxr-cx ) <= gui_radar.w && 2*ABS( myr-cy ) <= gui_radar.h);
   } else {
      cx = gui_radar.x;
      cy = gui_radar.y;
      in_bounds = (pow2( mxr-cx ) + pow2( myr-cy ) <= pow2( gui_radar.w ));
   }
   if (!in_bounds)
      return 0;
   x = (mxr - cx) * gui_radar.res + player.p->solid->pos.x;
   y = (myr - cy) * gui_radar.res + player.p->solid->pos.y;
   return input_clickPos( event, x, y, 1., 10. * gui_radar.res, 15. * gui_radar.res );
}

/**
 * @brief Handles GUI events.
 */
int gui_handleEvent( SDL_Event *evt )
{
   int ret;
   int x, y;

   if (player.p == NULL)
      return 0;
   if ((evt->type == SDL_MOUSEBUTTONDOWN) &&
         (pilot_isFlag(player.p,PILOT_HYP_PREP) ||
         pilot_isFlag(player.p,PILOT_HYP_BEGIN) ||
         pilot_isFlag(player.p,PILOT_HYPERSPACE)))
      return 0;

   ret = 0;
   switch (evt->type) {
      /* Mouse motion. */
      case SDL_MOUSEMOTION:
         if (!gui_L_mmove)
            break;
         gui_prepFunc( "mouse_move" );
         gui_eventToScreenPos( &x, &y, evt->motion.x, evt->motion.y );
         lua_pushnumber( naevL, x );
         lua_pushnumber( naevL, y );
         gui_runFunc( "mouse_move", 2, 0 );
         break;

      /* Mouse click. */
      case SDL_MOUSEBUTTONDOWN:
      case SDL_MOUSEBUTTONUP:
         if (!gui_L_mclick)
            break;
         gui_prepFunc( "mouse_click" );
         lua_pushnumber( naevL, evt->button.button+1 );
         gui_eventToScreenPos( &x, &y, evt->button.x, evt->button.y );
         lua_pushnumber( naevL, x );
         lua_pushnumber( naevL, y );
         lua_pushboolean( naevL, (evt->type==SDL_MOUSEBUTTONDOWN) );
         gui_runFunc( "mouse_click", 4, 1 );
         ret = lua_toboolean( naevL, -1 );
         lua_pop( naevL, 1 );
         break;

      /* Not interested in the rest. */
      default:
         break;
   }
   return ret;
}


/**
 * @brief Enables the mouse click callback.
 */
void gui_mouseClickEnable( int enable )
{
   gui_L_mclick = enable;
}


/**
 * @brief Enables the mouse movement callback.
 */
void gui_mouseMoveEnable( int enable )
{
   gui_L_mmove = enable;
}
