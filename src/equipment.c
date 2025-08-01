/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file equipment.c
 *
 * @brief Handles equipping ships.
 */


/** @cond */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "equipment.h"

#include "array.h"
#include "conf.h"
#include "credits.h"
#include "debug.h"
#include "dialogue.h"
#include "gui.h"
#include "hook.h"
#include "info.h"
#include "land.h"
#include "land_outfits.h"
#include "log.h"
#include "map.h"
#include "mission.h"
#include "ndata.h"
#include "nstring.h"
#include "ntime.h"
#include "player.h"
#include "pilot_outfit.h"
#include "shipstats.h"
#include "slots.h"
#include "tk/toolkit_priv.h" /* Yes, I'm a bad person, abstractions be damned! */
#include "toolkit.h"


/*
 * Image array names.
 */
#define  EQUIPMENT_SHIPS      "iarAvailShips"
#define  EQUIPMENT_OUTFIT_TAB "tabOutfits"
#define  EQUIPMENT_OUTFITS    "iarAvailOutfits"
#define  EQUIPMENT_FILTER     "inpFilterOutfits"
#define  OUTFIT_TABS          5


/* global/main window */
#define BUTTON_WIDTH    180 /**< Default button width. */
#define BUTTON_HEIGHT   40 /**< Default button height. */


/*
 * equipment stuff
 */
static CstSlotWidget eq_wgt; /**< Equipment widget. */
static double equipment_dir = 0.; /**< Equipment dir. */
static Uint32 equipment_lastick = 0; /**< Last tick. */
static unsigned int equipment_wid = 0; /**< Global wid. */
static iar_data_t *iar_data = NULL; /**< Stored image array positions. */
static Outfit ***iar_outfits = NULL; /**< Outfits associated with the image array cells. */

/*
 * prototypes
 */
/* Creation. */
static void equipment_getDim( unsigned int wid, int *w, int *h,
      int *sw, int *sh, int *ow, int *oh,
      int *ew, int *eh,
      int *cw, int *ch, int *bw, int *bh );
static void equipment_genShipList( unsigned int wid );
static void equipment_genOutfitList( unsigned int wid );
/* Widget. */
static void equipment_genLists( unsigned int wid );
static void equipment_renderColumn( double x, double y, double w, double h,
      PilotOutfitSlot *lst, const char *txt,
      int selected, Outfit *o, Pilot *p, CstSlotWidget *wgt );
static void equipment_renderSlots( double bx, double by, double bw, double bh, void *data );
static void equipment_renderMisc( double bx, double by, double bw, double bh, void *data );
static void equipment_renderOverlayColumn( double x, double y, double h,
      PilotOutfitSlot *lst, int mover, CstSlotWidget *wgt );
static void equipment_renderOverlaySlots( double bx, double by, double bw, double bh,
      void *data );
static void equipment_renderShip( double bx, double by,
      double bw, double bh, double x, double y, Pilot *p );
static int equipment_mouseInColumn( double y, double h, int n, double my );
static int equipment_mouseSlots( unsigned int wid, SDL_Event* event,
      double x, double y, double w, double h, double rx, double ry, void *data );
/* Misc. */
static int equipment_swapSlot( unsigned int wid, Pilot *p, PilotOutfitSlot *slot );
static void equipment_sellShip( unsigned int wid, char* str );
static void equipment_renameShip( unsigned int wid, char *str );
static void equipment_transChangeShip( unsigned int wid, char* str );
static void equipment_changeShip( unsigned int wid );
static void equipment_unequipShip( unsigned int wid, char* str );
static void equipment_sellOutfit( unsigned int wid, char* str );
static void equipment_filterOutfits( unsigned int wid, char *str );
static void equipment_rightClickOutfits( unsigned int wid, char* str );
static void equipment_changeTab( unsigned int wid, char *wgt, int old, int tab );
static int equipment_playerAddOutfit( const Outfit *o, int quantity );
static int equipment_playerRmOutfit( const Outfit *o, int quantity );


/**
 * @brief Handles right-click on unequipped outfit.
 *    @param wid Window to update.
 *    @param str Widget name. Must be EQUIPMENT_OUTFITS.
 */
void equipment_rightClickOutfits( unsigned int wid, char* str )
{
   (void)str;
   Outfit* o;
   int i, active, minimal, n, nfits;
   PilotOutfitSlot* slots;
   Pilot *p;
   OutfitSlotSize size;

   active = window_tabWinGetActive( wid, EQUIPMENT_OUTFIT_TAB );
   i = toolkit_getImageArrayPos( wid, EQUIPMENT_OUTFITS );

   /* Did the user click on background or placeholder cell? */
   if (i < 0 || iar_outfits[active] == NULL)
      return;

   o = iar_outfits[active][i];
   if (o==NULL)
      return;

   /* Figure out which slot this stuff fits into */
   switch (o->slot.type) {
      case OUTFIT_SLOT_STRUCTURE:
         slots    = eq_wgt.selected->outfit_structure;
         break;
      case OUTFIT_SLOT_UTILITY:
         slots    = eq_wgt.selected->outfit_utility;
         break;
      case OUTFIT_SLOT_WEAPON:
         slots    = eq_wgt.selected->outfit_weapon;
         break;
      default:
         return;
   }
   n = array_size(slots);

   /* See how many slots it fits into. */
   nfits = 0;
   minimal = n;
   for (i=0; i<n; i++) {
      /* Must fit the slot. */
      if (!outfit_fitsSlot( o, &slots[i].sslot->slot))
         continue;

      /* Must have valid slot size. */
      if (o->slot.size == OUTFIT_SLOT_SIZE_NA)
         continue;

      minimal = i;
      nfits++;
   }
   /* Only fits in a single slot, so we might as well just swap it. */
   if (nfits==1) {
      eq_wgt.outfit = NULL;
      p = eq_wgt.selected;

      if (slots[minimal].outfit != NULL)
         /* First unequip the existing outfit. */
         equipment_swapSlot(equipment_wid, p, &slots[minimal]);

      /* Have to set this here (after removing the outfit) since the
       * image array can get offset by the returned outfit. Otherwise
       * we'll swap in the wrong outfit. */
      eq_wgt.outfit = o;

      /* Equip the new outfit. */
      equipment_swapSlot(equipment_wid, p, &slots[minimal]);

      return;
   }

   /* See if limit is applied and swap with shared limit slot. */
   if (o->limit != NULL) {
      minimal = n;
      for (i=0; i<n; i++) {
         /* Must fit the slot. */
         if (!outfit_fitsSlot( o, &slots[i].sslot->slot))
            continue;

         /* Must have valid slot size. */
         if (o->slot.size == OUTFIT_SLOT_SIZE_NA)
            continue;

         /* Must have outfit with limit. */
         if ((slots[i].outfit == NULL) || (slots[i].outfit->limit == NULL))
            continue;

         /* Must share a limit to be able to swap. */
         if (strcmp(slots[i].outfit->limit,o->limit)!=0)
            continue;

         minimal = i;
      }
      if (minimal < n) {
         eq_wgt.outfit = NULL;
         p = eq_wgt.selected;

         /* First unequip the existing outfit. */
         equipment_swapSlot(equipment_wid, p, &slots[minimal]);

         /* Have to set this here (after removing the outfit) since the
          * image array can get offset by the returned outfit. Otherwise
          * we'll swap in the wrong outfit. */
         eq_wgt.outfit = o;

         /* Equip the new outfit. */
         equipment_swapSlot(equipment_wid, p, &slots[minimal]);

         return;
      }
   }

   /* Loop through outfit slots of the right type, try to find an empty one */
   size = OUTFIT_SLOT_SIZE_NA;
   minimal = n;
   for (i=0; i<n; i++) {
      /* Slot full. */
      if (slots[i].outfit != NULL)
         continue;

      /* Must fit the slot. */
      if (!outfit_fitsSlot( o, &slots[i].sslot->slot))
         continue;

      /* Must have valid slot size. */
      if (o->slot.size == OUTFIT_SLOT_SIZE_NA)
         continue;

      /* Search for the smallest slot avaliable. */
      if ((size == OUTFIT_SLOT_SIZE_NA) || (slots[i].sslot->slot.size < size)){
         size = slots[i].sslot->slot.size;
         minimal = i;
      }
   }

   /* Use the chosen one (if any). */
   if (minimal < n) {
      eq_wgt.outfit  = o;
      p              = eq_wgt.selected;
      equipment_swapSlot( equipment_wid, p, &slots[minimal] );
   }
}

/**
 * @brief Gets the window dimensions.
 */
static void equipment_getDim( unsigned int wid, int *w, int *h,
      int *sw, int *sh, int *ow, int *oh,
      int *ew, int *eh,
      int *cw, int *ch, int *bw, int *bh )
{
   int ssw, ssh;
   /* Get window dimensions. */
   window_dimWindow( wid, w, h );

   /* Calculate image array dimensions. */
   ssw = 440 + (*w - LAND_WIDTH);
   ssh = (*h - 100);
   if (sw != NULL)
      *sw = ssw;
   if (sh != NULL)
      *sh = (1*ssh)/3;
   if (ow != NULL)
      *ow = ssw;
   if (oh != NULL)
      *oh = (2*ssh)/3;

   /* Calculate slot widget. */
   if (ew != NULL)
      *ew = 180.;
   if (eh != NULL)
      *eh = *h - 100;

   /* Calculate custom widget. */
   if (cw != NULL)
      *cw = 142;
   if (ch != NULL)
      *ch = 250;

   /* Calculate button dimensions. */
   if (bw != NULL)
      *bw = (*w - 10 - ssw - (4*10) - 10) / 4;
   if (bh != NULL)
      *bh = BUTTON_HEIGHT;
}

/**
 * @brief Opens the player's equipment window.
 */
void equipment_open( unsigned int wid )
{
   int w, h;
   int sw, sh;
   int ow, oh;
   int bw, bh;
   int ew, eh;
   int cw, ch;
   int x, y;

   /* Mark as generated. */
   land_tabGenerate(LAND_WINDOW_EQUIPMENT);

   /* Set global WID. */
   equipment_wid = wid;

   /* Get dimensions. */
   equipment_getDim( wid, &w, &h, &sw, &sh, &ow, &oh,
         &ew, &eh, &cw, &ch, &bw, &bh );

   /* Prepare the outfit array. */
   if (iar_data == NULL)
      iar_data = calloc( OUTFIT_TABS, sizeof(iar_data_t) );
   else
      memset( iar_data, 0, sizeof(iar_data_t) * OUTFIT_TABS );
   if (iar_outfits == NULL)
      iar_outfits = calloc( OUTFIT_TABS, sizeof(Outfit**) );
   else {
      for (int i=0; i<OUTFIT_TABS; i++)
         free( iar_outfits[i] );
      memset( iar_outfits, 0, sizeof(Outfit**) * OUTFIT_TABS );
   }

   /* Safe defaults. */
   equipment_lastick = SDL_GetTicks();
   equipment_dir = 0.;
   eq_wgt.selected = NULL;

   /* Add ammo. */
   equipment_addAmmo();

   /* buttons */
   window_addButtonKey(wid, -10, 20, bw, bh, "btnCloseEquipment",
         _("&Take Off"), land_buttonTakeoff, SDLK_t);

   window_addButtonKey(wid, 10+sw+10 + (10+bw)*2, 20,
         bw, bh, "btnSellShip",
         _("&Sell Ship"), equipment_sellShip, SDLK_s);
   window_addButtonKey(wid, 10+sw+10 + (10+bw), 20,
         bw, bh, "btnChangeShip",
         _("Swa&p Ship"), equipment_transChangeShip, SDLK_p);
   window_addButtonKey(wid, 10 + sw + 10, 20, bw, bh, "btnSellOutfit",
         _("Sell &Outfit"), equipment_sellOutfit, SDLK_o);

   window_addButtonKey(wid, -10, -40-ch-10 - (10+bh),
         cw, bh, "btnUnequipShip",
         _("&Unequip"), equipment_unequipShip, SDLK_u);
   window_addButtonKey(wid, -10, -40-ch-10,
         cw, bh, "btnRenameShip",
         _("&Rename"), equipment_renameShip, SDLK_r);

   x = 10 + sw + 10 + ew + 10;
   y = -40;
   window_addText(wid, x, y, w-x-10-cw-10, h+y-20-bh, 0, "txtDDesc",
         &gl_defFont, NULL, NULL);

   /* Generate lists. */
   window_addText( wid, 30, -20,
         ow, gl_defFont.h, 0, "txtShipTitle", &gl_defFont, NULL, _("Available Ships") );
   window_addText( wid, 30, -40-sh-20,
         ow, gl_defFont.h, 0, "txtOutfitTitle", &gl_defFont, NULL, _("Available Outfits") );
   equipment_genLists( wid );

   /* Slot widget. */
   equipment_slotWidget( wid, 10 + sw + 10, -40, ew, eh, &eq_wgt );
   eq_wgt.canmodify = 1;

   /* Custom widget (ship information). */
   window_addCust( wid, -10, -40, cw, ch, "cstMisc", 0,
         equipment_renderMisc, NULL, NULL );

   /* Focus the ships image array. */
   window_setFocus( wid , EQUIPMENT_SHIPS );
}


/**
 * @brief Creates the slot widget and initializes it.
 *
 *    @param wid Parent window id.
 *    @param x X position to put it at.
 *    @param y Y position to put it at.
 *    @param w Width.
 *    @param h Height;
 *    @param data Dataset to use.
 */
void equipment_slotWidget( unsigned int wid,
      double x, double y, double w, double h,
      CstSlotWidget *data )
{
   /* Initialize data. */
   memset( data, 0, sizeof(CstSlotWidget) );
   data->slot        = -1;
   data->mouseover   = -1;
   data->weapons     = -1;

   /* Create the widget. */
   window_addCust( wid, x, y, w, h, "cstEquipment", 0,
         equipment_renderSlots, equipment_mouseSlots, data );
   window_custSetClipping( wid, "cstEquipment", 0 );
   window_custSetOverlay( wid, "cstEquipment", equipment_renderOverlaySlots );
}
/**
 * @brief Renders an outfit column.
 */
static void equipment_renderColumn( double x, double y, double w, double h,
      PilotOutfitSlot *lst, const char *txt,
      int selected, Outfit *o, Pilot *p, CstSlotWidget *wgt )
{
   int i, level;
   const glColour *c;
   const glColour ic = { .r = 0.5, .g = 0.5, .b = 0.5, .a = 0.5 };
   glColour rc;
   const glColour *lc;
   int irrelevant;

   /* Render text. */
   if ((o != NULL) && (lst[0].sslot->slot.type == o->slot.type))
      c = &cFontBlue;
   else
      c = &cFontWhite;
   gl_printMidRaw( &gl_smallFont, 60.,
         x-10., y+h+10., c, -1., txt );

   /* Iterate for all the slots. */
   for (i=0; i<array_size(lst); i++) {
      irrelevant = 0;

      /* Choose default colour. */
      if (wgt->weapons >= 0) {
         level = pilot_weapSetCheck(p, wgt->weapons, &lst[i]);
         if (level == 0)
            c = &cSlotPrimary;
         else if (level == 1)
            c = &cSlotSecondary;
         else if (pilot_slotIsActive(&lst[i]))
            c = &cSlotRelevant;
         else {
            c = &cSlotIrrelevant;
            irrelevant = 1;
         }
      }
      else
         c = outfit_slotSizeColour(&lst[i].sslot->slot);

      /* Fallback in case slot size color is undefined. */
      if (c == NULL)
         c = &cBlack;

      /* Draw background. */
      toolkit_drawRect( x, y, w, h, c, NULL );

      if (lst[i].outfit != NULL) {
         /* Draw bugger. */
         gl_blitScale( lst[i].outfit->gfx_store,
               x, y, w, h, (irrelevant ? &ic : NULL) );
      }
      else if ((o != NULL) &&
            (lst[i].sslot->slot.type == o->slot.type)) {
         /* Render a thick frame with a yes/no color, and geometric cue. */
         int ok = (pilot_canEquip( p, &lst[i], o ) == NULL);
         glUseProgram( shaders.status.program );
         glUniform1f( shaders.status.paramf, ok );
         gl_renderShader( x, y, w, h, 0., &shaders.status, NULL, 0 );
      }

      /* Must rechoose colour based on slot properties. */
      rc = cBlack;
      rc.a = 0.1;
      lc = NULL;
      if (wgt->canmodify) {
         if (lst[i].sslot->required)
            rc = cSlotRequired;
         else if (lst[i].sslot->slot.exclusive) {
            rc = cSlotExclusive;
            lc = &cSlotExclusiveLight;
         }
         else if (lst[i].sslot->slot.spid != 0) {
            lc = &cSlotTyped;
            rc = cSlotTypedLight;
         }
      }

      /* Draw outer color. */
      toolkit_drawOutlineThick(x, y, w, h, 1, 3, &rc, lc);

      /* Draw outline if selected. */
      if (i == selected) {
         toolkit_drawOutlineThick(x, y, w, h, 3, 2, &cWhite, NULL);
         toolkit_drawOutlineThick(x, y, w, h, 1, 1, &cBlack, NULL);
      }

      /* Go to next one. */
      y -= h+20;
   }
}


/**
 * @brief Calculates the size the slots need to be for a given window.
 *
 *    @param p Pilot to calculate the slots of.
 *    @param bw Base widget width.
 *    @param bh Base window height.
 *    @param w Width to use.
 *    @param h Height to use.
 *    @param n Number of columns.
 *    @param m Number of rows.
 */
static void equipment_calculateSlots( Pilot *p, double bw, double bh,
      double *w, double *h, int *n, int *m )
{
   double tw, th, s;
   int tm;

   /* Calculate size. */
   tm = MAX( MAX( array_size(p->outfit_weapon), array_size(p->outfit_utility) ), array_size(p->outfit_structure) );
   th = bh / (double)tm;
   tw = bw / 3.;
   s  = MIN( th, tw ) - 20.;
   th = s;
   tw = s;

   /* Return. */
   *w = tw;
   *h = th;
   *n = 3;
   *m = tm;
}
/**
 * @brief Renders the equipment slots.
 *
 *    @param bx Base X position of the widget.
 *    @param by Base Y position of the widget.
 *    @param bw Width of the widget.
 *    @param bh Height of the widget.
 *    @param data Custom widget data.
 */
static void equipment_renderSlots( double bx, double by, double bw, double bh, void *data )
{
   double x, y;
   double w, h;
   double tw;
   int n, m;
   CstSlotWidget *wgt;
   Pilot *p;
   int selected;

   /* Get data. */
   wgt = (CstSlotWidget*) data;
   p   = wgt->selected;
   selected = wgt->slot;

   /* Must have selected ship. */
   if (p == NULL)
      return;

   /* Get dimensions. */
   equipment_calculateSlots( p, bw, bh, &w, &h, &n, &m );
   tw = bw / (double)n;

   /* Draw weapon outfits. */
   x  = bx + (tw-w)/2;
   y  = by + bh - (h+20) + (h+20-h)/2;
   equipment_renderColumn( x, y, w, h,
         p->outfit_weapon, _("Weapon"),
         selected, wgt->outfit, wgt->selected, wgt );

   /* Draw systems outfits. */
   selected -= array_size(p->outfit_weapon);
   x += tw;
   y  = by + bh - (h+20) + (h+20-h)/2;
   equipment_renderColumn( x, y, w, h,
         p->outfit_utility, _("Utility"),
         selected, wgt->outfit, wgt->selected, wgt );

   /* Draw structure outfits. */
   selected -= array_size(p->outfit_utility);
   x += tw;
   y  = by + bh - (h+20) + (h+20-h)/2;
   equipment_renderColumn( x, y, w, h,
         p->outfit_structure, _("Structure"),
         selected, wgt->outfit, wgt->selected, wgt );
}
/**
 * @brief Renders the custom equipment widget.
 *
 *    @param bx Base X position of the widget.
 *    @param by Base Y position of the widget.
 *    @param bw Width of the widget.
 *    @param bh Height of the widget.
 *    @param data Custom widget data.
 */
static void equipment_renderMisc( double bx, double by, double bw, double bh, void *data )
{
   (void) data;
   Pilot *p;
   double percent;
   double x, y;
   double w, h;

   /* Must have selected ship. */
   if (eq_wgt.selected == NULL)
      return;

   p = eq_wgt.selected;

   /* Render ship graphic. */
   equipment_renderShip( bx, by, bw, bh, bx, by, p );

   /* Render mass limit bar. */
   w = 120;
   h = 20;
   x = bx + 10;
   y = by + bh - 48 - 140;

   gl_printMidRaw(&gl_smallFont, w,
      x, y, &cFontWhite, -1., _("Mass Limit Left"));

   y -= gl_smallFont.h + h;

   percent = (p->stats.engine_limit > 0) ? CLAMP(0., 1.,
      (p->stats.engine_limit - p->solid->mass) / p->stats.engine_limit) : 0.;
   toolkit_drawRect(x, y - 2, w * percent, h + 4, &cDarkOrange, NULL);
   toolkit_drawRect(x + w * percent, y - 2, w * (1.-percent), h + 4,
         &cBlack, NULL);
   gl_printMid( &gl_smallFont, w,
      x, y + h / 2. - gl_smallFont.h / 2.,
      &cFontWhite, "%.0f / %.0f", p->stats.engine_limit - p->solid->mass, p->stats.engine_limit );

   if (p->stats.engine_limit > 0. && p->solid->mass > p->stats.engine_limit) {
      y -= h;
      gl_printMid( &gl_smallFont, w,
         x, y, &cFontRed, _("!! %.0f%% Slower !!"),
         (1. - p->speed / p->speed_base) * 100);
   }
}


/**
 * @brief Renders an outfit column.
 *
 *    @param x X position to render at.
 *    @param y Y position to render at.
 *    @param h Height.
 *    @param lst Array (array.h) of elements.
 *    @param mover Slot for which mouseover is active
 *    @param wgt Widget rendering.
 */
static void equipment_renderOverlayColumn( double x, double y, double h,
      PilotOutfitSlot *lst, int mover, CstSlotWidget *wgt )
{
   int i;
   const glColour *c;
   glColour tc;
   int text_width, yoff, top;
   const char *display;
   int subtitle;

   /* Iterate for all the slots. */
   for (i=0; i<array_size(lst); i++) {
      subtitle = 0;
      if (lst[i].outfit != NULL) {
         /* See if needs a subtitle. */
         if ((outfit_isLauncher(lst[i].outfit) ||
                  (outfit_isFighterBay(lst[i].outfit))) &&
               ((lst[i].u.ammo.outfit == NULL) ||
                (lst[i].u.ammo.quantity < outfit_amount(lst[i].outfit))))
            subtitle = 1;
      }
      /* Draw bottom. */
      if ((i==mover) || subtitle) {
         display = NULL;
         if ((i==mover) && (wgt->canmodify)) {
            if (lst[i].outfit != NULL) {
               top = 1;
               display = pilot_canEquip( wgt->selected, &lst[i], NULL );
               if (display != NULL)
                  c = &cFontYellow;
               else {
                  display = _("Right click to remove");
                  c = &cFontBlue;
               }
            }
            else if ((wgt->outfit != NULL) &&
                  (lst->sslot->slot.type == wgt->outfit->slot.type)) {
               top = 1;
               display = pilot_canEquip( wgt->selected, &lst[i], wgt->outfit );
               if (display != NULL)
                  c = &cFontYellow;
               else {
                  display = _("Right click to add");
                  c = &cFontBlue;
               }
            }
         }
         else if (lst[i].outfit != NULL) {
            top = 1;
         }

         if (display != NULL) {
            /* The text might appear on top of previously drawn text. */
            glClear(GL_DEPTH_BUFFER_BIT);

            text_width = gl_printWidthRaw( &gl_smallFont, display );
            if (top)
               yoff = h + 2;
            else
               yoff = -gl_smallFont.h - 3;
            tc.r = 0.;
            tc.g = 0.;
            tc.b = 0.;
            tc.a = 0.9;
            toolkit_drawRect( x, y -5. + yoff,
                  text_width+60, gl_smallFont.h+10,
                  &tc, NULL );
            gl_printMaxRaw( &gl_smallFont, text_width,
                  x+5, y + yoff,
                  c, -1., display );
         }
      }
      /* Go to next one. */
      y -= h+20;
   }
}
/**
 * @brief Renders the equipment overlay.
 *
 *    @param bx Base X position of the widget.
 *    @param by Base Y position of the widget.
 *    @param bw Width of the widget.
 *    @param bh Height of the widget.
 *    @param data Custom widget data.
 */
static void equipment_renderOverlaySlots( double bx, double by, double bw, double bh,
      void *data )
{
   (void) bw;
   Pilot *p;
   int mover;
   double x, y;
   double w, h;
   double tw;
   int n, m;
   PilotOutfitSlot *slot;
   char slot_alt[STRMAX];
   char outfit_alt[STRMAX];
   char *alt;
   int pos;
   const Outfit *o;
   CstSlotWidget *wgt;

   /* Get data. */
   wgt = (CstSlotWidget*) data;
   p   = wgt->selected;

   /* Must have selected ship. */
   if (wgt->selected == NULL)
      return;

   /* Get dimensions. */
   equipment_calculateSlots( p, bw, bh, &w, &h, &n, &m );
   tw = bw / (double)n;

   /* Get selected. */
   mover    = wgt->mouseover;

   /* Render weapon outfits. */
   x  = bx + (tw-w)/2;
   y  = by + bh - (h+20) + (h+20-h)/2;
   equipment_renderOverlayColumn( x, y, h,
         p->outfit_weapon, mover, wgt );
   mover    -= array_size(p->outfit_weapon);
   x += tw;
   y  = by + bh - (h+20) + (h+20-h)/2;
   equipment_renderOverlayColumn( x, y, h,
         p->outfit_utility, mover, wgt );
   mover    -= array_size(p->outfit_utility);
   x += tw;
   y  = by + bh - (h+20) + (h+20-h)/2;
   equipment_renderOverlayColumn( x, y, h,
         p->outfit_structure, mover, wgt );

   /* Mouse must be over something. */
   if (wgt->mouseover < 0)
      return;

   /* Get the slot. */
   if (wgt->mouseover < array_size(p->outfit_weapon))
      slot = &p->outfit_weapon[wgt->mouseover];
   else if (wgt->mouseover < array_size(p->outfit_weapon) + array_size(p->outfit_utility))
      slot = &p->outfit_utility[ wgt->mouseover - array_size(p->outfit_weapon) ];
   else
      slot = &p->outfit_structure[ wgt->mouseover -
         array_size(p->outfit_weapon) - array_size(p->outfit_utility) ];

   /* For comfortability. */
   o = slot->outfit;

   if (slot->sslot->slot.spid)
      pos = scnprintf(slot_alt, sizeof(slot_alt), _("%s slot (%s)"),
            _(sp_display(slot->sslot->slot.spid)),
            slotSize(slot->sslot->slot.size));
   else {
      pos = scnprintf(slot_alt, sizeof(slot_alt), _("%s slot (%s)"),
            _(slotName(slot->sslot->slot.type)),
            _(slotSize(slot->sslot->slot.size)));
   }
   if (slot->sslot->slot.exclusive && (pos < (int)sizeof(slot_alt)))
      pos += scnprintf(&slot_alt[pos], sizeof(slot_alt)-pos,
            _(" #y[Exclusive]#0"));

   /* Slot is empty. */
   if ((o == NULL) || (o->desc_short == NULL)) {
      if (slot->sslot->slot.spid)
         scnprintf(&slot_alt[pos], sizeof(slot_alt)-pos,
               "\n\n%s", _(sp_description(slot->sslot->slot.spid)));
      toolkit_drawAltText(bx + wgt->altx, by + wgt->alty, slot_alt);
      return;
   }

   /* Get text. */
   outfit_altText(outfit_alt, sizeof(outfit_alt), o);

   asprintf(&alt, _("#n%s\n\n#nEquipped outfit:#0\n%s"),
         slot_alt, outfit_alt);

   /* Draw the text. */
   toolkit_drawAltText(bx + wgt->altx, by + wgt->alty, alt);
   free(alt);
}


/**
 * @brief Renders the ship in the equipment window.
 *
 *    @param bx Base X position of the widget.
 *    @param by Base Y position of the widget.
 *    @param bw Width of the widget.
 *    @param bh Height of the widget.
 *    @param x X position to render at.
 *    @param y Y position to render at.
 *    @param p Pilot to render.
 */
static void equipment_renderShip( double bx, double by,
      double bw, double bh, double x, double y, Pilot* p )
{
   int sx, sy;
   Uint32 tick;
   double dt;
   double px, py;
   double pw, ph;
   double w, h;
   Vector2d v;

   tick = SDL_GetTicks();
   dt = (double)(tick - equipment_lastick)/1000.;
   equipment_lastick = tick;
   equipment_dir += p->turn * dt;
   if (equipment_dir > 2*M_PI)
      equipment_dir = fmod( equipment_dir, 2*M_PI );
   gl_getSpriteFromDir( &sx, &sy, p->ship->gfx_space, equipment_dir );

   /* Render ship graphic. */
   if (p->ship->gfx_space->sw > 128) {
      pw = 128;
      ph = 128;
   }
   else {
      pw = p->ship->gfx_space->sw;
      ph = p->ship->gfx_space->sh;
   }
   w  = 128;
   h  = 128;
   px = (x+5) + (bx+bw - (x+5) - pw)/2;
   py = by + bh - 5 - h + (h-ph)/2 + 4;
   x  = (x+5) + (bx+bw - (x+5) - w)/2;
   y  = by + bh - 5 - h + 5;
   toolkit_drawRect( x-5, y-5, w+10, h+10, &cBlack, NULL );
   gl_blitScaleSprite( p->ship->gfx_space,
         px, py, sx, sy, pw, ph, NULL );

#ifdef DEBUGGING
   if (debug_isFlag(DEBUG_MARK_EMITTER)) {
      /* Visualize the trail emitters. */
      double dircos, dirsin;
      int i;
      dircos = cos(equipment_dir);
      dirsin = sin(equipment_dir);
      for (i=0; i<array_size(p->ship->trail_emitters); i++) {
         v.x = p->ship->trail_emitters[i].x_engine * dircos -
              p->ship->trail_emitters[i].y_engine * dirsin;
         v.y = p->ship->trail_emitters[i].x_engine * dirsin +
              p->ship->trail_emitters[i].y_engine * dircos +
              p->ship->trail_emitters[i].h_engine;
         v.x *= pw / p->ship->gfx_space->sw;
         v.y *= ph / p->ship->gfx_space->sh;
         if (p->ship->trail_emitters[i].trail_spec->nebula)
            gl_renderCross(px + pw/2 + v.x, py + ph/2 + v.y*M_SQRT1_2, 2, &cFontBlue);
         else
            gl_renderCross(px + pw/2 + v.x, py + ph/2 + v.y*M_SQRT1_2, 4, &cInert);
      }
   }
#endif /* DEBUGGING */

   if ((eq_wgt.slot >= 0) && (eq_wgt.slot < array_size(p->outfit_weapon))) {
      p->tsx = sx;
      p->tsy = sy;
      pilot_getMount( p, &p->outfit_weapon[eq_wgt.slot], &v );
      px += pw/2;
      py += ph/2;
      v.x *= pw / p->ship->gfx_space->sw;
      v.y *= ph / p->ship->gfx_space->sh;

      /* Render it. */
      glUseProgram(shaders.crosshairs.program);
      glUniform1f(shaders.crosshairs.paramf, 2.);
      gl_renderShader( px+v.x, py+v.y, 7, 7, 0., &shaders.crosshairs, &cRadar_player, 1 );
   }

   toolkit_drawOutline( x - 4., y-4., w+7., h+2., 1., toolkit_colLight, NULL  );
   toolkit_drawOutline( x - 4., y-4., w+7., h+2., 2., toolkit_colDark, NULL  );
}
/**
 * @brief Handles a mouse press in column.
 *
 *    @param y Y position of the column.
 *    @param h Height of column.
 *    @param n Number of elements in column.
 *    @param my Mouse press position.
 *    @return Number pressed (or -1 if none).
 */
static int equipment_mouseInColumn( double y, double h, int n, double my )
{
   int i;

   for (i=0; i<n; i++) {
      if ((my > y) && (my < y+h+20))
         return i;
      y -= h+20;
   }

   return -1;
}
/**
 * @brief Handles a mouse press in a column.
 *
 *    @param wid Parent window id.
 *    @param event Mouse input event.
 *    @param mx Mouse X event position.
 *    @param my Mouse Y event position.
 *    @param y Y position of the column.
 *    @param h Height of the column.
 *    @param os Array (array.h) of elements in the column.
 *    @param p Pilot to which the elements belong.
 *    @param selected Currently selected element.
 *    @param wgt Slot widget.
 */
static int equipment_mouseColumn( unsigned int wid, SDL_Event* event,
      double mx, double my, double y, double h, PilotOutfitSlot* os,
      Pilot *p, int selected, CstSlotWidget *wgt )
{
   int ret, exists, level;
   int wstype;

   ret = equipment_mouseInColumn( y, h, array_size(os), my );
   if (ret < 0)
      return 0;

   if (event->type == SDL_MOUSEBUTTONDOWN) {
      /* Normal mouse usage. */
      if (wgt->weapons < 0) {
         if (event->button.button == SDL_BUTTON_LEFT)
            wgt->slot = selected + ret;
         else if ((event->button.button == SDL_BUTTON_RIGHT) &&
               wgt->canmodify)
            equipment_swapSlot( wid, p, &os[ret] );
      }
      /* Viewing weapon slots. */
      else {
         /* See if it exists. */
         exists = pilot_weapSetCheck(p, wgt->weapons, &os[ret]);
         wstype = pilot_weapSetTypeCheck(p, wgt->weapons);
         /* Get the level of the selection. */
         if (event->button.button == SDL_BUTTON_LEFT)
            level = 0;
         else if (event->button.button == SDL_BUTTON_RIGHT)
            level = 1;
         else
            return 0; /* We ignore this type of click. */
         /* See if we should add it or remove it. */
         if ((exists == level)
               || ((wstype == WEAPSET_TYPE_WEAPON) && (exists != -1)))
            pilot_weapSetRm(p, wgt->weapons, &os[ret]);
         else {
            /* This is a bloody awful place to do this. I hate it. HATE!. */
            /* Case active outfit, convert the weapon group to active outfit. */
            if ((os->sslot->slot.type == OUTFIT_SLOT_STRUCTURE) ||
                  (os->sslot->slot.type == OUTFIT_SLOT_UTILITY)) {
               pilot_weapSetRmSlot( p, wgt->weapons, OUTFIT_SLOT_WEAPON );
               pilot_weapSetAdd( p, wgt->weapons, &os[ret], 0 );
               pilot_weapSetType( p, wgt->weapons, WEAPSET_TYPE_ACTIVE );
            }
            /* Case change weapon groups or active weapon. */
            else {
               pilot_weapSetRmSlot(p, wgt->weapons, OUTFIT_SLOT_STRUCTURE);
               pilot_weapSetRmSlot(p, wgt->weapons, OUTFIT_SLOT_UTILITY);

               if (wstype == WEAPSET_TYPE_ACTIVE)
                  wstype = WEAPSET_TYPE_CHANGE;
               else if (wstype == WEAPSET_TYPE_WEAPON)
                  level = 0;

               pilot_weapSetType(p, wgt->weapons, wstype);
               pilot_weapSetAdd(p, wgt->weapons, &os[ret], level);
            }
         }
         p->autoweap = 0; /* Disable autoweap. */
         info_update(); /* Need to update weapons. */
         
         /* Notify GUI of modification. */
         gui_setShip();
      }
   }
   else {
      wgt->mouseover  = selected + ret;
      wgt->altx       = mx;
      wgt->alty       = my;
   }

   return 1;
}
/**
 * @brief Does mouse input for the custom equipment widget.
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
static int equipment_mouseSlots( unsigned int wid, SDL_Event* event,
      double mx, double my, double bw, double bh,
      double rx, double ry, void *data )
{
   (void) bw;
   (void) rx;
   (void) ry;
   Pilot *p;
   int selected, ret;
   double x, y;
   double w, h;
   double tw;
   CstSlotWidget *wgt;
   int n, m;

   /* Get data. */
   wgt = (CstSlotWidget*) data;
   p   = wgt->selected;

   /* Must have selected ship. */
   if (p == NULL)
      return 0;

   /* Must be left click for now. */
   if ((event->type != SDL_MOUSEBUTTONDOWN) &&
         (event->type != SDL_MOUSEMOTION))
      return 0;

   /* Get dimensions. */
   equipment_calculateSlots( p, bw, bh, &w, &h, &n, &m );
   tw = bw / (double)n;

   /* Render weapon outfits. */
   selected = 0;
   x  = (tw-w)/2;
   y  = bh - (h+20) + (h+20-h)/2 - 10;
   if ((mx > x-10) && (mx < x+w+10)) {
      ret = equipment_mouseColumn( wid, event, mx, my, y, h,
            p->outfit_weapon, p, selected, wgt );
      if (ret)
         return !!(event->type == SDL_MOUSEBUTTONDOWN);
   }
   selected += array_size(p->outfit_weapon);
   x += tw;
   if ((mx > x-10) && (mx < x+w+10)) {
      ret = equipment_mouseColumn( wid, event, mx, my, y, h,
            p->outfit_utility, p, selected, wgt );
      if (ret)
         return !!(event->type == SDL_MOUSEBUTTONDOWN);
   }
   selected += array_size(p->outfit_utility);
   x += tw;
   if ((mx > x-10) && (mx < x+w+10)) {
      ret = equipment_mouseColumn( wid, event, mx, my, y, h,
            p->outfit_structure, p, selected, wgt );
      if (ret)
         return !!(event->type == SDL_MOUSEBUTTONDOWN);
   }

   /* Not over anything. */
   wgt->mouseover = -1;
   return 0;
}


/**
 * @brief Swaps an equipment slot.
 *
 *    @param wid Parent window id.
 *    @param p Pilot swapping slots.
 *    @param slot Slot to swap.
 */
static int equipment_swapSlot( unsigned int wid, Pilot *p, PilotOutfitSlot *slot )
{
   int ret;
   const Outfit *o, *ammo;
   int i;
   PilotOutfitSlot* dockslot;
   Pilot *escort;

   /* Remove outfit. */
   if (slot->outfit != NULL) {
      o = slot->outfit;

      /* Must be able to remove. */
      if (pilot_canEquip( eq_wgt.selected, slot, NULL ) != NULL)
         return 0;

      /* Remove ammo first. */
      ammo = outfit_ammo(o);
      if ( ammo != NULL )
         pilot_rmAmmo( eq_wgt.selected, slot, slot->u.ammo.quantity );

      /* Recall deployed fighters if it's a fighter bay. */
      if (outfit_isFighterBay(o)) {
         for (i=array_size(p->escorts)-1; i>=0; i--) {
            escort = pilot_get(p->escorts[i].id);
            if ((escort == NULL) || pilot_isFlag(escort, PILOT_DEAD)
                  || pilot_isFlag(escort, PILOT_DELETE))
               continue;

            dockslot = pilot_getDockSlot(escort);
            if ((dockslot == NULL) || (dockslot->id != slot->id))
               continue;

            pilot_delete(escort);
         }
      }

      /* Remove outfit. */
      ret = pilot_rmOutfit( eq_wgt.selected, slot );
      if (ret == 0)
         equipment_playerAddOutfit( o, 1 );
   }
   /* Add outfit. */
   else {
      /* Must have outfit. */
      o = eq_wgt.outfit;
      if (o==NULL)
         return 0;

      /* Must fit slot. */
      if (!outfit_fitsSlot( o, &slot->sslot->slot ))
         return 0;

      /* Must be able to add. */
      if (pilot_canEquip( eq_wgt.selected, slot, o ) != NULL)
         return 0;

      /* Add outfit to ship. */
      ret = equipment_playerRmOutfit( o, 1 );
      if (ret == 1) {
         pilot_addOutfitRaw( eq_wgt.selected, o, slot );

         /* Recalculate stats. */
         pilot_calcStats( eq_wgt.selected );
      }

      equipment_addAmmo();
   }

   /* Refuel if necessary. */
   land_refuel();

   /* Recalculate stats. */
   pilot_calcStats( p );
   pilot_healLanded( p );

   /* Redo the outfits thingy. */
   equipment_regenLists( wid, 1, 1 );

   /* Update outfits. */
   outfits_updateEquipmentOutfits();

   /* Update weapon sets if needed. */
   if (eq_wgt.selected->autoweap)
      pilot_weaponAuto( eq_wgt.selected );
   pilot_weaponSafe( eq_wgt.selected );

   /* Notify GUI of modification. */
   gui_setShip();

   return 0;
}


/**
 * @brief Regenerates the equipment window lists.
 *
 *    @param wid Window to regenerate lists.
 *    @param outfits Whether or not should regenerate outfits list.
 *    @param ships Whether or not to regenerate ships list.
 */
void equipment_regenLists( unsigned int wid, int outfits, int ships )
{
   int i, ret;
   int nship;
   double offship;
   char *s, selship[PATH_MAX];
   char *focused;

   /* Default.s */
   nship    = 0;
   offship  = 0.;

   /* Must exist. */
   if (!window_existsID( equipment_wid ))
      return;

   /* Save focus. */
   focused = window_getFocus( wid );

   /* Save positions. */
   if (outfits) {
      i = window_tabWinGetActive( wid, EQUIPMENT_OUTFIT_TAB );
      toolkit_saveImageArrayData( wid, EQUIPMENT_OUTFITS, &iar_data[i] );
      window_destroyWidget( wid, EQUIPMENT_OUTFITS );
   }
   if (ships) {
      nship   = toolkit_getImageArrayPos(    wid, EQUIPMENT_SHIPS );
      offship = toolkit_getImageArrayOffset( wid, EQUIPMENT_SHIPS );
      s       = toolkit_getImageArray(       wid, EQUIPMENT_SHIPS );
      strncpy( selship, s, sizeof(selship)-1 );
      selship[PATH_MAX-1] = '\0'; /* Just in case. */
      window_destroyWidget( wid, EQUIPMENT_SHIPS );
   }

   /* Regenerate lists. */
   equipment_genLists( wid );

   /* Restore positions. */
   if (outfits) {
      toolkit_setImageArrayPos(    wid, EQUIPMENT_OUTFITS, iar_data[i].pos );
      toolkit_setImageArrayOffset( wid, EQUIPMENT_OUTFITS, iar_data[i].offset );
      equipment_updateOutfits( wid, NULL );
   }
   if (ships) {
      toolkit_setImageArrayPos(    wid, EQUIPMENT_SHIPS, nship );
      toolkit_setImageArrayOffset( wid, EQUIPMENT_SHIPS, offship );
      /* Try to maintain same ship selected. */
      s = toolkit_getImageArray( wid, EQUIPMENT_SHIPS );
      if ((s != NULL) && (strcmp(s,selship)!=0)) {
         ret = toolkit_setImageArray( wid, EQUIPMENT_SHIPS, selship );
         if (ret != 0) /* Failed to maintain. */
            toolkit_setImageArrayPos( wid, EQUIPMENT_SHIPS, nship );

         /* Update ships. */
         equipment_updateShips( wid, NULL );
      }
   }

   /* Restore focus. */
   window_setFocus( wid, focused );
   free(focused);
}


/**
 * @brief Adds all the ammo it can to the player.
 */
void equipment_addAmmo (void)
{
   Pilot *p;

   /* Get player. */
   if (eq_wgt.selected == NULL)
      p = player.p;
   else
      p = eq_wgt.selected;

   /* Add ammo to all outfits. */
   pilot_fillAmmo( p );

   /* Update weapon sets if needed. */
   if (p->autoweap)
      pilot_weaponAuto( p );
   pilot_weaponSafe( p );

   /* Notify GUI of modification. */
   gui_setShip();
}


/**
 * @brief Creates and allocates a string containing the ship stats.
 *
 *    @param buf Buffer to write to.
 *    @param max_len Maximum length of the string to allocate.
 *    @param s Pilot to get stats of.
 *    @param dpseps Whether or not to display dps and eps.
 */
int equipment_shipStats( char *buf, int max_len,  const Pilot *s, int dpseps )
{
   int j, l;
   const Outfit *o;
   double mod_energy, mod_damage, mod_shots;
   double eps, dps, shots;
   const Damage *dmg;

   dps = 0.;
   eps = 0.;
   /* Calculate damage and energy per second. */
   if (dpseps) {
      for (j=0; j<array_size(s->outfits); j++) {
         o = s->outfits[j]->outfit;
         if (o==NULL)
            continue;
         switch (o->type) {
            case OUTFIT_TYPE_BOLT:
               mod_energy = s->stats.blt_energy * s->stats.fwd_energy;
               mod_damage = s->stats.blt_damage * s->stats.fwd_damage;
               mod_shots = 1. / (s->stats.blt_firerate*s->stats.fwd_firerate);
               break;
            case OUTFIT_TYPE_TURRET_BOLT:
               mod_energy = s->stats.blt_energy * s->stats.tur_energy;
               mod_damage = s->stats.blt_damage * s->stats.tur_damage;
               mod_shots = 1. / (s->stats.blt_firerate*s->stats.tur_firerate);
               break;
            case OUTFIT_TYPE_LAUNCHER:
               mod_energy = 1.;
               mod_damage = s->stats.launch_damage * s->stats.fwd_damage;
               mod_shots = 1. / (s->stats.launch_rate*s->stats.fwd_firerate);
               break;
            case OUTFIT_TYPE_TURRET_LAUNCHER:
               mod_energy = 1.;
               mod_damage = s->stats.launch_damage * s->stats.tur_damage;
               mod_shots = 1. / (s->stats.launch_rate*s->stats.tur_firerate);
               break;
            case OUTFIT_TYPE_BEAM:
            case OUTFIT_TYPE_TURRET_BEAM:
               /* Special case due to continuous fire. */
               mod_energy = s->stats.bem_energy;
               mod_damage = s->stats.bem_damage;
               mod_shots = s->stats.bem_cooldown;
               if (o->type == OUTFIT_TYPE_BEAM) {
                  mod_energy *= s->stats.fwd_energy;
                  mod_damage *= s->stats.fwd_damage;
                  mod_shots *= 1. / s->stats.fwd_firerate;
               }
               else {
                  mod_energy *= s->stats.tur_energy;
                  mod_damage *= s->stats.tur_damage;
                  mod_shots *= 1. / s->stats.tur_firerate;
               }
               shots = s->stats.bem_duration * outfit_duration(o);
               mod_shots = shots / (shots + mod_shots*outfit_delay(o));
               dps += mod_shots * mod_damage * outfit_damage(o)->damage;
               eps += mod_shots * mod_energy * outfit_energy(o);
               continue;

            default:
               continue;
         }
         shots = 1. / (mod_shots * outfit_delay(o));

         /* Special case: Ammo-based weapons. */
         if (outfit_isLauncher(o))
            dmg = outfit_damage(o->u.lau.ammo);
         else
            dmg = outfit_damage(o);
         dps  += shots * mod_damage * dmg->damage;
         eps  += shots * mod_energy * MAX( outfit_energy(o), 0. );
      }
   }

   /* Write to buffer. */
   l = 0;
   if (dps > 0.)
      l += scnprintf( &buf[l], (max_len-l),
            _("%s%.1f GW Weapon Damage\n%.1f GW Weapon Energy"), (l!=0)?"\n":"", dps, eps );
   l += ss_statsDesc(&s->stats, &buf[l], (max_len-l), l, 1);
   return l;
}


/**
 * @brief Generates a new ship/outfit lists if needed.
 *
 *    @param wid Parent window id.
 */
static void equipment_genLists( unsigned int wid )
{
   /* Outfit list. */
   equipment_genOutfitList(wid);

   /* Ship list. */
   equipment_genShipList(wid);

   /* Update window. */
   equipment_updateOutfits(wid, NULL);
   equipment_updateShips(wid, NULL);
}


/**
 * @brief Generates the ship list.
 *    @param wid Window to generate list on.
 */
static void equipment_genShipList( unsigned int wid )
{
   int i, l;
   ImageArrayCell *cships;
   int nships;
   int w, h;
   int sw, sh;
   Pilot *s;
   const PlayerShip_t *ps;
   char r[PATH_MAX];
   glTexture *t;
   int iconsize;

   /* Get dimensions. */
   equipment_getDim( wid, &w, &h, &sw, &sh, NULL, NULL,
         NULL, NULL, NULL, NULL, NULL, NULL );

   /* Ship list. */
   if (!widget_exists( wid, EQUIPMENT_SHIPS )) {
      eq_wgt.selected = NULL;
      nships = player_nships() + 1;
      cships = calloc(nships, sizeof(ImageArrayCell));
      /* Add player's current ship. */
      cships[0].image = gl_dupTexture(player.p->ship->gfx_store);
      cships[0].caption = strdup(player.p->name);
      cships[0].layers = gl_copyTexArray( player.p->ship->gfx_overlays, &cships[0].nlayers );
      t = gl_newImage( OVERLAY_GFX_PATH"active.webp", OPENGL_TEX_MIPMAPS );
      cships[0].layers = gl_addTexArray( cships[0].layers, &cships[0].nlayers, t );
      if (player.p->ship->rarity > 0) {
         snprintf( r, sizeof(r), OVERLAY_GFX_PATH"rarity_%d.webp", player.p->ship->rarity );
         t = gl_newImage( r, OPENGL_TEX_MIPMAPS );
         cships[0].layers = gl_addTexArray( cships[0].layers, &cships[0].nlayers, t );
      }
      player_shipsSort();
      ps = player_getShipStack();
      for (i=1; i<=array_size(ps); i++) {
         cships[i].image = gl_dupTexture(ps[i-1].p->ship->gfx_store);
         cships[i].caption = strdup(ps[i-1].p->name);
         cships[i].layers = gl_copyTexArray(ps[i-1].p->ship->gfx_overlays,
               &cships[i].nlayers);
         if (ps[i-1].p->ship->rarity > 0) {
            snprintf(r, sizeof(r), OVERLAY_GFX_PATH"rarity_%d.webp",
                  ps[i-1].p->ship->rarity);
            t = gl_newImage(r, OPENGL_TEX_MIPMAPS);
            cships[i].layers = gl_addTexArray(cships[i].layers,
                  &cships[i].nlayers, t);
         }
      }
      /* Ship stats in alt text. */
      for (i=0; i<nships; i++) {
         s        = player_getShip( cships[i].caption );
         cships[i].alt = malloc( STRMAX_SHORT );
         l        = snprintf( &cships[i].alt[0], STRMAX_SHORT, _("Ship Stats\n") );
         l        = equipment_shipStats( &cships[i].alt[0], STRMAX_SHORT-l, s, 1 );
         if (l == 0) {
            free( cships[i].alt );
            cships[i].alt = NULL;
         }
      }

      /* Create the image array. */
      iconsize = 96;
      window_addImageArray(
         wid, 10, -40, sw, sh, EQUIPMENT_SHIPS, iconsize, iconsize,
         cships, nships, equipment_updateShips, NULL,
         equipment_transChangeShip);
      toolkit_setImageArrayAccept(wid, EQUIPMENT_SHIPS,
            equipment_transChangeShip);
   }
}


/**
 * @brief Generates the outfit list.
 *    @param wid Window to generate list on.
 */
static void equipment_genOutfitList( unsigned int wid )
{
   int x, y, w, h, ow, oh;
   int ix, iy, iw, ih, barw; /* Input filter. */
   char *filtertext;
   int (*tabfilters[])( const Outfit *o ) = {
      NULL,
      outfit_filterWeapon,
      outfit_filterUtility,
      outfit_filterStructure,
      outfit_filterCore
   };
   const char *tabnames[] = {
      OUTFIT_LABEL_ALL, OUTFIT_LABEL_WEAPON, OUTFIT_LABEL_UTILITY,
      OUTFIT_LABEL_STRUCTURE, OUTFIT_LABEL_CORE
   };

   int noutfits, active;
   ImageArrayCell *coutfits;
   int iconsize;

   /* Get dimensions. */
   equipment_getDim( wid, &w, &h, NULL, NULL, &ow, &oh,
         NULL, NULL, NULL, NULL, NULL, NULL );

   /* Deselect. */
   eq_wgt.outfit = NULL;

   /* Calculate position. */
   x = 10;
   y = 20;

   /* Create tabbed window. */
   if (!widget_exists( wid, EQUIPMENT_OUTFIT_TAB )) {
      window_addTabbedWindow( wid, x, y + oh - 30, ow, 30,
            EQUIPMENT_OUTFIT_TAB, OUTFIT_TABS, tabnames, 1 );

      barw = window_tabWinGetBarWidth( wid, EQUIPMENT_OUTFIT_TAB );

      iw = CLAMP(0, 150, ow - barw - 30);
      ih = 20;

      ix = ow - iw;
      iy = oh - (30 - ih) / 2; /* Centered relative to 30 px tab bar */

      /* Only create the filter widget if it will be a reasonable size. */
      if (iw >= 30) {
         window_addInput( wid, ix+5, iy+1, iw, ih, EQUIPMENT_FILTER, 32, 1, &gl_smallFont );
         inp_setEmptyText( wid, EQUIPMENT_FILTER, _("Filter…") );
         window_setInputCallback( wid, EQUIPMENT_FILTER, equipment_filterOutfits );
      }
   }

   window_tabWinOnChange( wid, EQUIPMENT_OUTFIT_TAB, equipment_changeTab );
   active = window_tabWinGetActive( equipment_wid, EQUIPMENT_OUTFIT_TAB );

   /* Widget must not already exist. */
   if (widget_exists( wid, EQUIPMENT_OUTFITS ))
      return;

   /* Allocate space. */
   noutfits = MAX( 1, player_numOutfits() ); /* This is the most we'll need, probably less due to filtering. */
   free( iar_outfits[active] );
   iar_outfits[active] = calloc( noutfits, sizeof(Outfit*) );

   filtertext = NULL;
   if (widget_exists(equipment_wid, EQUIPMENT_FILTER)) {
      filtertext = window_getInput( equipment_wid, EQUIPMENT_FILTER );
      if (strlen(filtertext) == 0)
         filtertext = NULL;
   }

   /* Get the outfits. */
   noutfits = player_getOutfitsFiltered( (const Outfit**)iar_outfits[active], tabfilters[active], filtertext );
   coutfits = outfits_imageArrayCells( (const Outfit**)iar_outfits[active], &noutfits );


   /* Create the actual image array. */
   iw = ow;
   ih = oh - 34;
   iconsize = 96;
   window_addImageArray(wid, x, y, iw, ih,
         EQUIPMENT_OUTFITS, iconsize, iconsize,
         coutfits, noutfits,
         equipment_updateOutfits,
         equipment_rightClickOutfits,
         equipment_rightClickOutfits);

   toolkit_setImageArrayAccept( wid, EQUIPMENT_OUTFITS, equipment_rightClickOutfits );
}


/**
 * @brief Gets the colour for comparing a current value vs a ship base value.
 */
static char eq_qCol(double cur, double base, int inv, int outcond)
{
   if (outcond)
      return 'D';
   else if (cur > base)
      return (inv) ? 'B' : 'G';
   else if (cur < base)
      return (inv) ? 'G' : 'B';
   return '0';
}


/**
 * @brief Gets the symbol for comparing a current value vs a ship base value.
 */
static const char* eq_qSym(double cur, double base, int inv, int outcond)
{
   if (outcond)
      return "!! ";
   else if (cur > base)
      return (inv) ? "* " : "";
   else if (cur < base)
      return (inv) ? "" : "* ";
   return "";
}


#define EQ_COMP(cur, base, inv, outcond) \
   eq_qCol(cur, base, inv, (outcond)), eq_qSym(cur, base, inv, (outcond)), cur
/**
 * @brief Updates the player's ship window.
 *    @param wid Window to update.
 *    @param str Unused.
 */
void equipment_updateShips( unsigned int wid, char* str )
{
   (void)str;
   char *buf;
   char buf_price[STRMAX_SHORT];
   char buf_money[STRMAX_SHORT];
   char buf_jumps[STRMAX_SHORT];
   char errorReport[STRMAX_SHORT];
   int problems;
   char *shipname;
   Pilot *ship;
   char *nt, *nt2;
   int onboard;
   int cargo, jumps;

   /* Clear defaults. */
   eq_wgt.slot = -1;
   eq_wgt.mouseover = -1;
   equipment_lastick = SDL_GetTicks();

   /* Get the ship. */
   shipname = toolkit_getImageArray( wid, EQUIPMENT_SHIPS );
   if ((shipname == NULL) || (strcmp(shipname, player.p->name) == 0)) {
      ship = player.p;
      onboard = 1;
   }
   else {
      ship   = player_getShip( shipname );
      onboard = 0;
   }
   eq_wgt.selected = ship;

   /* update text */
   credits2str(buf_price, sizeof(buf_price), player_shipPrice(shipname), 2);
   credits2str(buf_money, sizeof(buf_money), player.p->credits, 2);
   cargo = pilot_cargoFree(ship) + pilot_cargoUsed(ship);
   nt = ntime_pretty(pilot_hyperspaceDelay(ship), 1);
   nt2 = ntime_pretty(
      ntime_create(0, 0, (int)(NT_DAY_SECONDS * ship->stats.land_delay)), 1);

   /* Get ship error report. */
   problems = pilot_reportSpaceworthy(ship, errorReport, sizeof(errorReport));

   if (ship->fuel_consumption != 0) {
      jumps = floor(ship->fuel_max / ship->fuel_consumption);
      snprintf(buf_jumps, sizeof(buf_jumps),
            n_("%d jump", "%d jumps", jumps), jumps);
   }
   else {
      strcpy(buf_jumps, _("∞ jumps"));
   }

   /* Fill the buffer. */
   asprintf(&buf,
      _("#nName:#0 %s\n"
         "#nModel:#0 %s (%s class)\n"
         "#nValue:#0 %s\n"
         "#nMoney:#0 %s\n"
         "\n"
         "#nMass:#0 %.0f kt\n"
         "#nJump Time:#0 %s\n"
         "#nTakeoff Time:#0 %s\n"
         "#nAcceleration:#0 #%c%s%.0f#0 mAU/s²\n"
         "#nSpeed:#0 #%c%s%.0f#0 mAU/s (max %.0f mAU/s)\n"
         "#nTurn:#0 #%c%s%.0f#0 deg/s\n"
         "#nTime Passage Rate:#0 #%c%s%.0f%%#0\n"
         "\n"
         "#nAbsorption:#0 #%c%s%.0f%%\n"
         "#nShield:#0 #%c%s%.0f#0 GJ; #nRegeneration:#0 #%c%s%.1f#0 GW\n"
         "#nArmor:#0 #%c%s%.0f#0 GJ; #nRegeneration:#0 #%c%s%.1f#0 GW\n"
         "#nEnergy:#0 #%c%s%.0f#0 GJ; #nRegeneration:#0 #%c%s%.1f#0 GW\n"
         "#nCargo:#0 %d / #%c%s%d#0 kt\n"
         "#nFuel:#0 #%c%s%.0f#0 kmol (%s); #nRegeneration:#0 #%c%s%.2f#0 kmol/s\n"
         "#nRadar Range:#0 #%c%s%.0f#0 mAU\n"
         "#nJump Detect Range:#0 #%c%s%.0f#0 mAU\n"
         "\n"
         "#nShip Status:#0\n"
         "#%c%s#0"),
         /* Generic. */
      ship->name,
      _(ship->ship->name),
      _(ship->ship->class),
      buf_price,
      buf_money,
      /* Movement. */
      ship->solid->mass,
      nt,
      nt2,
      EQ_COMP(ship->thrust / ship->solid->mass,
            (ship->ship->thrust+ship->ship->stats_array.thrust)
               * ship->ship->stats_array.thrust_mod / ship->ship->mass,
            0, ship->thrust / ship->solid->mass <= 0.5),
      EQ_COMP(ship->speed,
            (ship->ship->speed+ship->ship->stats_array.speed)
               * ship->ship->stats_array.speed_mod
               * ship->ship->stats_array.speed,
            0, ship->speed <= 0.5),
      solid_maxspeed(ship->solid, ship->speed, ship->thrust),
      EQ_COMP(ship->turn * 180. / M_PI,
            (ship->ship->turn*180./M_PI + ship->ship->stats_array.turn)
               * ship->ship->stats_array.turn_mod,
            0, ship->turn*180./M_PI <= 0.5),
      EQ_COMP(ship->stats.time_mod * ship->ship->dt_default * 100.,
            ship->ship->stats_array.time_mod * ship->ship->dt_default * 100.,
            1, 0),
      /* Health. */
      EQ_COMP(ship->dmg_absorb * 100.,
            CLAMP(0., 1.,
               ship->ship->dmg_absorb+ship->ship->stats_array.absorb) * 100.,
            0, ship->dmg_absorb < 0.),
      EQ_COMP(ship->shield_max,
            (ship->ship->shield+ship->ship->stats_array.shield)
               * ship->ship->stats_array.shield_mod,
            0, ship->shield_max <= 0.),
      EQ_COMP(ship->shield_regen,
            (ship->ship->shield_regen+ship->ship->stats_array.shield_regen)
               * ship->ship->stats_array.shield_regen_mod
               - ship->ship->stats_array.shield_regen_malus,
            0, ship->shield_regen < 0.),
      EQ_COMP(ship->armour_max,
            (ship->ship->armour+ship->ship->stats_array.armour)
               * ship->ship->stats_array.armour_mod,
            0, ship->armour_max <= 0.),
      EQ_COMP(ship->armour_regen,
            (ship->ship->armour_regen+ship->ship->stats_array.armour_regen)
               * ship->ship->stats_array.armour_regen_mod
               - ship->ship->stats_array.armour_regen_malus,
            0, ship->armour_regen < 0.),
      EQ_COMP(ship->energy_max,
            (ship->ship->energy+ship->ship->stats_array.energy)
               * ship->ship->stats_array.energy_mod,
            0, ship->energy_max <= 0.),
      EQ_COMP(ship->energy_regen,
            (ship->ship->energy_regen+ship->ship->stats_array.energy_regen)
               * ship->ship->stats_array.energy_regen_mod
               - ship->ship->stats_array.energy_regen_malus,
            0, ship->energy_regen <= 0.05),
      /* Misc. */
      pilot_cargoUsed(ship),
      EQ_COMP(cargo,
            (ship->ship->cap_cargo+ship->ship->stats_array.cargo)
               * ship->ship->stats_array.cargo_mod,
            0, cargo < 0.),
      EQ_COMP(ship->fuel_max, ship->ship->fuel + ship->ship->stats_array.fuel,
            0, ship->fuel_max < ship->fuel_consumption),
      buf_jumps,
      EQ_COMP(ship->fuel_regen,
            ship->ship->fuel_regen + ship->ship->stats_array.fuel_regen,
            0, ship->fuel_regen < 0.),
      EQ_COMP(ship->rdr_range,
            (ship->ship->rdr_range+ship->ship->stats_array.rdr_range)
               * ship->ship->stats_array.rdr_range_mod,
            0, ship->rdr_range < 0.),
      EQ_COMP(ship->rdr_jump_range,
            (ship->ship->rdr_jump_range+ship->ship->stats_array.rdr_jump_range)
               * ship->ship->stats_array.rdr_jump_range_mod,
            0, ship->rdr_jump_range < 0.),
      problems ? 'D' : '0', errorReport);
   window_modifyText(wid, "txtDDesc", buf);

   /* Clean up. */
   free(buf);
   free(nt);
   free(nt2);

   /* button disabling */
   if (onboard) {
      window_disableButton(wid, "btnSellShip");
      window_disableButton(wid, "btnChangeShip");
   }
   else {
      window_enableButton(wid, "btnChangeShip");
      window_enableButton(wid, "btnSellShip");
   }
}
#undef EQ_COMP
/**
 * @brief Updates the player's outfit list.
 *    @param wid Window to update.
 *    @param str Unused.
 */
void equipment_updateOutfits( unsigned int wid, char* str )
{
   (void) wid;
   (void) str;
   int i, active;

   window_disableButton(wid, "btnSellOutfit");

   /* Must have outfit. */
   active = window_tabWinGetActive( wid, EQUIPMENT_OUTFIT_TAB );
   i = toolkit_getImageArrayPos( wid, EQUIPMENT_OUTFITS );
   if (i < 0 || iar_outfits[active] == NULL) {
      eq_wgt.outfit = NULL;
      return;
   }

   eq_wgt.outfit = iar_outfits[active][i];
   if (eq_wgt.outfit != NULL)
      window_enableButton(wid, "btnSellOutfit");
}

/**
 * @brief Handles text input in the filter input widget.
 *    @param wid Window containing the widget.
 *    @param str Unused.
 */
static void equipment_filterOutfits( unsigned int wid, char *str )
{
   (void) str;
   equipment_regenLists(wid, 1, 0);
}

/**
 * @brief Ensures the tab's selected item is reflected in the ship slot list
 *
 *    @param wid Unused.
 *    @param wgt Unused.
 *    @param old Tab changed from.
 *    @param tab Tab changed to.
 */
static void equipment_changeTab( unsigned int wid, char *wgt, int old, int tab )
{
   (void) wid;
   (void) wgt;
   int pos;
   double offset;

   toolkit_saveImageArrayData( wid, EQUIPMENT_OUTFITS, &iar_data[old] );

   /* Store the currently-saved positions for the new tab. */
   pos    = iar_data[tab].pos;
   offset = iar_data[tab].offset;

   /* Resetting the input will cause the outfit list to be regenerated. */
   if (widget_exists(wid, EQUIPMENT_FILTER))
      window_setInput(wid, EQUIPMENT_FILTER, NULL);
   else
      equipment_regenLists(wid, 1, 0);

   /* Set positions for the new tab. This is necessary because the stored
    * position for the new tab may have exceeded the size of the old tab,
    * resulting in it being clipped. */
   toolkit_setImageArrayPos(    wid, EQUIPMENT_OUTFITS, pos );
   toolkit_setImageArrayOffset( wid, EQUIPMENT_OUTFITS, offset );

   /* Focus the outfit image array. */
   window_setFocus( wid, EQUIPMENT_OUTFITS );
}

/**
 * @brief Changes ship.
 *    @param wid Window player is attempting to change ships in.
 *    @param str Unused.
 */
static void equipment_transChangeShip( unsigned int wid, char* str )
{
   (void) str;

   equipment_changeShip( wid );

   /* update the window to reflect the change */
   equipment_updateShips( wid, NULL );
}
/**
 * @brief Player attempts to change ship.
 *    @param wid Window player is attempting to change ships in.
 */
static void equipment_changeShip( unsigned int wid )
{
   char *shipname, *filtertext;
   int i;

   shipname = toolkit_getImageArray( wid, EQUIPMENT_SHIPS );

   if (land_errDialogue( shipname, "swapEquipment" ))
      return;

   /* Store active tab, filter text, and positions for the outfits. */
   i = window_tabWinGetActive( wid, EQUIPMENT_OUTFIT_TAB );
   toolkit_saveImageArrayData( wid, EQUIPMENT_OUTFITS, &iar_data[i] );
   if (widget_exists(wid, EQUIPMENT_FILTER))
      filtertext = window_getInput( equipment_wid, EQUIPMENT_FILTER );
   else
      filtertext = NULL;

   /* Swap ship. */
   player_swapShip( shipname, 1 );
   pilot_healLanded( player.p );

   /* What happens here is the gui gets recreated when the player swaps ship.
    * This causes all the windows to be destroyed and the 'wid' we have here
    * becomes invalid. However, since we store it in a global variable we can
    * recover it and use it instead. */
   wid = equipment_wid;

   /* Restore outfits image array properties. */
   window_tabWinSetActive( wid, EQUIPMENT_OUTFIT_TAB, i );
   toolkit_setImageArrayPos(    wid, EQUIPMENT_OUTFITS, iar_data[i].pos );
   toolkit_setImageArrayOffset( wid, EQUIPMENT_OUTFITS, iar_data[i].offset );
   if (widget_exists(wid, EQUIPMENT_FILTER))
      window_setInput(wid, EQUIPMENT_FILTER, filtertext);

   /* Regenerate ship widget. */
   equipment_regenLists( wid, 0, 1 );

   /* Focus new ship. */
   toolkit_setImageArrayPos(    wid, EQUIPMENT_SHIPS, 0 );
   toolkit_setImageArrayOffset( wid, EQUIPMENT_SHIPS, 0. );
}



/**
 * @brief Unequips the player's ship.
 *
 *    @param wid Window id.
 *    @param str of widget.
 */
static void equipment_unequipShip( unsigned int wid, char* str )
{
   (void) str;
   int ret;
   int i;
   Pilot *ship;
   const Outfit *o, *ammo;

   ship = eq_wgt.selected;

   /*
    * Unequipping is disallowed under two conditions. Firstly, the ship may not
    * be unequipped when it has fighters deployed in space. Secondly, it cannot
    * unequip if it's carrying more cargo than the ship normally fits, i.e.
    * by equipping cargo pods.
    */
   for (i=0; i<array_size(ship->outfits); i++) {
      /* Must have outfit. */
      if (ship->outfits[i]->outfit == NULL)
         continue;
      /* Must be fighter bay. */
      if (!outfit_isFighterBay( ship->outfits[i]->outfit))
         continue;
      /* Must not have deployed fighters. */
      if (ship->outfits[i]->u.ammo.deployed > 0) {
         dialogue_alert( _("You can not unequip your ship while you have deployed fighters!") );
         return;
      }
   }
   if (pilot_cargoUsed( ship ) > ship->ship->cap_cargo) {
      dialogue_alert( _("You can not unequip your ship when you have more cargo than it can hold without modifications!") );
      return;
   }

   if (dialogue_YesNo(_("Unequip Ship"), /* confirm */
         _("Are you sure you want to remove all equipment from your ship?"))==0)
      return;

   /* Remove all outfits. */
   for (i=0; i<array_size(ship->outfits); i++) {
      o = ship->outfits[i]->outfit;

      /* Skip null outfits. */
      if (o==NULL)
         continue;

      /* Remove ammo first. */
      ammo = outfit_ammo(o);
      if (ammo != NULL) {
         pilot_rmAmmo( ship, ship->outfits[i], pilot_maxAmmoO(ship, o) );
      }

      /* Remove rest. */
      ret = pilot_rmOutfitRaw( ship, ship->outfits[i] );
      if (ret==0)
         equipment_playerAddOutfit( o, 1 );
   }

   /* Recalculate stats. */
   pilot_calcStats( ship );
   pilot_healLanded( ship );

   /* Regenerate list. */
   equipment_regenLists( wid, 1, 1 );

   /* Regenerate outfits. */
   outfits_updateEquipmentOutfits();

   /* Update weapon sets if needed. */
   if (ship->autoweap)
      pilot_weaponAuto( ship );
   pilot_weaponSafe( ship );

   /* Notify GUI of modification. */
   gui_setShip();
}
/**
 * @brief Player tries to sell a ship.
 *    @param wid Window player is selling ships in.
 *    @param str Unused.
 */
static void equipment_sellShip( unsigned int wid, char* str )
{
   (void)str;
   char *shipname;
   char buf[STRMAX_SHORT];
   char *name;
   credits_t price;
   Pilot *p;
   const Ship *s;
   HookParam hparam[3];

   shipname = toolkit_getImageArray( wid, EQUIPMENT_SHIPS );

   if (land_errDialogue( shipname, "sell" ))
      return;

   /* Calculate price. */
   price = player_shipPrice(shipname);
   credits2str(buf, sizeof(buf), price, 2);

   /* Check if player really wants to sell. */
   if (!dialogue_YesNo( _("Sell Ship"),
            _("Are you sure you want to sell your ship %s for %s? All"
               " equipped outfits will be sold along with it."),
            shipname, buf))
      return;

   /* Store ship type. */
   p = player_getShip( shipname );
   s = p->ship;

   /* Sold. */
   name = strdup(shipname);
   player_modCredits( price );
   player_rmShip( shipname );

   /* Destroy widget - must be before widget. */
   equipment_regenLists( wid, 0, 1 );

   /* Display widget. */
   dialogue_msg( _("Ship Sold"),
         _("You have sold your ship %s for %s."), name, buf );

   /* Run hook. */
   hparam[0].type    = HOOK_PARAM_STRING;
   hparam[0].u.str   = s->name;
   hparam[1].type    = HOOK_PARAM_STRING;
   hparam[1].u.str   = name;
   hparam[2].type    = HOOK_PARAM_SENTINEL;
   hooks_runParam( "ship_sell", hparam );
   if (land_takeoff)
      takeoff(1);
   free(name);
}
/**
 * @brief Player tries to sell an outfit.
 *    @param wid Window player is selling an outfit in.
 *    @param str Unused.
 */
static void equipment_sellOutfit( unsigned int wid, char* str )
{
   (void) str;
   char buf[STRMAX_SHORT];
   Outfit* o;
   int i, active, q;
   HookParam hparam[3];

   active = window_tabWinGetActive( wid, EQUIPMENT_OUTFIT_TAB );
   i = toolkit_getImageArrayPos( wid, EQUIPMENT_OUTFITS );

   /* Did the user click on background or placeholder cell? */
   if (i < 0 || iar_outfits[active] == NULL)
      return;

   o = iar_outfits[active][i];
   if (o == NULL)
      return;

   /* Check various failure conditions. */
   if (land_errDialogue( o->name, "sellOutfit" ))
      return;

   /* Calculate price. */
   credits2str(buf, sizeof(buf), o->price, 2);

   /* TODO: Would be nice to have a quantity choice. */
   q = 1;

   /* Check if player really wants to sell. */
   if (!dialogue_YesNo( _("Sell Outfit"),
            _("Are you sure you want to sell your %s for %s?"),
            _(o->name), buf))
      return;

   /* Destroy widget. */
   equipment_regenLists( wid, 1, 0 );

   player_modCredits( o->price * player_rmOutfit( o, q ) );
   outfits_updateEquipmentOutfits();
   hparam[0].type    = HOOK_PARAM_STRING;
   hparam[0].u.str   = o->name;
   hparam[1].type    = HOOK_PARAM_NUMBER;
   hparam[1].u.num   = q;
   hparam[2].type    = HOOK_PARAM_SENTINEL;
   hooks_runParam( "outfit_sell", hparam );
   if (land_takeoff)
      takeoff(1);
}


/**
 * @brief Renames the selected ship.
 *
 *    @param wid Parent window id.
 *    @param str Unused.
 */
static void equipment_renameShip( unsigned int wid, char *str )
{
   (void)str;
   Pilot *ship;
   char *shipname, *newname;

   shipname = toolkit_getImageArray( wid, EQUIPMENT_SHIPS );
   ship = player_getShip(shipname);
   newname = dialogue_input( _("Ship Name"), 1, 60,
         _("Please enter a new name for your %s:"), _(ship->ship->name) );

   /* Player cancelled the dialogue. */
   if (newname == NULL)
      return;

   /* Must not have same name. */
   if (player_hasShip(newname)) {
      if (strcmp(shipname, newname) != 0) {
         dialogue_msg( _("Name Collision"),
               _("Please do not give the ship the same name as another of your ships."));
      }
      free(newname);
      return;
   }

   free (ship->name);
   ship->name = newname;

   /* Destroy widget - must be before widget. */
   equipment_regenLists( wid, 0, 1 );
}


/**
 * @brief Wrapper to only add unique outfits.
 */
static int equipment_playerAddOutfit( const Outfit *o, int quantity )
{
   if (outfit_isProp(o,OUTFIT_PROP_UNIQUE) && (player_outfitOwned(o)>0))
      return 1;
   return player_addOutfit(o,quantity);
}


/**
 * @brief Wrapper to only remove unique outfits.
 */
static int equipment_playerRmOutfit( const Outfit *o, int quantity )
{
   if (outfit_isProp(o,OUTFIT_PROP_UNIQUE))
      return 1;
   return player_rmOutfit(o,quantity);
}


/**
 * @brief Cleans up after the equipment stuff.
 */
void equipment_cleanup (void)
{
   /* Free stored positions. */
   free(iar_data);
   iar_data = NULL;
   if (iar_outfits != NULL) {
      for (int i=0; i<OUTFIT_TABS; i++)
         free( iar_outfits[i] );
      free(iar_outfits);
      iar_outfits = NULL;
   }
}

