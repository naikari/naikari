/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file npc.c
 *
 * @brief Handles NPC stuff.
 */


/** @cond */
#include <lua.h>

#include "naev.h"
/** @endcond */

#include "npc.h"

#include "array.h"
#include "dialogue.h"
#include "event.h"
#include "land.h"
#include "log.h"
#include "nstring.h"
#include "opengl.h"
#include "ndata.h"


/**
 * @brief NPC types.
 */
typedef enum NPCtype_ {
   NPC_TYPE_NULL, /**< Inexistent NPC. */
   NPC_TYPE_GIVER, /**< Mission giver NPC. */
   NPC_TYPE_MISSION, /**< NPC generated by a mission. */
   NPC_TYPE_EVENT /**< NPC generated by an event. */
} NPCtype;

/**
 * @brief Minimum needed NPC data for event.
 */
typedef struct NPCevtData_ {
   unsigned int id; /**< ID of the event. */
   char *func; /**< Function to run. */
} NPCevtData;
/**
 * @brief Minimum needed NPC data for mission.
 */
typedef struct NPCmisnData_ {
   unsigned int id; /**< Mission information. */
   char *func; /**< Function to run. */
} NPCmisnData;
/**
 * @brief The bar NPC.
 */
typedef struct NPC_s {
   unsigned int id; /**< ID of the NPC. */
   NPCtype type; /**< Type of the NPC. */
   int priority; /**< NPC priority, 5 is average, 0 is highest, 10 is lowest. */
   char *name; /**< Translated, human-readable name of the NPC. */
   glTexture *portrait; /**< Portrait of the NPC. */
   glTexture *background; /**< Background of the NPC. */
   char *desc; /**< Translated, human-readable NPC description. */
   union {
      NPCmisnData m; /**< Mission information (for mission generated NPC). */
      NPCevtData e; /**< Event data (for event generated NPC). */
   } u; /**< Type-specific data. */
} NPC_t;

static unsigned int npc_array_idgen = 0; /**< ID generator. */
static NPC_t *npc_array  = NULL; /**< Missions at the spaceport bar. */

/* We have to store the missions temporarily here. */
static Mission *npc_missions = NULL;

/*
 * Prototypes.
 */
/* NPCs. */
static unsigned int npc_add( NPC_t *npc );
static int npc_rm( NPC_t *npc );
static NPC_t *npc_arrayGet( unsigned int id );
static void npc_free( NPC_t *npc );
/* Missions. */
static Mission* npc_getMisn( const NPC_t *npc );


/**
 * Gets the mission associated with an NPC.
 */
static Mission* npc_getMisn( const NPC_t *npc )
{
   int i;

   /* First check active missions. */
   for (i=0; i<MISSION_MAX; i++)
      if (player_missions[i]->id == npc->u.m.id)
         return player_missions[i];

   /* Now check npc missions. */
   for (i=0; i<array_size(npc_missions); i++)
      if (npc_missions[i].id == npc->u.m.id)
         return &npc_missions[i];

   return NULL;
}


/**
 * @brief Adds an NPC to the spaceport bar.
 */
static unsigned int npc_add( NPC_t *npc )
{
   NPC_t *new_npc;

   /* Must be landed. */
   if (!landed) {
      npc_free( npc );
      return 0;
   }

   /* Create if needed. */
   if (npc_array == NULL)
      npc_array = array_create( NPC_t );

   /* Grow. */
   new_npc = &array_grow( &npc_array );

   /* Copy over. */
   *new_npc = *npc;

   /* Set ID. */
   new_npc->id = ++npc_array_idgen;
   return new_npc->id;
}


/**
 * @brief Adds a mission giver NPC to the mission computer.
 */
static unsigned int npc_add_giver( Mission *misn )
{
   NPC_t npc;

   /* Sanity check. */
   if (misn->npc == NULL) {
      WARN(_("Mission '%s' trying to create NPC with no name!"), misn->data->name);
      return 0;
   }
   if (misn->portrait == NULL) {
      WARN(_("Mission '%s' trying to create NPC with no portrait!"), misn->data->name);
      return 0;
   }
   if (misn->npc_desc == NULL) {
      WARN(_("Mission '%s' trying to create NPC with no description!"), misn->data->name);
      return 0;
   }

   /* Set up the data. */
   npc.type       = NPC_TYPE_GIVER;
   npc.name       = strdup(misn->npc);
   npc.priority   = misn->data->avail.priority;
   npc.portrait   = gl_dupTexture(misn->portrait);
   npc.background = NULL;
   npc.desc       = strdup(misn->npc_desc);
   npc.u.m.id     = misn->id;
   npc.u.m.func   = strdup("accept");

   return npc_add( &npc );
}


/**
 * @brief Adds a mission NPC to the mission computer.
 */
unsigned int npc_add_mission( unsigned int mid, const char *func, const char *name,
      int priority, const char *portrait, const char *desc, const char *background )
{
   NPC_t npc;

   /* The data. */
   npc.type       = NPC_TYPE_MISSION;
   npc.name       = strdup( name );
   npc.priority   = priority;
   npc.portrait   = gl_newImage( portrait, 0 );
   if (background != NULL)
      npc.background = gl_newImage( background, 0 );
   else
      npc.background = NULL;
   npc.desc       = strdup( desc );
   npc.u.m.id     = mid;
   npc.u.m.func   = strdup( func );

   return npc_add( &npc );
}


/**
 * @brief Adds a event NPC to the mission computer.
 */
unsigned int npc_add_event( unsigned int evt, const char *func, const char *name,
      int priority, const char *portrait, const char *desc, const char *background )
{
   NPC_t npc;

   /* The data. */
   npc.type       = NPC_TYPE_EVENT;
   npc.name       = strdup( name );
   npc.priority   = priority;
   npc.portrait   = gl_newImage( portrait, 0 );
   if (background != NULL)
      npc.background = gl_newImage( background, 0 );
   else
      npc.background = NULL;
   npc.desc       = strdup( desc );
   npc.u.e.id     = evt;
   npc.u.e.func   = strdup( func );

   return npc_add( &npc );
}


/**
 * @brief Removes an npc from the spaceport bar.
 */
static int npc_rm( NPC_t *npc )
{
   npc_free(npc);

   array_erase( &npc_array, &npc[0], &npc[1] );

   return 0;
}


/**
 * @brief Gets an NPC by ID.
 */
static NPC_t *npc_arrayGet( unsigned int id )
{
   int i;
   for (i=0; i<array_size( npc_array ); i++)
      if (npc_array[i].id == id)
         return &npc_array[i];
   return NULL;
}


/**
 * @brief removes an event NPC.
 */
int npc_rm_event( unsigned int id, unsigned int evt )
{
   NPC_t *npc;

   /* Get the NPC. */
   npc = npc_arrayGet( id );
   if (npc == NULL)
      return -1;

   /* Doesn't match type. */
   if (npc->type != NPC_TYPE_EVENT)
      return -1;

   /* Doesn't belong to the event.. */
   if (npc->u.e.id != evt)
      return -1;

   /* Remove the NPC. */
   return npc_rm( npc );
}


/**
 * @brief removes a mission NPC.
 */
int npc_rm_mission( unsigned int id, unsigned int mid )
{
   NPC_t *npc;

   /* Get the NPC. */
   npc = npc_arrayGet( id );
   if (npc == NULL)
      return -1;

   /* Doesn't match type. */
   if (npc->type != NPC_TYPE_MISSION)
      return -1;

   /* Doesn't belong to the mission. */
   if (mid != npc->u.m.id)
      return -1;

   /* Remove the NPC. */
   return npc_rm( npc );
}


/**
 * @brief Removes all the npc belonging to an event.
 */
int npc_rm_parentEvent( unsigned int id )
{
   int i, n;
   NPC_t *npc;

   n = 0;
   for (i=0; i<array_size(npc_array); i++) {
      npc = &npc_array[i];
      if (npc->type != NPC_TYPE_EVENT)
         continue;
      if (npc->u.e.id != id )
         continue;

      /* Invalidates iterators. */
      npc_rm( npc );
      i--;
      n++;
   }

   bar_regen();

   return n;
}


/**
 * @brief Removes all the npc belonging to a mission.
 */
int npc_rm_parentMission( unsigned int mid )
{
   int i, n;
   NPC_t *npc;

   n = 0;
   for (i=0; i<array_size(npc_array); i++) {
      npc = &npc_array[i];
      if (npc->type != NPC_TYPE_MISSION)
         continue;
      if (npc->u.m.id != mid )
         continue;

      /* Invalidates iterators. */
      npc_rm( npc );
      i--;
      n++;
   }

   bar_regen();

   return n;
}


/**
 * @brief NPC compare function.
 */
static int npc_compare( const void *arg1, const void *arg2 )
{
   const NPC_t *npc1, *npc2;
   int ret;

   npc1 = (NPC_t*)arg1;
   npc2 = (NPC_t*)arg2;

   /* Compare priority. */
   if (npc1->priority > npc2->priority)
      return +1;
   else if (npc1->priority < npc2->priority)
      return -1;

   /* Compare name. */
   ret = strcmp( npc1->name, npc2->name );
   if (ret != 0)
      return ret;

   /* Compare ID. */
   if (npc1->id > npc2->id)
      return +1;
   else if (npc1->id < npc2->id)
      return -1;
   return 0;
}


/**
 * @brief Sorts the NPCs.
 */
void npc_sort (void)
{
   if (npc_array != NULL)
      qsort( npc_array, array_size(npc_array), sizeof(NPC_t), npc_compare );
}


/**
 * @brief Generates the bar missions.
 */
void npc_generateMissions (void)
{
   int i;
   Mission *missions, *m;
   int nmissions;

   if (npc_missions == NULL)
      npc_missions = array_create( Mission );

   /* Get the missions. */
   missions = missions_genList( &nmissions,
         land_planet->faction, land_planet->name, cur_system->name,
         MIS_AVAIL_BAR );
   /* Mission sshould already be generated and have had their 'create' function
    * run, so NPCs should be running wild (except givers). */

   /* Add to the bar NPC stack and add npc. */
   for (i=0; i<nmissions; i++) {
      m = &missions[i];
      array_push_back( &npc_missions, *m );

      /* See if need to add NPC. */
      if (m->npc)
         npc_add_giver( m );

#if DEBUGGING
      /* Make sure the mission has created an NPC or it won't be able to do anything. */
      int found = 0;
      NPC_t *npc;
      for (int j=0; j<array_size(npc_array); j++) {
         npc = &npc_array[j];
         if ((npc->type == NPC_TYPE_MISSION || npc->type == NPC_TYPE_GIVER) &&
               npc->u.m.id == m->id) {
            found = 1;
            break;
         }
      }
      if (!found)
         WARN(_("Mission '%s' was created at the spaceport bar but didn't create any NPC!"), m->data->name);
#endif /* DEBUGGING */
   }

   /* Clean up. */
   free( missions );

   /* Sort NPC. */
   npc_sort();
}


/**
 * @brief Patches a new mission bar npc into the bar system.
 *
 * @note Do not reuse the pointer once it's fed.
 *
 *    @param misn Mission to patch in.
 */
void npc_patchMission( Mission *misn )
{
   if (npc_missions==NULL)
      npc_missions = array_create( Mission );

   /* Add to array. */
   array_push_back( &npc_missions, *misn );

   /* Add mission giver if necessary. */
   if (misn->npc)
      npc_add_giver( misn );

   /* Sort NPC. */
   npc_sort();
}


/**
 * @brief Frees a single npc.
 */
static void npc_free( NPC_t *npc )
{
   /* Common free stuff. */
   free(npc->name);
   gl_freeTexture(npc->portrait);
   if (npc->background != NULL)
      gl_freeTexture(npc->background);
   free(npc->desc);

   /* Type-specific free stuff. */
   switch (npc->type) {
      case NPC_TYPE_GIVER:
      case NPC_TYPE_MISSION:
         free(npc->u.m.func);
         break;

      case NPC_TYPE_EVENT:
         free(npc->u.e.func);
         break;

      default:
         WARN(_("Freeing NPC of invalid type."));
         return;
   }
}


/**
 * @brief Cleans up the spaceport bar NPC.
 */
void npc_clear (void)
{
   int i, j;

   /* Clear the npcs. */
   for (i=0; i<array_size( npc_array ); i++)
      npc_free( &npc_array[i] );
   array_free( npc_array );
   npc_array = NULL;

   /* Clear all the missions. */
   for (i=0; i<array_size( npc_missions ); i++) {
      /* TODO this is horrible and should be removed */
      /* Clean up all missions that haven't been moved to the active missions. */
      for (j=0; j<MISSION_MAX; j++)
         if (player_missions[i]->id == npc_missions[i].id)
            break;
      if (j>=MISSION_MAX)
         mission_cleanup( &npc_missions[i] );
   }
   array_free( npc_missions );
   npc_missions = NULL;
}


/**
 * @brief Get the size of the npc array.
 */
int npc_getArraySize (void)
{
   return array_size( npc_array );
}


/**
 * @brief Get the name of an NPC.
 */
const char *npc_getName( int i )
{
   /* Make sure in bounds. */
   if (i<0 || npc_array == NULL || i>=array_size(npc_array))
      return NULL;

   return npc_array[i].name;
}


/**
 * @brief Get the background of an NPC.
 */
glTexture *npc_getBackground( int i )
{
   /* Make sure in bounds. */
   if (i<0 || npc_array == NULL || i>=array_size(npc_array))
      return NULL;

   /* TODO choose the background based on the planet or something. */
   if (npc_array[i].background == NULL)
      npc_array[i].background = gl_newImage( GFX_PATH"portraits/background.png", 0 );
   return npc_array[i].background;
}


/**
 * @brief Get the texture of an NPC.
 */
glTexture *npc_getTexture( int i )
{
   /* Make sure in bounds. */
   if (i<0 || npc_array == NULL || i>=array_size(npc_array))
      return NULL;

   return npc_array[i].portrait;
}


/**
 * @brief Gets the NPC description.
 */
const char *npc_getDesc( int i )
{
   /* Make sure in bounds. */
   if (i<0 || npc_array == NULL || i>=array_size(npc_array))
      return NULL;

   return npc_array[i].desc;
}


/**
 * @brief Checks to see if the NPC is important or not.
 */
int npc_isImportant( int i )
{
   /* Make sure in bounds. */
   if (i<0 || npc_array == NULL || i>=array_size(npc_array))
      return 0;

   if (npc_array[i].priority <= 5)
      return 1;
   return 0;
}


/**
 * @brief Approaches a mission giver guy.
 *
 *    @brief Returns 1 on destroyed, 0 on not destroyed.
 */
static int npc_approach_giver( NPC_t *npc )
{
   int i;
   int ret;
   Mission *misn;
   unsigned int id;

   /* Make sure player can accept the mission. */
   for (i=0; i<MISSION_MAX; i++)
      if (player_missions[i]->data == NULL)
         break;
   if (i >= MISSION_MAX) {
      dialogue_alert(_("You have too many active missions."));
      return -1;
   }

   /* Get mission. */
   misn = npc_getMisn( npc );
   if (misn==NULL) {
      WARN(_("Unable to find mission '%d' in npc_missions for giver npc '%s'!"), npc->u.m.id, npc->name);
      return -1;
   }
   id   = npc->id;
   ret  = mission_accept( misn );
   if ((ret==3) || (ret==2) || (ret==-1)) { /* success in accepting the mission */
      if (ret==-1)
         mission_cleanup( misn );
      npc_rm( npc_arrayGet(id) );
      ret = 1;
   }
   else
      ret  = 0;

   return ret;
}


/**
 * @brief Approaches the NPC.
 *
 *    @param i Index of the NPC to approach.
 */
int npc_approach( int i )
{
   NPC_t *npc;
   Mission *misn;

   /* Make sure in bounds. */
   if (i<0 || i>=array_size(npc_array))
      return -1;

   /* Comfortability. */
   npc = &npc_array[i];

   /* Handle type. */
   switch (npc->type) {
      case NPC_TYPE_GIVER:
         return npc_approach_giver( npc );

      case NPC_TYPE_MISSION:
         misn = npc_getMisn( npc );
         if (misn==NULL) {
      WARN(_("Unable to find mission '%d' in npc_missions for mission npc '%s'!"), npc->u.m.id, npc->name);
            return -1;
         }
         misn_runStart( misn, npc->u.m.func );
         lua_pushnumber( naevL, npc->id );
         misn_runFunc( misn, npc->u.m.func, 1 );
         break;

      case NPC_TYPE_EVENT:
         event_runStart( npc->u.e.id, npc->u.e.func );
         lua_pushnumber( naevL, npc->id );
         event_runFunc( npc->u.e.id, npc->u.e.func, 1 );
         break;

      default:
         WARN(_("Unknown NPC type!"));
         return -1;
   }

   return 0;
}

