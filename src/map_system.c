/*
 * See Licensing and Copyright notice in naev.h
 */

/** @cond */
#include <float.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "map.h"

#include "array.h"
#include "background.h"
#include "colour.h"
#include "dialogue.h"
#include "economy.h"
#include "faction.h"
#include "gui.h"
#include "land_outfits.h"
#include "log.h"
#include "mapData.h"
#include "map_find.h"
#include "map_system.h"
#include "mission.h"
#include "ndata.h"
#include "nmath.h"
#include "nstring.h"
#include "opengl.h"
#include "player.h"
#include "space.h"
#include "toolkit.h"

#define BUTTON_WIDTH  200 /**< Map button width. */
#define BUTTON_HEIGHT  30 /**< Map button height. */

static StarSystem *cur_sys_sel = NULL; /**< Currently selected system */
static int cur_planet_sel = 0; /**< Current planet selected by user (0 = star). */
static Planet *cur_planetObj_sel = NULL;
static Outfit **cur_planet_sel_outfits = NULL;
static Ship **cur_planet_sel_ships = NULL;
static int pitch = 0; /**< pitch of planet images. */
static int nameWidth = 0; /**< text width of planet name */
static int nshow = 0; /**< number of planets shown. */
static char infobuf[STRMAX];
static unsigned int starCnt = 1;
glTexture **bgImages; /**< array (array.h) of nebula and star textures */

#define MAP_SYSTEM_WDWNAME "wdwSystemMap"
#define MAPSYS_OUTFITS "mapSysOutfits"
#define MAPSYS_SHIPS "mapSysShips"
#define MAPSYS_TRADE "mapSysTrade"

/*
 * extern
 */
/*land.c*/
//extern int landed;
//extern Planet* land_planet;

/*
 * prototypes
 */
static void map_system_window_close( unsigned int wid, char *str );

/* Update. */
static void map_system_updateSelected( unsigned int wid );

/* Render. */
static void map_system_render( double bx, double by, double w, double h, void *data );
/* Mouse. */
static int map_system_mouse( unsigned int wid, SDL_Event* event, double mx, double my,
      double w, double h, double rx, double ry, void *data );
/* Misc. */
static int map_system_keyHandler( unsigned int wid, SDL_Keycode key, SDL_Keymod mod );
static void map_system_show( int wid, int x, int y, int w, int h);

static void map_system_genOutfitsList( unsigned int wid, float goodsSpace, float outfitSpace, float shipSpace );
static void map_system_genShipsList( unsigned int wid, float goodsSpace, float outfitSpace, float shipSpace );
static void map_system_genTradeList( unsigned int wid, float goodsSpace, float outfitSpace, float shipSpace );


static void map_system_array_update( unsigned int wid, char* str );


/**
 * @brief Initializes the system map subsystem.
 *
 *    @return 0 on success.
 */
int map_system_init( void )
{
   return 0;
}

/**
 * @brief Placemarker for when required for loading system map subsystem.
 *
 *    @return 0 on success.
 */
int map_system_load( void )
{
  return 0;
}

/**
 * @brief Destroys the system map subsystem.
 */
void map_system_exit( void )
{
   for (int i=0; i<array_size(bgImages); i++)
      gl_freeTexture(bgImages[i]);

   array_free(bgImages);
   bgImages = NULL;
   array_free(cur_planet_sel_outfits);
   cur_planet_sel_outfits = NULL;
   array_free(cur_planet_sel_ships);
   cur_planet_sel_ships = NULL;
}


/**
 * @brief Closes the system map window.
 */
void map_system_close(void)
{
   unsigned int wid;

   if ((cur_sys_sel != NULL) && (cur_sys_sel != cur_system))
      space_gfxUnload(cur_sys_sel);

   map_system_exit();
   wid = window_get(MAP_SYSTEM_WDWNAME);
   if (wid > 0)
      window_destroy(wid);
}


/**
 * @brief Handles key input to the map window.
 */
static int map_system_keyHandler( unsigned int wid, SDL_Keycode key, SDL_Keymod mod )
{
   (void)mod;
   if (key == SDLK_m) {
      map_system_close();
      return 1;
   }
   if (key == SDLK_UP) {
      cur_planet_sel = MAX( cur_planet_sel-1, 0 );
      map_system_updateSelected( wid );
      return 1;
   }
   if (key == SDLK_DOWN) {
      cur_planet_sel = MIN( cur_planet_sel+1, nshow );
      map_system_updateSelected( wid );
      return 1;
   }
   return 0;
}

/**
 * @brief Opens the map window.
 */
void map_system_open( int sys_selected )
{
   unsigned int wid;
   int w, h;
   StarSystem *tmp_sys;
   /* Destroy window if exists. */
   wid = window_get( MAP_SYSTEM_WDWNAME );
   if ( wid > 0 ) {
      window_destroy( wid );
      return;
   }
   cur_planetObj_sel = NULL;
   memset( infobuf,0,sizeof(infobuf) );
   pitch = 0;
   nameWidth = 0;
   nshow = 0;
   starCnt = 1;

   /* get the selected system. */
   cur_sys_sel = system_getIndex( sys_selected );
   cur_planet_sel = 0;

   /* Set up window size. */
   w = MAP_WIDTH;
   h = MAP_HEIGHT;

   /* create the window. */
   wid = window_create( MAP_SYSTEM_WDWNAME, _("System Info"), -1, -1, w, h );
   window_setCancel( wid, map_system_window_close );
   window_handleKeys( wid, map_system_keyHandler );
   window_addText( wid, 40, h-30, 160, 20, 1, "txtSysname",
         &gl_defFont, NULL, _(cur_sys_sel->name) );
   /* Close button */
   window_addButton(wid, -20, 20,
         BUTTON_WIDTH, BUTTON_HEIGHT,
         "btnClose", _("Close"), map_system_window_close);

   /* Load the planet gfx if necessary */
   if ( cur_sys_sel != cur_system ) {
      space_gfxLoad(cur_sys_sel);
   }
   /* get textures for the stars.  The first will be the nebula */
   /* There seems no other reliable way of getting the correct images -*/
   /* these are determined by a random number generator in lua */
   /* This is a bit nasty - luckily Naev is single threaded! */
   tmp_sys = cur_system;
   cur_system = cur_sys_sel;
   /* load background images */
   background_clear();
   background_load ( cur_system->background );
   bgImages = background_getTextures();
   if ( array_size( bgImages ) <= 1 )
      starCnt = 0;
   background_clear();
   /* and reload the images for the current system */
   cur_system = tmp_sys;
   background_load( cur_system->background );

   map_system_show( wid, 20, 60, w-40, h-100);
   map_system_updateSelected( wid );

}


/**
 * @brief Shows a solar system map at x, y (relative to wid) with size w,h.
 *
 *    @param wid Window to show map on.
 *    @param x X position to put map at.
 *    @param y Y position to put map at.
 *    @param w Width of map to open.
 *    @param h Height of map to open.
 *    @param zoom Default zoom to use.
 */
static void map_system_show( int wid, int x, int y, int w, int h)
{
   window_addCust( wid, x, y, w, h,
         "cstMapSys", 1, map_system_render, map_system_mouse, NULL );
}


/**
 * @brief Renders the custom solar system map widget.
 *
 *    @param bx Base X position to render at.
 *    @param by Base Y position to render at.
 *    @param w Width of the widget.
 *    @param h Height of the widget.
 */
static void map_system_render( double bx, double by, double w, double h, void *data )
{
   (void) data;
   int i,j;
   double iw, ih;
   StarSystem *sys=cur_sys_sel;
   Planet *p;
   static int phase=0;
   glColour ccol;
   char buf[1000];
   int cnt;
   double ast_nb, ast_area;
   factionId_t f;
   int hasPresence = 0;
   double unknownPresence = 0;
   char t;
   int txtHeight;
   int offset;
   int hasService;
   const char *name;

   phase++;
   if ( phase > 150 ) {
      phase = 0;
      starCnt++;
      if ( starCnt >= (unsigned int) array_size( bgImages ) ) {
         if ( array_size( bgImages ) <= 1)
            starCnt = 0;
         else
            starCnt = 1;
      }
   }
   /* background */
   gl_renderRect( bx, by, w, h, &cBlack );

   j = 0;
   offset = h - pitch*nshow;
   for ( i=0; i<array_size(sys->planets); i++ ) {
      p = sys->planets[i];
      if ( planet_isKnown(p) && (p->real == ASSET_REAL) ) {
         j++;
         if ( p->gfx_space == NULL) {
            WARN( _("No gfx for %s...\n"),p->name );
         } else {
            ih = pitch;
            iw = ih;
            if ( p->gfx_space->w > p->gfx_space->h )
               ih = ih * p->gfx_space->h / p->gfx_space->w;
            else if ( p->gfx_space->w < p->gfx_space->h )
               iw = iw * p->gfx_space->w / p->gfx_space->h;
            gl_blitScale( p->gfx_space, bx+2, by+(nshow-j-1)*pitch + (pitch-ih)/2 + offset, iw, ih, &cWhite );
         }
         gl_print(&gl_smallFont, bx + 5 + pitch,
               by + (nshow-j-0.5)*pitch + offset, NULL, "#%c%s%s#0",
               planet_getColourChar(p), planet_getSymbol(p), _(p->name));
      }
   }
   /* draw the star */
   ih = pitch;
   iw = ih;
   if ( array_size( bgImages ) > 0 ) {
      if ( bgImages[starCnt]->w > bgImages[starCnt]->h )
         ih = ih * bgImages[starCnt]->h / bgImages[starCnt]->w;
      else if ( bgImages[starCnt]->w < bgImages[starCnt]->h )
         iw = iw * bgImages[starCnt]->w / bgImages[starCnt]->h;
      ccol.r=ccol.g=ccol.b=ccol.a=1;
      if ( phase > 120 && array_size( bgImages ) > 2 )
         ccol.a = cos ( (phase-121)/30. *M_PI/2.);
      gl_blitScale( bgImages[starCnt], bx+2 , by+(nshow-1)*pitch + (pitch-ih)/2 + offset, iw , ih, &ccol );
      if ( phase > 120 && array_size( bgImages ) > 2) {
         /* fade in the next star */
         ih = pitch;
         iw = ih;
         i = starCnt + 1;
         if ( i >= array_size( bgImages ) ) {
            if ( array_size( bgImages ) <= 1 )
               i=0;
            else
               i=1;
         }
         if ( bgImages[i]->w > bgImages[i]->h )
            ih = ih * bgImages[i]->h / bgImages[i]->w;
         else if ( bgImages[i]->w < bgImages[i]->h )
            iw = iw * bgImages[i]->w / bgImages[i]->h;
         ccol.a = 1 - ccol.a;
         gl_blitScale( bgImages[i], bx+2, by+(nshow-1)*pitch + (pitch-ih)/2 + offset, iw, ih, &ccol );
      }
   }
   gl_printRaw(&gl_smallFont, bx + 5 + pitch, by + (nshow-0.5)*pitch + offset,
         NULL, -1., _(sys->name));
   if ( cur_planet_sel == 0 && array_size( bgImages ) > 0 ) {
      /* make use of space to draw a nice nebula */
      double imgw,imgh;
      iw = w - 50 - pitch - nameWidth;
      ih = h - 110;
      imgw = bgImages[0]->w;
      imgh = bgImages[0]->h;
      if ( (ih * imgw) / imgh > iw ) {
         /* image is wider per height than the space allows - use all width */
         int newih = (int)((iw * imgh) / imgw);
         gl_blitScale( bgImages[0], bx + 10 + pitch + nameWidth, by + (ih-newih)/2, iw, newih, &cWhite );
      } else {
         /* image is higher, so use all height. */
         int newiw = (int)((ih * imgw) / imgh);
         gl_blitScale( bgImages[0], bx + 10 + pitch + nameWidth + (iw-newiw)/2, by, newiw, ih, &cWhite );
      }
   }
   /* draw marker around currently selected planet */
   ccol.r = 0;
   ccol.g = 0.6+0.4*sin( phase/150.*2*M_PI );
   ccol.b = 0;
   ccol.a = 1;
   ih = 15;
   iw = 3;
   gl_renderRect( bx+1, by+(nshow-cur_planet_sel-1)*pitch + offset, iw, ih, &ccol );
   gl_renderRect( bx+1, by+(nshow-cur_planet_sel)*pitch-ih + offset, iw, ih, &ccol );
   gl_renderRect( bx+pitch+3-iw, by+(nshow-cur_planet_sel-1)*pitch + offset, iw, ih, &ccol );
   gl_renderRect( bx+pitch+3-iw, by+(nshow-cur_planet_sel)*pitch-ih + offset, iw, ih, &ccol );
   gl_renderRect( bx+1, by+(nshow-cur_planet_sel-1)*pitch + offset, ih, iw, &ccol );
   gl_renderRect( bx+1, by+(nshow-cur_planet_sel)*pitch-iw + offset, ih, iw, &ccol );
   gl_renderRect( bx+pitch+3-ih, by+(nshow-cur_planet_sel-1)*pitch + offset, ih, iw, &ccol );
   gl_renderRect( bx+pitch+3-ih, by+(nshow-cur_planet_sel)*pitch-iw + offset, ih, iw, &ccol );
   cnt = 0;
   buf[0] = '\0';
   if ( cur_planet_sel == 0 ) {
      int infopos = 0;
      int stars   = MAX( array_size( bgImages )-1, 0 );
      cnt+=scnprintf( &buf[cnt], sizeof(buf)-cnt, _("System: %s\n"), _(sys->name) );
      /* display sun information */
      cnt+=scnprintf( &buf[cnt], sizeof(buf)-cnt, n_("%d-star system\n", "%d-star system\n", stars), stars );

      /* Nebula. */
      if (sys->nebu_density > 0. ) {
         /* Volatility */
         if (sys->nebu_volatility > 0.)
            cnt += scnprintf(&buf[cnt], sizeof(buf)-cnt,
                  _("Nebula: %G GW volatility\n"), sys->nebu_volatility);
         else
            cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("Nebula: Stable\n") );
      }

      /* Interference. */
      if (sys->rdr_range_mod != 1. ) {
         cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt,
               _("Radar Range: %+G%%\n"), sys->rdr_range_mod*100 - 100);
      }
      /* Asteroids. */
      if (array_size(sys->asteroids) > 0 ) {
         ast_nb = ast_area = 0.;
         for ( i=0; i<array_size(sys->asteroids); i++ ) {
            ast_nb += sys->asteroids[i].nb;
            ast_area = MAX( ast_area, sys->asteroids[i].area );
         }
         cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("Asteroid field density: %.2g\n"), ast_nb*ASTEROID_REF_AREA/ast_area );
      }
      /* Faction */
      f = 0;
      for ( i=0; i<array_size(sys->planets); i++ ) {
         if (sys->planets[i]->real == ASSET_REAL && planet_isKnown( sys->planets[i] ) ) {
            if ((f == 0) && (sys->planets[i]->faction > 0)) {
               f = sys->planets[i]->faction;
            }
            else if ((f != sys->planets[i]->faction)
                  && (sys->planets[i]->faction > 0)) {
               cnt += scnprintf(&buf[cnt], sizeof(buf)-cnt,
                     _("Faction: Multiple\n"));
               break;
            }
         }
      }
      if (f == 0) {
         cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("Faction: N/A\n") );
      }  else {
         if (i==array_size(sys->planets)) /* saw them all and all the same */
            cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt,
                  _("Faction: %s\nStanding: %s\n"), faction_longname(f),
                  faction_getStandingText(f) );
      }
      /* Get presence. */
      hasPresence = 0;
      unknownPresence = 0;
      for ( i=0; i<array_size(sys->presence); i++ ) {
         if (sys->presence[i].value <= 0)
            continue;
         hasPresence = 1;
         if ( faction_isKnown( sys->presence[i].faction ) ) {
            t = faction_getColourChar(sys->presence[i].faction);
            cnt += scnprintf(&buf[cnt], sizeof(buf)-cnt, "#%c%s%s:#0 %.0f\n",
                  t, faction_getSymbol(sys->presence[i].faction),
                  faction_shortname(sys->presence[i].faction),
                  sys->presence[i].value);
         } else
            unknownPresence += sys->presence[i].value;
      }
      if (unknownPresence != 0)
         cnt += scnprintf(&buf[cnt], sizeof(buf)-cnt, "#0Unknown: #I%.0f\n",
               unknownPresence);
      if (hasPresence == 0)
         cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("Presence: N/A\n"));
      txtHeight=gl_printHeightRaw(&gl_smallFont,(w - nameWidth-pitch-60)/2,buf);
      gl_printTextRaw( &gl_smallFont, (w - nameWidth - pitch - 60) / 2, txtHeight,
            bx + 10 + pitch + nameWidth, by + h - 10 - txtHeight, 0, &cFontWhite, -1., buf );

      /* Jumps. */
      for (  i=0; i<array_size(sys->jumps); i++ ) {
         if ( jp_isUsable ( &sys->jumps[i] ) ) {
            if ( infopos == 0) /* First jump */
               infopos = scnprintf( infobuf, sizeof(infobuf), _("   Jump points to:\n") );
            if ( sys_isKnown( sys->jumps[i].target ) ) {
               infopos+=scnprintf( &infobuf[infopos], sizeof(infobuf)-infopos, "     %s\n", _(sys->jumps[i].target->name) );
            } else {
               infopos+=scnprintf( &infobuf[infopos], sizeof(infobuf)-infopos, _("     Unknown system\n") );
            }
         }
      }
   } else {
   /* display planet info */
   p = cur_planetObj_sel;

   cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt,
      _("#%c%s%s#0\nPlanetary class: %s\n"), planet_getColourChar(p),
      planet_getSymbol(p), _(p->name), p->class );

   if (p->faction > 0)
      cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("Faction: %s\n"),
            faction_shortname(p->faction) );
   else
      cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("Faction: None\n") );

   hasService = 0;
   cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("\nServices:\n") );

   for (i=1; i<PLANET_SERVICES_MAX; i<<=1) {
      if (planet_hasService(p, i)) {
         hasService = 1;
         name = planet_getServiceName(i);
         cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, "%s\n", _(name) );
      }
   }

   if (!hasService)
      cnt += scnprintf( &buf[cnt], sizeof(buf)-cnt, _("None\n") );

   txtHeight = gl_printHeightRaw( &gl_smallFont, (w - nameWidth-pitch-60)/2, buf );
   gl_printTextRaw( &gl_smallFont, (w - nameWidth - pitch - 60) / 2, txtHeight,
      bx + 10 + pitch + nameWidth, by + h - 10 - txtHeight, 0, &cFontWhite, -1., buf );
   }

   /* show the trade/outfit/ship info */
   if (infobuf[0] != '\0') {
      txtHeight = gl_printHeightRaw(&gl_smallFont, (w-nameWidth-pitch-60) / 2,
            infobuf);
      gl_printTextRaw(&gl_smallFont, (w-nameWidth-pitch-60) / 2, txtHeight,
            bx + 10 + pitch + nameWidth, by + 10, 0, NULL, -1., infobuf);
   }
}

/**
 * @brief Map custom widget mouse handling.
 *
 *    @param wid Window sending events.
 *    @param event Event window is sending.
 *    @param mx Mouse X position.
 *    @param my Mouse Y position.
 *    @param w Width of the widget.
 *    @param h Height of the widget.
 */
static int map_system_mouse( unsigned int wid, SDL_Event* event, double mx, double my,
      double w, double h, double rx, double ry, void *data )
{
   (void) data;
   (void) rx;
   (void) ry;
   switch (event->type) {
   case SDL_MOUSEBUTTONDOWN:
     /* Must be in bounds. */
     if ((mx < 0.) || (mx > w) || (my < 0.) || (my > h))
            return 0;
     if (mx < pitch && my > 0) {
        if ( cur_planet_sel != (h-my) / pitch ) {
           cur_planet_sel = ( h-my) / pitch;
           map_system_updateSelected( wid );
        }
       return 1;
     }
   }
   return 0;
}


static void map_system_array_update( unsigned int wid, char* str ) {
   int i, l;
   Outfit *outfit;
   Ship *ship;
   char buf_price[ECON_CRED_STRLEN], buf_license[STRMAX_SHORT];
   Commodity *com;
   credits_t mean;
   double std;
   credits_t globalmean;
   double globalstd;
   char buf_local_price[ECON_CRED_STRLEN];
   char buf_mean[ECON_CRED_STRLEN], buf_globalmean[ECON_CRED_STRLEN];
   char buf_std[ECON_CRED_STRLEN], buf_globalstd[ECON_CRED_STRLEN];
   char buf_buy_price[ECON_CRED_STRLEN];
   int owned;

   i = toolkit_getImageArrayPos( wid, str );
   if ( i < 0 ) {
      infobuf[0]='\0';
      return;
   }
   if ( ( strcmp( str, MAPSYS_OUTFITS ) == 0 ) ) {
      outfit = cur_planet_sel_outfits[i];

      /* new text */
      price2str( buf_price, outfit->price, player.p->credits, 2 );
      if (outfit->license == NULL)
         strncpy( buf_license, _("None"), sizeof(buf_license)-1 );
      else if (player_hasLicense( outfit->license ) ||
            (cur_planetObj_sel != NULL && planet_hasService( cur_planetObj_sel, PLANET_SERVICE_BLACKMARKET )))
         strncpy( buf_license, _(outfit->license), sizeof(buf_license)-1 );
      else
         snprintf( buf_license, sizeof( buf_license ), "#r%s#0", _(outfit->license) );

      snprintf(infobuf, sizeof(infobuf),
                 _("%s\n\n"
                   "#nOwned:#0 %d\n"
                   "#nPrice:#0 %s\n"
                   "#nLicense:#0 %s"),
                 _(outfit->name),
                 player_outfitOwned(outfit),
                 buf_price,
                 buf_license);

   } else if ( ( strcmp( str, MAPSYS_SHIPS ) == 0 ) ) {
      ship = cur_planet_sel_ships[i];

      /* update text */
      price2str( buf_price, ship_buyPrice( ship ), player.p->credits, 2 );
      if (ship->license == NULL)
         strncpy( buf_license, _("None"), sizeof(buf_license)-1 );
      else if (player_hasLicense(ship->license)
            || ((cur_planetObj_sel != NULL)
               && planet_hasService(cur_planetObj_sel,
                  PLANET_SERVICE_BLACKMARKET)))
         strncpy( buf_license, _(ship->license), sizeof(buf_license)-1 );
      else
         snprintf(buf_license, sizeof(buf_license), "#r%s#0", _(ship->license));

      l = scnprintf(infobuf, sizeof(infobuf),
            _("%s (%s)\n\n"
               "#nFabricator:#0 %s\n"
               "#nPrice:#0 %s\n"
               "#nLicense:#0 %s"),
            _(ship->name), _(ship->class),
            _(ship->fabricator),
            buf_price,
            buf_license);

      if (ship->cpu != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nCPU:#0 %.0f TFLOPS"), ship->cpu);

      l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
            _("\n#nMass:#0 %.0f kt"), ship->mass);

      if (ship->thrust != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nAcceleration:#0 %G mAU/s²"), ship->thrust);

      if (ship->speed != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nSpeed:#0 %G mAU/s"), ship->speed);

      if (ship->turn != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nTurn:#0 %.0f deg/s"), ship->turn*180./M_PI);

      l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
            _("\n#nTime Constant:#0 %.0f%%"), ship->dt_default*100.);

      if (ship->dmg_absorb != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nAbsorption:#0 %.0f%%"), ship->dmg_absorb*100.);

      if ((ship->shield != 0.) || (ship->shield_regen != 0.))
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nShield:#0 %G GJ (%G GW)"),
               ship->shield, ship->shield_regen);

      if ((ship->armour != 0.) || (ship->armour_regen != 0.))
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nArmor:#0 %G GJ (%G GW)"),
               ship->armour, ship->armour_regen);

      if ((ship->energy != 0.) || (ship->energy_regen != 0.))
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nEnergy:#0 %G GJ (%G GW)"),
               ship->energy, ship->energy_regen);

      if (ship->cap_cargo != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nCargo Space:#0 %.0f kt"), ship->cap_cargo);

      if (ship->fuel != 0.)
         l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
               _("\n#nFuel:#0 %.0f kL"), ship->fuel);

      l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
            _("\n#nFuel Use:#0 %.0f kL"), ship->fuel_consumption);

      l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
            _("\n#nRadar Range:#0 %.0f mAU"), ship->rdr_range);

      l += scnprintf(&infobuf[l], sizeof(infobuf) - l,
            _("\n#nJump Detect Range:#0 %.0f mAU"), ship->rdr_jump_range);
   } else if ( ( strcmp( str, MAPSYS_TRADE ) == 0 ) ) {
      com = cur_planetObj_sel->commodities[i];
      credits2str(buf_local_price,
            planet_commodityPrice(cur_planetObj_sel, com), -1);
      economy_getAveragePrice(com, &globalmean, &globalstd);
      economy_getAveragePlanetPrice(com, cur_planetObj_sel, &mean, &std);
      credits2str(buf_mean, mean, -1);
      snprintf(buf_std, sizeof(buf_std), _("%.1f ¢/kt"), std);
      credits2str(buf_globalmean, globalmean, -1);
      snprintf(buf_globalstd, sizeof(buf_globalstd), _("%.1f ¢/kt"), globalstd);
      owned=pilot_cargoOwned( player.p, com );

      infobuf[0] = '\0';
      i = scnprintf(infobuf, sizeof(infobuf)-i, "%s\n\n", _(com->name));

      i += scnprintf(&infobuf[i], sizeof(infobuf)-i,
            n_("#nYou have:#0 %d kt\n", "#nYou have:#0 %d kt\n", owned),
            owned);

      if (owned > 0) {
         credits2str(buf_buy_price, com->lastPurchasePrice, -1);
         i += scnprintf(&infobuf[i], sizeof(infobuf)-i,
               _("#nPurchased for:#0 %s/kt\n"),
               buf_buy_price);
      }

      i += scnprintf(&infobuf[i], sizeof(infobuf)-i,
            _("#nCurrent price here:#0 %s/kt\n"
               "#nAverage price seen here:#0 %s/kt ± %s\n"
               "#nAverage price seen everywhere:#0 %s/kt ± %s\n"),
            buf_local_price, buf_mean, buf_std, buf_globalmean, buf_globalstd);
   }
   else
      WARN( _("Unexpected call to map_system_array_update\n") );
}


static void map_system_updateSelected( unsigned int wid )
{
   int i;
   StarSystem *sys = cur_sys_sel;
   Planet *last = NULL;
   int planetObjChanged = 0;
   int w, h;
   Planet *p;
   int textw;
   int noutfits,nships,ngoods;
   Outfit **outfits;
   Ship **ships;
   float g,o,s;
   nameWidth = 0; /* get the widest planet/star name */
   nshow = 1; /* start at 1 for the sun */
   for ( i=0; i<array_size(sys->planets); i++) {
      p = sys->planets[i];
      if ( planet_isKnown( p ) && (p->real == ASSET_REAL) ) {
         textw = gl_printWidth(&gl_smallFont, "#%c%s%s#0",
               planet_getColourChar(p), planet_getSymbol(p), _(p->name));
         if ( textw > nameWidth )
            nameWidth = textw;
         last = p;
         if ( cur_planet_sel == nshow ) {
            if ( cur_planetObj_sel != p )
               planetObjChanged = 1;
            cur_planetObj_sel = p;
         }
         nshow++;
      }
   }
   /* get width of star name text */
   textw = gl_printWidthRaw( &gl_smallFont, _(sys->name) );
   if ( textw > nameWidth )
      nameWidth = textw;

   window_dimWindow( wid, &w, &h );

   pitch = (h-100) / nshow;
   if ( pitch > w/5 )
      pitch = w/5;

   if ( cur_planet_sel >= nshow ) {
      cur_planet_sel = nshow-1;
      if ( cur_planetObj_sel != last ) {
         cur_planetObj_sel = last;
         planetObjChanged = 1;
      }
   }
   if ( cur_planet_sel <= 0 ) {
      /* star selected */
      cur_planet_sel = 0;
      if ( cur_planetObj_sel != NULL ) {
         cur_planetObj_sel = NULL;
         planetObjChanged = 1;
      }
   }

   if ( planetObjChanged ) {
      infobuf[0]='\0';
      if ( cur_planetObj_sel == NULL ) {
         /*The star*/
         noutfits = 0;
         nships = 0;
         ngoods = 0;
      } else {
         /* get number of each to decide how much space the lists can have */
         outfits = tech_getOutfit( cur_planetObj_sel->tech );
         noutfits = array_size( outfits );
         array_free( outfits );
         ships = tech_getShip( cur_planetObj_sel->tech );
         nships = array_size( ships );
         array_free( ships );
         ngoods = array_size( cur_planetObj_sel->commodities );
      }
      /* determine the ratio of space */
      s=g=o=0;
      if ( ngoods != 0 )
         g=0.35;

      if ( noutfits != 0 ) {
         if ( nships != 0 ) {
            s=0.25;
            o=1-g-s;
         } else
            o=1-g;
      } else if ( nships!=0 )
         s=1-g;
      /* ensure total is ~1 */
      g += 1 - g - o - s;
      map_system_genOutfitsList( wid, g, o, s );
      map_system_genShipsList( wid, g, o, s );
      map_system_genTradeList( wid, g, o, s );
   }
}


/**
 * @brief Generates the outfit list.
 *
 *    @param wid Window to generate the list on.
 */
static void map_system_genOutfitsList( unsigned int wid, float goodsSpace, float outfitSpace, float shipSpace )
{
   int i;
   ImageArrayCell *coutfits;
   int noutfits;
   int w, h;
   int xpos, xw, ypos, yh;
   int iconsize;
   static Planet *planetDone = NULL;

   window_dimWindow( wid, &w, &h );
   if (planetDone == cur_planetObj_sel) {
      if ( widget_exists( wid, MAPSYS_OUTFITS ) ) {
         return;
      }
   } else {
      if ( widget_exists( wid, MAPSYS_OUTFITS ) ) {
         window_destroyWidget( wid, MAPSYS_OUTFITS );
         array_free( cur_planet_sel_outfits );
         cur_planet_sel_outfits = NULL;
      }
      assert(cur_planet_sel_outfits == NULL);
   }
   planetDone = cur_planetObj_sel;

   /* set up the outfits to buy/sell */
   if ( cur_planetObj_sel == NULL )
      return;

   cur_planet_sel_outfits = tech_getOutfit( cur_planetObj_sel->tech );
   noutfits = array_size( cur_planet_sel_outfits );

   if (noutfits > 0) {
      coutfits = outfits_imageArrayCells( (const Outfit**)cur_planet_sel_outfits, &noutfits );

      xw = ( w - nameWidth - pitch - 60 ) / 2;
      xpos = 35 + pitch + nameWidth + xw;
      i = (goodsSpace!=0) + (outfitSpace!=0) + (shipSpace!=0);
      yh = (h - 100 - (i+1)*5 ) * outfitSpace;
      ypos = 65 + 5*(shipSpace!=0) + (h - 100 - (i+1)*5)*shipSpace;

      iconsize = 64;
      if (toolkit_simImageArrayVisibleElements( xw, yh, iconsize, iconsize ) < noutfits)
         iconsize = 48;
      window_addImageArray( wid, xpos, ypos,
                            xw, yh, MAPSYS_OUTFITS, iconsize, iconsize,
                            coutfits, noutfits, map_system_array_update, NULL, NULL );
      toolkit_unsetSelection( wid, MAPSYS_OUTFITS );
   }
}


static void map_system_genShipsList( unsigned int wid, float goodsSpace, float outfitSpace, float shipSpace )
{
   ImageArrayCell *cships;
   int nships;
   int xpos, ypos, xw, yh;
   static Planet *planetDone=NULL;
   int i, w, h, iconsize;
   window_dimWindow( wid, &w, &h );

   /* set up the ships that can be bought here */
   if ( planetDone == cur_planetObj_sel ) {
      if ( widget_exists( wid, MAPSYS_SHIPS ) ) {
         return;
      }
   } else {
      if ( widget_exists( wid, MAPSYS_SHIPS ) ) {
         window_destroyWidget( wid, MAPSYS_SHIPS );
         array_free( cur_planet_sel_ships );
         cur_planet_sel_ships = NULL;
      }
      assert(cur_planet_sel_ships == NULL);
   }
   planetDone = cur_planetObj_sel;

   /* set up the outfits to buy/sell */
   if ( cur_planetObj_sel == NULL )
      return;

   cur_planet_sel_ships = tech_getShip( cur_planetObj_sel->tech );
   nships = array_size( cur_planet_sel_ships );

   if (nships > 0) {
      cships = calloc( nships, sizeof(ImageArrayCell) );
      for ( i=0; i<nships; i++ ) {
         cships[i].image = gl_dupTexture(cur_planet_sel_ships[i]->gfx_store);
         cships[i].caption = strdup(_(cur_planet_sel_ships[i]->name));
         cships[i].alt = strdup(cur_planet_sel_ships[i]->desc_stats);
      }
      xw = (w - nameWidth - pitch - 60)/2;
      xpos = 35 + pitch + nameWidth + xw;
      i = (goodsSpace!=0) + (outfitSpace!=0) + (shipSpace!=0);
      yh = (h - 100 - (i+1)*5 ) * shipSpace;
      ypos = 65;

      iconsize = 48;
      if (toolkit_simImageArrayVisibleElements( xw, yh, iconsize, iconsize ) < nships )
         iconsize = 48;
      window_addImageArray( wid, xpos, ypos,
         xw, yh, MAPSYS_SHIPS, iconsize, iconsize,
         cships, nships, map_system_array_update, NULL, NULL );
      toolkit_unsetSelection( wid, MAPSYS_SHIPS );
   }
}


static void map_system_genTradeList( unsigned int wid, float goodsSpace, float outfitSpace, float shipSpace )
{
   static Planet *planetDone=NULL;
   int i, ngoods;
   ImageArrayCell *cgoods;
   int xpos, ypos, xw, yh, w, h, iconsize;
   window_dimWindow( wid, &w, &h );

   /* set up the commodities that can be bought here */
   if ( planetDone == cur_planetObj_sel ) {
      if ( widget_exists( wid, MAPSYS_TRADE ) ) {
         return;
      }
   } else {
      if ( widget_exists( wid, MAPSYS_TRADE ) ) {
         window_destroyWidget( wid, MAPSYS_TRADE );
      }
   }
   planetDone = cur_planetObj_sel;
   /* goods list */
   if ( cur_planetObj_sel == NULL ) {
      ngoods = 0;
   } else {
      ngoods = array_size( cur_planetObj_sel->commodities );
   }
   if ( ngoods > 0 ) {
      cgoods = calloc( ngoods, sizeof(ImageArrayCell) );
      for ( i=0; i<ngoods; i++ ) {
         cgoods[i].image = gl_dupTexture( cur_planetObj_sel->commodities[i]->gfx_store );
         cgoods[i].caption = strdup( _(cur_planetObj_sel->commodities[i]->name) );
      }
      /* set up the goods to buy/sell */
      xw = (w - nameWidth - pitch - 60)/2;
      xpos = 35 + pitch + nameWidth + xw;
      i = (goodsSpace!=0) + (outfitSpace!=0) + (shipSpace!=0);
      yh = (h - 100 - (i+1)*5 ) * goodsSpace;
      ypos = 60 + 5*i + (h-100 - (i+1)*5 )*(outfitSpace + shipSpace);

      iconsize = 48;
      if (toolkit_simImageArrayVisibleElements( xw, yh, iconsize, iconsize ) < ngoods )
         iconsize = 48;
      window_addImageArray( wid, xpos, ypos,
         xw, yh, MAPSYS_TRADE, iconsize, iconsize,
         cgoods, ngoods, map_system_array_update, NULL, NULL );
      toolkit_unsetSelection( wid, MAPSYS_TRADE );
   }
}


/**
 * @brief Wrapper for map_system_close()
 */
static void map_system_window_close( unsigned int wid, char *str ) {
   (void) wid;
   (void) str;

   map_system_close();
}
