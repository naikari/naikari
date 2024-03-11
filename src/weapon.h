/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef WEAPON_H
#  define WEAPON_H


#include "faction.h"
#include "outfit.h"
#include "physics.h"
#include "pilot.h"


/**
 * @enum WeaponLayer
 * @brief Designates the layer the weapon is on.
 * Automatically set up on creation (player is front, rest is back).
 */
typedef enum { WEAPON_LAYER_BG, WEAPON_LAYER_FG } WeaponLayer;


/*
 * addition
 */
void weapon_add(const PilotOutfitSlot *slot, const double dir,
      const Vector2d* pos, const Vector2d* vel,
      const Pilot *parent, pilotId_t target, double time);


/*
 * Beam weapons.
 */
unsigned int beam_start(const PilotOutfitSlot *slot,
      const double dir, const Vector2d* pos, const Vector2d* vel,
      const Pilot *parent, const pilotId_t target,
      PilotOutfitSlot *mount);
void beam_end(const pilotId_t parent, unsigned int beam);


/*
 * Misc stuff.
 */
void weapon_explode( double x, double y, double radius,
      int dtype, double damage,
      const Pilot *parent, int mode );


/*
 * update
 */
void weapons_update( const double dt );
void weapons_render( const WeaponLayer layer, const double dt );


/*
 * clean
 */
void weapon_init (void);
void weapon_clear (void);
void weapon_exit (void);


#endif /* WEAPON_H */

