/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file player_gui.c
 *
 * @brief Handles the GUIs the player owns.
 */


/** @cond */
#include "physfs.h"
#include "physfsrwops.h"

#include "naev.h"
/** @endcond */

#include "player_gui.h"

#include "array.h"
#include "log.h"
#include "ndata.h"
#include "nstring.h"


static char** gui_list = NULL; /**< List of GUIs the player has. */


/**
 * @brief Initializes the player's GUI list.
 */
void player_guiInit(void)
{
   int i;
   char **gui_files;
   char *name, *ext;

   gui_files = PHYSFS_enumerateFiles(GUI_PATH);
   if (gui_files == NULL) {
      ERR(_("Failed to enumerate files in '%s'."), GUI_PATH);
      return;
   }

   gui_list = array_create(char*);
   for (i=0; gui_files[i]!=NULL; i++) {
      if (naev_pollQuit())
         break;

      name = gui_files[i];
      ext = strstr(name, ".lua");
      if ((ext != NULL) && (strcmp(ext, ".lua") == 0)) {
         /* ext is a substring of name, so this erases the ".lua" at the
          * end of name. */
         *ext = '\0';

#ifdef DEBUGGING
         /* Make sure the GUI is vaild. */
         SDL_RWops *rw;
         char buf[PATH_MAX];
         snprintf(buf, sizeof(buf), GUI_PATH"%s.lua", name);
         rw = PHYSFSRWOPS_openRead(buf);
         if (rw == NULL) {
            WARN(_("GUI '%s' does not exist as a file: '%s' not found."),
                  name, buf);
            return;
         }
         SDL_RWclose(rw);
#endif /* DEBUGGING */

         array_push_back(&gui_list, strdup(name));
      }
   }
   PHYSFS_freeList(gui_files);
   array_shrink(&gui_list);

   DEBUG(n_("Loaded %d GUI", "Loaded %d GUIs", array_size(gui_list)),
         array_size(gui_list));
}


/**
 * @brief Cleans up the player's GUI list.
 */
void player_guiCleanup (void)
{
   int i;
   for (i=0; i<array_size(gui_list); i++)
      free( gui_list[i] );
   array_free( gui_list );
   gui_list = NULL;
}


/**
 * @brief Adds a gui to the player.
 */
int player_guiAdd( char* name )
{
   /* Name must not be NULL. */
   if (name == NULL)
      return -1;

   /* Create new array. */
   if (gui_list == NULL)
      gui_list = array_create( char* );

   /* Check if already exists. */
   if (player_guiCheck(name))
      return 1;

#ifdef DEBUGGING
   /* Make sure the GUI is vaild. */
   SDL_RWops *rw;
   char buf[PATH_MAX];
   snprintf( buf, sizeof(buf), GUI_PATH"%s.lua", name );
   rw = PHYSFSRWOPS_openRead( buf );
   if (rw == NULL) {
      WARN(_("GUI '%s' does not exist as a file: '%s' not found."), name, buf );
      return -1;
   }
   SDL_RWclose(rw);
#endif /* DEBUGGING */

   /* Add. */
   array_push_back(&gui_list, strdup(name));
   return 0;
}


/**
 * @brief Removes a player GUI.
 */
void player_guiRm( char* name )
{
   (void) name;
   if (gui_list == NULL)
      return;
}


/**
 * @brief Check if player has a GUI.
 */
int player_guiCheck( char* name )
{
   int i;

   if (name == NULL)
      return 0;

   for (i=0; i<array_size(gui_list); i++)
      if (strcmp(gui_list[i], name)==0)
         return 1;

   return 0;
}


/**
 * @brief Gets the list of GUIs.
 */
char** player_guiList (void)
{
   return gui_list;
}

