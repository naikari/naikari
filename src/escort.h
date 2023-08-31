/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef ESCORT_H
#  define ESCORT_H


#include "physics.h"
#include "pilot.h"
#include "space.h"


/* Creation. */
int escort_addList(Pilot *p, char *ship, EscortType_t type, pilotId_t id,
      int persist);
void escort_freeList(Pilot *p);
void escort_rmList(Pilot *p, pilotId_t id);
void escort_rmListIndex(Pilot *p, int i);
pilotId_t escort_create(Pilot *p, char *ship, Vector2d *pos, Vector2d *vel,
      double dir, EscortType_t type, int add, int dockslot);

/* Keybind commands. */
int escorts_attack( Pilot *parent );
int escorts_hold( Pilot *parent );
int escorts_return( Pilot *parent );
int escorts_clear( Pilot *parent );
int escort_playerCommand( Pilot *e );


#endif /* ESCORT_H */
