/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file list.c
 *
 * @brief List widget.
 */


/** @cond */
#include <stdlib.h>
/** @endcond */

#include "nstring.h"
#include "tk/toolkit_priv.h"

#define CELLPADV 8
#define CELLHEIGHT (gl_smallFont.h + CELLPADV)


static void lst_render( Widget* lst, double bx, double by );
static int lst_key( Widget* lst, SDL_Keycode key, SDL_Keymod mod );
static int lst_mclick( Widget* lst, int button, int x, int y );
static int lst_mdoubleclick( Widget* lst, int button, int x, int y );
static int lst_mwheel( Widget* lst, SDL_MouseWheelEvent event );
static int lst_mmove( Widget* lst, int x, int y, int rx, int ry );
static void lst_cleanup( Widget* lst );

static Widget *lst_getWgt( const unsigned int wid, const char* name );
static int lst_focus( Widget* lst, double bx, double by );
static void lst_scroll( Widget* lst, int direction );


/**
 * @brief Adds a list widget to a window.
 *
 * Position origin is 0,0 at bottom left.  If you use negative X or Y
 *  positions.  They actually count from the opposite side in.
 *
 *    @param wid ID of the window to add the widget to.
 *    @param x X position within the window to use.
 *    @param y Y position within the window to use.
 *    @param w Width of the widget.
 *    @param h Height of the widget.
 *    @param name Name of the widget to use internally.
 *    @param items Items in the list (will be freed automatically).
 *    @param nitems Number of items in items parameter.
 *    @param defitem Default item to select.
 *    @param onSelect Function to call when new item is selected. Parameter passed
 *                is the name of the list.
 *    @param onActivate Function to call when selected item is double-clicked. Parameter passed
 *                is the name of the list.
 */
void window_addList( const unsigned int wid,
                     const int x, const int y,
                     const int w, const int h,
                     char* name, char **items, int nitems, int defitem,
                     void (*onSelect) (unsigned int wdw, char* wgtname),
                     void (*onActivate) (unsigned int wdw, char* wgtname) )
{
   Window *wdw = window_wget(wid);
   Widget *wgt = window_newWidget(wdw, name);
   if (wgt == NULL)
      return;

   /* generic */
   wgt->type   = WIDGET_LIST;

   /* specific */
   wgt->render             = lst_render;
   wgt->cleanup            = lst_cleanup;
   wgt_setFlag(wgt, WGT_FLAG_CANFOCUS);
   wgt->keyevent           = lst_key;
   wgt->mclickevent        = lst_mclick;
   wgt->mdoubleclickevent  = lst_mdoubleclick;
   wgt->mwheelevent        = lst_mwheel;
   wgt->mmoveevent         = lst_mmove;
   wgt->dat.lst.options    = items;
   wgt->dat.lst.noptions   = nitems;
   wgt->dat.lst.selected   = defitem; /* -1 would be none */
   wgt->dat.lst.pos        = 0;
   wgt->dat.lst.onSelect   = onSelect;
   wgt->dat.lst.onActivate = onActivate;

   /* position/size */
   wgt->w = (double) w;
   wgt->h = (double) h - (h-2) % CELLHEIGHT;
   toolkit_setPos( wdw, wgt, x, y );

   /* check if needs scrollbar. */
   if (2 + nitems*CELLHEIGHT > (int)wgt->h)
      wgt->dat.lst.height = nitems*CELLHEIGHT;
   else
      wgt->dat.lst.height = 0;

   if (wdw->focus == -1) /* initialize the focus */
      toolkit_nextFocus( wdw );

   lst_scroll( wgt, 0 ); /* checks boundaries and triggers callback */
   if (defitem >= 0 && onSelect)
      onSelect(wid, name);
}


/**
 * @brief Renders a list widget.
 *
 *    @param lst List widget to render.
 *    @param bx Base X position.
 *    @param by Base Y position.
 */
static void lst_render( Widget* lst, double bx, double by )
{
   int i;
   double x,y, tx,ty, miny;
   double w, scroll_pos;

   w = lst->w;
   x = bx + lst->x;
   y = by + lst->y;

   /* If this list is a pop-up menu, we may be on top of previously drawn text. */
   glClear( GL_DEPTH_BUFFER_BIT );
   /* lst bg */
   toolkit_drawRect( x, y, lst->w, lst->h, &cBlack, NULL );

   /* inner outline */
   toolkit_drawOutline( x, y, lst->w, lst->h, 0., toolkit_colLight, NULL );
   /* outer outline */
   toolkit_drawOutline( x, y, lst->w, lst->h, 1., toolkit_colDark, NULL );

   /* Draw scrollbar. */
   if (lst->dat.lst.height > 0) {
      /* We need to make room for list. */
      w -= 11.;

      scroll_pos = (double)(lst->dat.lst.pos * CELLHEIGHT) / (lst->dat.lst.height - lst->h + 2);
      toolkit_drawScrollbar( x + lst->w - 12. + 1, y, 12., lst->h, scroll_pos );
   }

   /* draw selected item background */
   ty = y - 1 + lst->h - (1 + lst->dat.lst.selected - lst->dat.lst.pos)*CELLHEIGHT;
   if (ty > y && ty < y+lst->h-CELLHEIGHT)
      toolkit_drawRect(x + 1, ty, w - 2, CELLHEIGHT, toolkit_colHilight, NULL);

   /* draw content */
   tx = x + 6.;
   w -= 4;
   ty = y + lst->h - CELLPADV/2 - gl_smallFont.h;
   miny = y;
   for (i=lst->dat.lst.pos; i<lst->dat.lst.noptions; i++) {
      gl_printMaxRaw( &gl_smallFont, w,
            tx, ty, &cFontWhite, -1., lst->dat.lst.options[i] );
      ty -= CELLHEIGHT;

      /* Check if out of bounds. */
      if (ty + 2 < miny)
         break;
   }
}


/**
 * @brief Handles input for a list widget.
 *
 *    @param lst List widget to handle event.
 *    @param key Key being handled.
 *    @param mod Mods when key is being pressed.
 *    @return 1 if the event was used, 0 if it wasn't.
 */
static int lst_key( Widget* lst, SDL_Keycode key, SDL_Keymod mod )
{
   (void) mod;

   switch (key) {
      case SDLK_UP:
         lst_scroll( lst, +1 );
         return 1;
      case SDLK_DOWN:
         lst_scroll( lst, -1 );
         return 1;
      case SDLK_HOME:
         lst_scroll( lst, +(lst->dat.lst.noptions) );
         return 1;
      case SDLK_END:
         lst_scroll( lst, -(lst->dat.lst.noptions) );
         return 1;
      case SDLK_PAGEUP:
         lst_scroll( lst, +8);
         return 1;
      case SDLK_PAGEDOWN:
         lst_scroll( lst, -8);
         return 1;

      default:
         break;
   }

   return 0;
}


/**
 * @brief Handler for mouse single-click events for the list widget.
 *
 *    @param lst The widget handling the mouse click event.
 *    @param mclick The event the widget should handle.
 *    @return 1 if the widget uses the event.
 */
static int lst_mclick( Widget* lst, int button, int x, int y )
{
   switch (button) {
      case SDL_BUTTON_LEFT:
         lst_focus( lst, x, y );
         return 1;

      default:
         break;
   }
   return 0;
}


/**
 * @brief Handler for mouse double-click events for the list widget.
 *
 *    @param lst The widget handling the mouse click event.
 *    @param mclick The event the widget should handle.
 *    @return 1 if the widget uses the event.
 */
static int lst_mdoubleclick( Widget* lst, int button, int x, int y )
{
   int prev_selected;
   prev_selected = lst->dat.lst.selected;
   if (lst_mclick( lst, button, x, y ) == 0)
      return 0;
   if (lst->dat.lst.selected != prev_selected)
      return 1;

   if (lst->dat.lst.onActivate != NULL)
      lst->dat.lst.onActivate( lst->wdw, lst->name );
   return 1;
}


/**
 * @brief Handler for mouse wheel events for the list widget.
 *
 *    @param lst The widget handling the mouse wheel event.
 *    @param event The event the widget should handle.
 *    @return 1 if the widget uses the event.
 */
static int lst_mwheel( Widget* lst, SDL_MouseWheelEvent event )
{
   if (event.y > 0)
      lst_scroll( lst, +1 );
   else if (event.y < 0)
      lst_scroll( lst, -1 );

   return 1;
}


/**
 * @brief Handles a mouse click focusing on widget.
 *
 *    @param lst Widget to focus.
 *    @param bx Base x click.
 *    @param by Base y click.
 *    @return 1 if event was used.
 */
static int lst_focus( Widget* lst, double bx, double by )
{
   int i;
   double y, w;
   double scroll_pos;

   /* Get the actual width. */
   w = lst->w;
   if (lst->dat.lst.height > 0)
      w -= 10.;

   if (bx < w) {
      i = lst->dat.lst.pos + (lst->h - by) / CELLHEIGHT;
      if (i < lst->dat.lst.noptions) { /* shouldn't be out of boundaries */
         lst->dat.lst.selected = i;
         lst_scroll( lst, 0 ); /* checks boundaries and triggers callback */
      }
   }
   else {
      /* Get bar position (center). */
      scroll_pos = (double)(lst->dat.lst.pos * CELLHEIGHT) / (lst->dat.lst.height - lst->h + 2);
      y = (lst->h - 30.) * (1.-scroll_pos) + 15.;

      /* Click below the bar. */
      if (by < y-15.)
         lst_scroll( lst, -5 );
      /* Click above the bar. */
      else if (by > y+15.)
         lst_scroll( lst, +5 );
      /* Click on the bar. */
      else
         lst->status = WIDGET_STATUS_SCROLLING;
   }

   return 1;
}


/**
 * @brief Handles List movement.
 *
 *    @param lst List that has mouse movement.
 *    @param mmove Mouse movement event.
 *    @return 1 if movement was used, 0 if movement wasn't used.
 */
static int lst_mmove( Widget* lst, int x, int y, int rx, int ry )
{
   (void) x;
   (void) rx;
   (void) ry;
   double p;

   /* Handle the scrolling if scrolling. */
   if (lst->status == WIDGET_STATUS_SCROLLING) {
      /* Make sure Y inbounds. */
      y = CLAMP( 15., lst->h-15., lst->h - y );

      /* Find absolute position. */
      p  = (y - 15. ) / (lst->h - 30.) * (lst->dat.lst.height - lst->h);
      p /= CELLHEIGHT;
      lst->dat.lst.pos = CLAMP( 0, lst->dat.lst.noptions, (int)ceil(p) );

      return 1;
   }

   return 0;
}


/**
 * @brief Clean up function for the list widget.
 *
 *    @param lst List widget to clean up.
 */
static void lst_cleanup( Widget* lst )
{
   int i;

   if (lst->dat.lst.options) {
      for (i=0; i<lst->dat.lst.noptions; i++)
         if (lst->dat.lst.options[i])
            free(lst->dat.lst.options[i]);
      free( lst->dat.lst.options );
   }
}


/**
 * @brief Scrolls a list widget up/down.
 *
 *    @param lst List to scroll.
 *    @param direction Direction to scroll.  Positive is up, negative
 *           is down and absolute value is number of elements to scroll.
 */
static void lst_scroll( Widget* lst, int direction )
{
   int pos;

   if (lst == NULL)
      return;

   lst->dat.lst.selected -= direction;

   /* boundary check. */
   lst->dat.lst.selected = CLAMP(0, lst->dat.lst.noptions - 1,
         lst->dat.lst.selected);

   /* see if we have to scroll. */
   pos = (lst->dat.lst.selected - lst->dat.lst.pos);
   if (pos < 0) {
      lst->dat.lst.pos += pos;
      if (lst->dat.lst.pos < 0)
         lst->dat.lst.pos = 0;
   }
   else if (CELLPADV + (pos+1) * CELLHEIGHT > lst->h)
      lst->dat.lst.pos += (CELLPADV + (pos+1) * CELLHEIGHT - lst->h) / CELLHEIGHT;

   if (lst->dat.lst.onSelect)
      lst->dat.lst.onSelect( lst->wdw, lst->name );
}


/**
 * @brief Gets the list widget.
 */
static Widget *lst_getWgt( const unsigned int wid, const char* name )
{
   Widget *wgt = window_getwgt(wid,name);

   /* Must be in stack. */
   if (wgt == NULL) {
      WARN("Widget '%s' not found", name);
      return NULL;
   }

   /* Must be a list. */
   if (wgt->type != WIDGET_LIST) {
      WARN("Widget '%s' is not a list", name);
      return NULL;
   }

   return wgt;
}


/**
 * @brief Gets what is selected currently in a list.
 *
 * List includes Image Arrays.
 *
 *   \warning Oftentimes, UI code will translate or otherwise preprocess
 *            text before populating this widget.
 *            In general, reading back such processed text and trying to
 *            interpret it is ill-advised; it's better to keep the original
 *            list of objects being presented and deal with indices into it.
 *            \see toolkit_getListPos
 *
 */
char* toolkit_getList( const unsigned int wid, const char* name )
{
   Widget *wgt = lst_getWgt( wid, name );
   if (wgt == NULL)
      return NULL;

   /* Nothing selected. */
   if (wgt->dat.lst.selected == -1)
      return NULL;

   /* Nothing that can be selected. */
   if (wgt->dat.lst.noptions<=0)
      return NULL;

   return wgt->dat.lst.options[ wgt->dat.lst.selected ];
}


/**
 * @brief Sets the list value by name.
 *
 *   \warning If the captions have been translated or otherwise preprocessed,
 *            this function can only find a name that has been transformed the
 *            same way. There may be a more robust solution involving indices.
 *            \see toolkit_setListPos
 */
char* toolkit_setList( const unsigned int wid, const char* name, char* value )
{
   int i;
   Widget *wgt = lst_getWgt( wid, name );
   if ((wgt == NULL) || (value==NULL))
      return NULL;

   for (i=0; i<wgt->dat.lst.noptions; i++) {
      if (strcmp(wgt->dat.lst.options[i],value)==0) {
         wgt->dat.lst.selected = i;
         lst_scroll( wgt, 0 ); /* checks boundaries and triggers callback */
         return value;
      }
   }

   return NULL;
}


/**
 * @brief Sets the list value by position.
 */
char* toolkit_setListPos( const unsigned int wid, const char* name, int pos )
{
   Widget *wgt = lst_getWgt( wid, name );
   if (wgt == NULL)
      return NULL;

   /* Set by pos. */
   wgt->dat.lst.selected = CLAMP( 0, wgt->dat.lst.noptions-1, pos );
   lst_scroll( wgt, 0 ); /* checks boundaries and triggers callback */
   return wgt->dat.lst.options[ wgt->dat.lst.selected ];
}


/**
 * @brief Get the position of current item in the list.
 *
 *    @param wid Window identifier where the list is.
 *    @param name Name of the list.
 *    @return The position in the list or -1 on error.
 */
int toolkit_getListPos( const unsigned int wid, const char* name )
{
   Widget *wgt = lst_getWgt( wid, name );
   if (wgt == NULL)
      return -1;

   return wgt->dat.lst.selected;
}


/**
 * @brief Gets the offset of a list.
 */
int toolkit_getListOffset( const unsigned int wid, const char* name )
{
   Widget *wgt = lst_getWgt( wid, name );
   if (wgt == NULL)
      return -1;

   return wgt->dat.lst.pos;
}


/**
 * @brief Sets the offset of a list.
 */
int toolkit_setListOffset( const unsigned int wid, const char* name, int off )
{
   int max;
   Widget *wgt = lst_getWgt(wid, name);

   if (wgt == NULL)
      return -1;

   /* wgt->dat.lst.noptions is 0 if there is no scrollbar, so we need to
    * specifically account for that. */
   max = MAX(0, wgt->dat.lst.noptions - (int)(wgt->h/CELLHEIGHT));
   wgt->dat.lst.pos = CLAMP(0, max, off);

   return 0;
}



