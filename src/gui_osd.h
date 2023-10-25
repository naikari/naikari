/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef OSD_H
#  define OSD_H


typedef unsigned int osdId_t; /**< Type for OSD IDs. */

/* Forward declaration to avoid cyclical import. */
struct Mission_;
typedef struct Mission_ Mission;


/*
 * OSD usage.
 */
osdId_t osd_create(Mission *misn, const char *title,
      int nitems, const char **items, int priority);
int osd_destroy(osdId_t osd);
int osd_active(osdId_t osd, int msg);
int osd_getActive(osdId_t osd);
char *osd_getTitle(osdId_t osd);
char **osd_getItems(osdId_t osd);


/*
 * Subsystem usage.
 */
int osd_setup( int x, int y, int w, int h );
void osd_exit (void);
void osd_render (void);


#endif /* OSD_H */
