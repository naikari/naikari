/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file save.c
 *
 * @brief Handles saving/loading games.
 */

/** @cond */
#include <errno.h>
#include "physfs.h"

#include "naev.h"
/** @endcond */

#include "save.h"

#include "conf.h"
#include "dialogue.h"
#include "event.h"
#include "gui.h"
#include "hook.h"
#include "land.h"
#include "load.h"
#include "log.h"
#include "menu.h"
#include "news.h"
#include "ndata.h"
#include "nfile.h"
#include "nlua_var.h"
#include "nstring.h"
#include "nxml.h"
#include "player.h"
#include "shiplog.h"
#include "start.h"
#include "unidiff.h"

int save_loaded   = 0; /**< Just loaded the saved game. */


/*
 * prototypes
 */
/* externs */
/* player.c */
extern int player_save( xmlTextWriterPtr writer ); /**< Saves player related stuff. */
/* event.c */
extern int events_saveActive( xmlTextWriterPtr writer );
/* news.c */
extern int news_saveArticles( xmlTextWriterPtr writer );
/* nlua_var.c */
extern int var_save( xmlTextWriterPtr writer ); /**< Saves mission variables. */
/* faction.c */
extern int pfaction_save( xmlTextWriterPtr writer ); /**< Saves faction data. */
/* hook.c */
extern int hook_save( xmlTextWriterPtr writer ); /**< Saves hooks. */
/* space.c */
extern int space_sysSave( xmlTextWriterPtr writer ); /**< Saves the space stuff. */
/* unidiff.c */
extern int diff_save( xmlTextWriterPtr writer ); /**< Saves the universe diffs. */
/* static */
static int save_data( xmlTextWriterPtr writer );


/**
 * @brief Saves all the player's game data.
 *
 *    @param writer XML writer to use.
 *    @return 0 on success.
 */
static int save_data( xmlTextWriterPtr writer )
{
   /* the data itself */
   if (diff_save(writer) < 0) return -1; /* Must save first or can get cleared. */
   if (player_save(writer) < 0) return -1;
   if (missions_saveActive(writer) < 0) return -1;
   if (events_saveActive(writer) < 0) return -1;
   if (news_saveArticles( writer ) < 0) return -1;
   if (var_save(writer) < 0) return -1;
   if (pfaction_save(writer) < 0) return -1;
   if (hook_save(writer) < 0) return -1;
   if (space_sysSave(writer) < 0) return -1;
   if (shiplog_save(writer) < 0) return -1;
   return 0;
}


/**
 * @brief Saves the current game.
 *
 *    @return 0 on success.
 */
int save_all (void)
{
   char file[PATH_MAX], buf[PATH_MAX];
   xmlDocPtr doc;
   xmlTextWriterPtr writer;
   int ret;
   int written;

   /* Do not save if saving is off. */
   if (player_isFlag(PLAYER_NOSAVE))
      return 0;

   /* Create the writer. */
   writer = xmlNewTextWriterDoc(&doc, 0);
   if (writer == NULL) {
      ERR(_("testXmlwriterDoc: Error creating the xml writer"));
      return -1;
   }

   ret = 0;

   /* Set the writer parameters. */
   xmlw_setParams(writer);

   /* Start element. */
   xmlw_start(writer);
   xmlw_startElem(writer,"naev_save");

   /* Save the version and such. */
   xmlw_startElem(writer,"version");
   xmlw_elem(writer, "naev", "%s", VERSION);
   xmlw_elem(writer, "data", "%s", start_name());
   xmlw_elem(writer, "player_name", "%s", player.name);
   xmlw_elem(writer, "annotation", "%s", player.name);
   xmlw_endElem(writer); /* "version" */

   /* Save last played. */
   xmlw_saveTime( writer, "last_played", time(NULL) );

   /* Save the data. */
   if (save_data(writer) < 0) {
      ERR(_("Trying to save game data"));
      ret = -1;
      goto exit;
   }

   /* Finish element. */
   xmlw_endElem(writer); /* "naev_save" */
   xmlw_done(writer);

   /* Write to file. */
   if (PHYSFS_mkdir("saves") == 0) {
      snprintf(file, sizeof(file), "%s/saves", PHYSFS_getWriteDir());
      WARN(_("Dir '%s' does not exist and unable to create: %s"), file,
            PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode()));
      ret = -1;
      goto exit;
   }
   str2filename(buf, sizeof(buf), player.name);
   written = snprintf(file, sizeof(file), "saves/%s.ns", buf);
   if (written < 0) {
      WARN(_("Error writing save file name."));
      goto exit;
   }
   else if (written >= (int)sizeof(file))
      WARN(_("Save file name was truncated: %s"), file);

   /* Back up old saved game. */
   if (!save_loaded) {
      if (ndata_backupIfExists(file) < 0) {
         WARN(_("Aborting save..."));
         ret = -1;
         goto exit;
      }
   }
   save_loaded = 0;

   /* Critical section, if crashes here player's game gets corrupted.
    * Luckily we have a copy just in case... */
   /* TODO: write via physfs */
   written = snprintf(file, sizeof(file), "%s/saves/%s.ns",
         PHYSFS_getWriteDir(), buf);
   if (written < 0) {
      WARN(_("Error writing save file name."));
      goto exit;
   }
   else if (written >= (int)sizeof(file))
      WARN(_("Save file name was truncated: %s"), file);

   if (xmlSaveFileEnc(file, doc, "UTF-8") < 0) {
      WARN(_("Failed to write saved game! You'll most likely have to"
            " restore it by copying your backup saved game over your"
            " current saved game."));
      ret = -1;
   }

exit:
   xmlFreeTextWriter(writer);
   xmlFreeDoc(doc);

   return ret;
}


/**
 * @brief Saves data to a snapshot file.
 *
 *    @param annotation The annotation to give the snapshot. Caller must
 *       prompt the user if it will replace existing data.
 *    @return 0 on success.
 */
int save_snapshot(const char *annotation)
{
   char buf[PATH_MAX], buf2[PATH_MAX];
   char *snapfile;
   char *path;
   xmlDocPtr doc;
   xmlTextWriterPtr writer;
   int ret;

   /* Do not save if saving is off. */
   if (player_isFlag(PLAYER_NOSAVE)) {
      WARN("%s", _("Attempted to save snapshot when saving is not allowed."));
      return 0;
   }

   /* Create the writer. */
   writer = xmlNewTextWriterDoc(&doc, 0);
   if (writer == NULL) {
      ERR(_("testXmlwriterDoc: Error creating the xml writer"));
      return -1;
   }

   /* path and snapfile need to be NULL by default in case we exit
    * without using asprintf (otherwise we'd call free() on an arbitrary
    * location and cause problems). */
   ret = 0;
   snapfile = NULL;
   path = NULL;

   /* Set the writer parameters. */
   xmlw_setParams(writer);

   /* Start element. */
   xmlw_start(writer);
   xmlw_startElem(writer, "naev_save");

   /* Save the version and such. */
   xmlw_startElem(writer,"version");
   xmlw_elem(writer, "naev", "%s", VERSION);
   xmlw_elem(writer, "data", "%s", start_name());
   xmlw_elem(writer, "player_name", "%s", player.name);
   xmlw_elem(writer, "annotation",
         p_("snapshot_name", "%s (%s)"), annotation, player.name);
   xmlw_endElem(writer); /* "version" */

   /* Save last played. */
   xmlw_saveTime(writer, "last_played", time(NULL));

   /* Save the data. */
   if (save_data(writer) < 0) {
      ERR(_("Error trying to save game data"));
      ret = -1;
      goto exit;
   }

   /* Finish element. */
   xmlw_endElem(writer); /* "naev_save" */
   xmlw_done(writer);

   /* Write to file. */
   if (PHYSFS_mkdir("saves") == 0) {
      snprintf(buf, sizeof(buf), "%s/saves", PHYSFS_getWriteDir());
      WARN(_("Dir '%s' does not exist and unable to create: %s"), buf,
            PHYSFS_getErrorByCode(PHYSFS_getLastErrorCode()));
      ret = -1;
      goto exit;
   }
   str2filename(buf, sizeof(buf), player.name);
   str2filename(buf2, sizeof(buf2), annotation);
   asprintf(&snapfile, "saves/%s-%s.ns.snapshot", buf, buf2);
   asprintf(&path, "%s/%s", PHYSFS_getWriteDir(), snapfile);

   if (PHYSFS_exists(snapfile)
         && !dialogue_YesNo(_("Save Snapshot"),
            _("You already have a snapshot named '%s'. Overwrite?"),
            annotation)) {
      goto exit;
   }

   /* TODO: write via physfs */
   if (xmlSaveFileEnc(path, doc, "UTF-8") < 0) {
      WARN(_("Failed to write snapshot."));
      ret = -1;
      goto exit;
   }

   dialogue_msg(_("Save Snapshot"), _("Snapshot '%s' saved."), annotation);

exit:
   xmlFreeTextWriter(writer);
   xmlFreeDoc(doc);
   free(snapfile);
   free(path);

   return ret;
}


/**
 * @brief Reload the current saved game.
 */
void save_reload (void)
{
   char path[PATH_MAX], buf[PATH_MAX];
   int written;

   str2filename(buf, sizeof(buf), player.name);
   written = snprintf(path, sizeof(path), "saves/%s.ns", buf);
   if (written < 0) {
      WARN(_("Error writing save file name."));
      return;
   }
   else if (written >= (int)sizeof(path))
      WARN(_("Save file name was truncated: %s"), path);
   load_gameFile(path);
}
