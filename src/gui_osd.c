/*
 * See Licensing and Copyright notice in naev.h
 */


/** @cond */
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "gui_osd.h"

#include "array.h"
#include "font.h"
#include "log.h"
#include "mission.h"
#include "nstring.h"
#include "opengl.h"
#include "space.h"


/**
 * @brief On Screen Display element.
 */
typedef struct OSD_s {
   Mission *misn; /**< Mission which owns the OSD. */

   osdId_t id; /**< OSD id. */
   int priority; /**< Priority level. */
   char *title; /**< Title of the OSD. */

   char **msg; /**< Array (array.h): Stored messages. */
   char ***items; /**< Array of array (array.h) of allocated strings. */

   unsigned int active; /**< Active item. */
} OSD_t;


/*
 * OSD array.
 */
static osdId_t osd_idgen = 0; /**< ID generator for OSD. */
static OSD_t *osd_list        = NULL; /**< Array (array.h) for OSD. */


/*
 * Dimensions.
 */
static int osd_x = 0;
static int osd_y = 0;
static int osd_w = 0;
static int osd_h = 0;
static int osd_lines = 0;
static int osd_rh = 0;
static int osd_tabLen = 0;
static int osd_hyphenLen = 0;
static int osd_abbreviated = 0;


/*
 * Prototypes.
 */
static OSD_t *osd_get(osdId_t osd);
static int osd_free(OSD_t *osd);
static void osd_calcDimensions(int abbreviate);
/* Sort. */
static int osd_sortCompare(const void * arg1, const void * arg2);
static void osd_sort(void);
static void osd_wordwrap(OSD_t* osd);


static int osd_sortCompare( const void *arg1, const void *arg2 )
{
   const OSD_t *osd1, *osd2;
   int ret, i, m;

   osd1 = (OSD_t*)arg1;
   osd2 = (OSD_t*)arg2;

   /* Compare priority. */
   if (osd1->priority > osd2->priority)
      return +1;
   else if (osd1->priority < osd2->priority)
      return -1;

   /* Compare name. */
   ret = strcmp( osd1->title, osd2->title );
   if (ret != 0)
      return ret;

   /* Compare items. */
   m = MIN(array_size(osd1->items), array_size(osd2->items));
   for (i=0; i<m; i++) {
      ret = strcmp( osd1->msg[i], osd2->msg[i] );
      if (ret != 0)
         return ret;
   }

   /* Compare on length. */
   if (array_size(osd1->items) > array_size(osd2->items))
      return +1;
   if (array_size(osd1->items) < array_size(osd2->items))
      return -1;

   /* Compare ID. */
   if (osd1->id > osd2->id)
      return +1;
   else if (osd1->id < osd2->id)
      return -1;
   return 0;
}


/**
 * @brief Sorts the OSD list.
 */
static void osd_sort (void)
{
   qsort( osd_list, array_size(osd_list), sizeof(OSD_t), osd_sortCompare );
}


/**
 * @brief Creates an on-screen display.
 *
 *    @param title Title of the display.
 *    @param nitems Number of items in the display.
 *    @param items Items in the display.
 *    @return ID of newly created OSD.
 */
osdId_t osd_create(Mission *misn, const char *title, int nitems,
      const char **items, int priority)
{
   int i, id;
   OSD_t *osd;

   /* Create. */
   if (osd_list == NULL)
      osd_list = array_create( OSD_t );
   osd = &array_grow( &osd_list );
   memset( osd, 0, sizeof(OSD_t) );
   osd->id = id = ++osd_idgen;
   osd->active = 0;

   /* Copy data. */
   osd->misn = misn;
   osd->title = strdup(title);
   osd->priority = priority;
   osd->msg = array_create_size(char*, nitems);
   osd->items = array_create_size(char**, nitems);
   for (i=0; i<nitems; i++) {
      array_push_back( &osd->msg, strdup( items[i] ) );
      array_push_back( &osd->items, array_create(char*) );
   }

   osd_wordwrap( osd );
   osd_sort(); /* THIS INVALIDATES THE osd POINTER. */
   osd_calcDimensions(0);

   return id;
}


/**
 * @brief Calculates the word-wrapped osd->items from osd->msg.
 */
void osd_wordwrap( OSD_t* osd )
{
   int i, l, msg_len, w, has_tab, chunk_len;
   char *chunk;
   const char *chunk_fmt;
   glPrintLineIterator iter;

   for (i=0; i<array_size(osd->items); i++) {
      for (l=0; l<array_size(osd->items[i]); l++)
         free(osd->items[i][l]);
      array_resize( &osd->items[i], 0 );

      msg_len = strlen(osd->msg[i]);
      if (msg_len == 0)
         continue;

      /* Test if tabbed. */
      has_tab = !!(osd->msg[i][0] == '\t');
      w = osd_w - (has_tab ? osd_tabLen + osd_hyphenLen : osd_hyphenLen);
      gl_printLineIteratorInit( &iter, &gl_smallFont, &osd->msg[i][has_tab], w );
      chunk_fmt = has_tab ? "   - %s" : "- %s";

      while (gl_printLineIteratorNext( &iter )) {
         /* Copy text over. */
         chunk_len = iter.l_end - iter.l_begin + strlen( chunk_fmt ) - 1;
         chunk = malloc( chunk_len );
         snprintf( chunk, chunk_len, chunk_fmt, &iter.text[iter.l_begin] );
         array_push_back( &osd->items[i], chunk );
         chunk_fmt = has_tab ? "   %s" : "%s";
         iter.width = has_tab ? osd_w - osd_tabLen - osd_hyphenLen : osd_w - osd_hyphenLen;
      }
   }
}


/**
 * @brief Gets an OSD by ID.
 *
 *    @param osd ID of the OSD to get.
 */
static OSD_t *osd_get(osdId_t osd)
{
   int i;
   OSD_t *ll;

   for (i=0; i<array_size(osd_list); i++) {
      ll = &osd_list[i];
      if (ll->id == osd)
         return ll;
   }

   WARN(_("OSD '%d' not found."), osd);
   return NULL;
}


/**
 * @brief Frees an OSD struct.
 */
static int osd_free( OSD_t *osd )
{
   int i, j;

   free(osd->title);

   for (i=0; i<array_size(osd->items); i++) {
      free( osd->msg[i] );
      for (j=0; j<array_size(osd->items[i]); j++)
         free(osd->items[i][j]);
      array_free(osd->items[i]);
   }
   array_free(osd->msg);
   array_free(osd->items);

   return 0;
}


/**
 * @brief Destroys an OSD.
 *
 *    @param osd ID of the OSD to destroy.
 */
int osd_destroy(osdId_t osd)
{
   int i;
   OSD_t *ll;

   for (i=0; i<array_size( osd_list ); i++) {
      ll = &osd_list[i];
      if (ll->id != osd)
         continue;

      /* Clean up. */
      osd_free( &osd_list[i] );

      /* Remove. */
      array_erase( &osd_list, &osd_list[i], &osd_list[i+1] );

      /* Recalculate dimensions. */
      osd_calcDimensions(0);

      /* Remove the OSD, if empty. */
      if (array_size(osd_list) == 0)
         osd_exit();

      /* Done here. */
      return 0;
   }

   WARN(_("OSD '%u' not found to destroy."), osd);
   return 0;
}


/**
 * @brief Makes an OSD message active.
 *
 *    @param osd OSD to change active message.
 *    @param msg Message to make active in OSD.
 *    @return 0 on success.
 */
int osd_active(osdId_t osd, int msg)
{
   OSD_t *o;

   o = osd_get(osd);
   if (o == NULL)
      return -1;

   if ((msg < 0) || (msg >= array_size(o->items))) {
      WARN(_("OSD '%s' only has %d items (requested %d)"), o->title, array_size(o->items), msg );
      return -1;
   }

   o->active = msg;
   osd_calcDimensions(0);
   return 0;
}


/**
 * @brief Gets the active OSD message.
 *
 *    @param osd OSD to get active message.
 *    @return The active OSD message or -1 on error.
 */
int osd_getActive(osdId_t osd)
{
   OSD_t *o;

   o = osd_get(osd);
   if (o == NULL)
      return -1;

   return o->active;
}


/**
 * @brief Sets up the OSD window.
 *
 *    @param x X position to render at.
 *    @param y Y position to render at.
 *    @param w Width to render.
 *    @param h Height to render.
 */
int osd_setup( int x, int y, int w, int h )
{
   int i, must_rewrap;
   /* Set offsets. */
   must_rewrap = (osd_w != w) && (osd_list != NULL);
   osd_x = x;
   osd_y = y;
   osd_w = w;
   osd_lines = h / (gl_smallFont.h+5);
   osd_h = h - h % (gl_smallFont.h+5);

   /* Calculate some font things. */
   osd_tabLen = gl_printWidthRaw( &gl_smallFont, "   " );
   osd_hyphenLen = gl_printWidthRaw( &gl_smallFont, "- " );

   if (must_rewrap)
      for (i=0; i<array_size(osd_list); i++)
         osd_wordwrap( &osd_list[i] );
   osd_calcDimensions(0);

   return 0;
}


/**
 * @brief Destroys all the OSD.
 */
void osd_exit (void)
{
   int i;
   OSD_t *ll;

   for (i=0; i<array_size(osd_list); i++) {
      ll = &osd_list[i];
      osd_free( ll );
   }

   array_free( osd_list );
   osd_list = NULL;
}


/**
 * @brief Renders all the OSD.
 */
void osd_render (void)
{
   OSD_t *ll;
   double p;
   int i, j, k, l, m;
   int w;
   int x;
   const glColour *c;
   const glColour *active_c;
   int is_sub_active;
   int *ignore;
   int nignore;
   int is_duplicate, duplicates;
   char title[STRMAX_SHORT];

   /* Nothing to render. */
   if (osd_list == NULL)
      return;

   nignore = array_size(osd_list);
   ignore  = calloc( nignore, sizeof( int ) );

   /* Background. */
   gl_renderRect(osd_x-5., osd_y-(osd_rh+5.), osd_w+10., osd_rh+10,
         &cTransBack);

   /* Render each thingy. */
   p = osd_y + 5.;
   l = 0;
   for (k=0; k<array_size(osd_list); k++) {
      if (ignore[k])
         continue;

      ll = &osd_list[k];
      x = osd_x;
      w = osd_w;

      /* Check how many duplicates we have, mark duplicates for ignoring */
      duplicates = 0;
      for (m=k+1; m<array_size(osd_list); m++) {
         if ((strcmp(osd_list[m].title, ll->title) == 0) &&
               (array_size(osd_list[m].items) == array_size(ll->items)) &&
               (osd_list[m].active == ll->active)) {
            is_duplicate = 1;
            for (i=osd_list[m].active; i<array_size(osd_list[m].items); i++) {
               if (array_size(osd_list[m].items[i]) == array_size(ll->items[i])) {
                  for (j=0; j<array_size(osd_list[m].items[i]); j++) {
                     if (strcmp(osd_list[m].items[i][j], ll->items[i][j]) != 0 ) {
                        is_duplicate = 0;
                        break;
                     }
                  }
               } else {
                  is_duplicate = 0;
               }
               if (!is_duplicate)
                  break;
            }
            if (is_duplicate) {
               duplicates++;
               ignore[m] = 1;
            }
         }
      }

      /* Print title. */
      if (duplicates > 0)
         snprintf(title, sizeof(title), "%s (%d)", ll->title, duplicates + 1);
      else {
         strncpy(title, ll->title, sizeof(title) - 1);
         title[sizeof(title) - 1] = '\0';
      }
      p -= gl_smallFont.h + 5.;
      gl_printMaxRaw(&gl_smallFont, w, x, p, NULL, -1., title);
      l++;
      if (l >= osd_lines) {
         free(ignore);
         return;
      }

      /* Choose active color: if the player is in its destination
       * system, we choose a special hilight color; otherwise, hilight
       * in white. */
      active_c = &cFontWhite;
      for (i=0; i<array_size(ll->misn->markers); i++) {
         if (ll->misn->markers[i].sys == cur_system->id) {
            active_c = &cFontOrange;
            break;
         }
      }

      /* Print items. */
      is_sub_active = 0;
      for (i=ll->active; i<array_size(ll->items); i++) {
         if (is_sub_active && (ll->msg[i][0] != '\t'))
            is_sub_active = 0;

         if (osd_abbreviated && !is_sub_active && (i != (int)ll->active))
            break;

         x = osd_x;
         w = osd_w;
         c = &cFontGrey;
         if (is_sub_active || (i == (int)ll->active)) {
            c = active_c;
            /* If this is an untabbed entry, set a flag so tabbed
             * entries underneath it also get hilighted and don't get
             * hidden. */
            if (ll->msg[i][0] != '\t')
               is_sub_active = 1;
         }

         for (j=0; j<array_size(ll->items[i]); j++) {
            p -= gl_smallFont.h + 5.;
            gl_printMaxRaw( &gl_smallFont, w, x, p,
                  c, -1., ll->items[i][j] );
            if (j==0) {
               w = osd_w - osd_hyphenLen;
               x = osd_x + osd_hyphenLen;
            }
            l++;
            if (l >= osd_lines) {
               free(ignore);
               return;
            }
         }
      }
   }

   free(ignore);
}


/**
 * @brief Calculates and sets the length of the OSD.
 *
 *    @param abbrevate Whether to set the OSD to abbreviate mode.
 */
static void osd_calcDimensions(int abbreviate)
{
   OSD_t *ll;
   int i, j, k, m;
   double len;
   int *ignore;
   int nignore;
   int is_duplicate;

   /* Nothing to render. */
   if (osd_list == NULL)
      return;

   osd_abbreviated = abbreviate;

   nignore = array_size(osd_list);
   ignore  = calloc( nignore, sizeof( int ) );

   /* Render each thingy. */
   len = 0;
   for (k=0; k<array_size(osd_list); k++) {
      if (ignore[k])
         continue;

      ll = &osd_list[k];

      /* Mark duplicates for ignoring */
      for (m=k+1; m<array_size(osd_list); m++) {
         if ((strcmp(osd_list[m].title, ll->title) == 0) &&
               (array_size(osd_list[m].items) == array_size(ll->items)) &&
               (osd_list[m].active == ll->active)) {
            is_duplicate = 1;
            for (i=osd_list[m].active; i<array_size(osd_list[m].items); i++) {
               if (array_size(osd_list[m].items[i]) == array_size(ll->items[i])) {
                  for (j=0; j<array_size(osd_list[m].items[i]); j++) {
                     if (strcmp(osd_list[m].items[i][j], ll->items[i][j]) != 0 ) {
                        is_duplicate = 0;
                        break;
                     }
                  }
               } else {
                  is_duplicate = 0;
               }
               if (!is_duplicate)
                  break;
            }
            if (is_duplicate) {
               ignore[m] = 1;
            }
         }
      }

      /* Print title. */
      len += gl_smallFont.h + 5.;

      /* Print items. */
      for (i=ll->active; i<array_size(ll->items); i++) {
         for (j=0; j<array_size(ll->items[i]); j++) {
            len += gl_smallFont.h + 5.;
         }
         if (osd_abbreviated)
            break;
      }
   }
   if (len <= osd_h) {
      /* OSD is shorter than max height. */
      osd_rh = len;
   }
   else {
      if (abbreviate)
         /* If already in abbreviated mode, set OSD hight to max. */
         osd_rh = osd_h;
      else
         /* Calculate abbreviated dimensions. */
         osd_calcDimensions(1);
   }
   free(ignore);
}


/**
 * @brief Gets the title of an OSD.
 *
 *    @param osd OSD to get title of.
 *    @return Title of the OSD.
 */
char *osd_getTitle(osdId_t osd)
{
   OSD_t *o;

   o = osd_get(osd);
   if (o == NULL)
      return NULL;

   return o->title;
}


/**
 * @brief Gets the items of an OSD.
 *
 *    @param osd OSD to get items of.
 *    @return Array (array.h) of OSD strings.
 */
char **osd_getItems(osdId_t osd)
{
   OSD_t *o;

   o = osd_get(osd);
   if (o == NULL)
      return NULL;
   return o->msg;
}


