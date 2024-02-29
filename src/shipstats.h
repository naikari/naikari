/*
 * See Licensing and Copyright notice in naev.h
 */



#ifndef SHIPSTATS_H
#  define SHIPSTATS_H


#include "nxml.h"
#include "nlua.h"


/**
 * @brief Lists all the possible types.
 *
 * Syntax:
 *    SS_TYPE_#1_#2
 *
 * #1 is D for double, A for absolute double, I for integer or B for boolean.
 * #2 is the name.
 */
typedef enum ShipStatsType_ {
   SS_TYPE_NIL, /**< Invalid type. */

   /* Core stats. */
   SS_TYPE_D_MASS, /**< Mass multiplier. */
   SS_TYPE_A_ENGINE_LIMIT, /**< Mass limit modifier. */
   SS_TYPE_D_ENGINE_LIMIT_REL, /**< Mass limit multiplier. */

   /* Forward weapons. */
   SS_TYPE_D_FORWARD_DAMAGE, /**< Forward damage multiplier. */
   SS_TYPE_D_FORWARD_FIRERATE, /**< Forward fire rate multiplier. */
   SS_TYPE_D_FORWARD_RANGE, /**< Forward range multiplier. */
   SS_TYPE_D_FORWARD_ENERGY, /**< Forward energy usage multiplier. */
   SS_TYPE_D_FORWARD_HEAT, /**< Forward heat generation multiplier. */
   SS_TYPE_P_FORWARD_DAMAGE_AS_DISABLE, /**< Forward damage as disable modifier. */

   /* Turrets. */
   SS_TYPE_B_TURRET_CONVERSION, /**< Convert all weapons to turrets. */
   SS_TYPE_D_TURRET_DAMAGE, /**< Turret damage multiplier. */
   SS_TYPE_D_TURRET_FIRERATE, /**< Turret fire rate multiplier. */
   SS_TYPE_D_TURRET_RANGE, /**< Forward range multiplier. */
   SS_TYPE_D_TURRET_ENERGY, /**< Turret energy usage multiplier. */
   SS_TYPE_D_TURRET_HEAT, /**< Turret heat generation multiplier. */
   SS_TYPE_P_TURRET_DAMAGE_AS_DISABLE, /**< Turret damage as disable modifier. */

   /* Launchers. */
   SS_TYPE_D_LAUNCH_DAMAGE, /**< Launcher damage multiplier. */
   SS_TYPE_D_LAUNCH_RATE, /**< Launcher fire rate multiplier. */
   SS_TYPE_D_LAUNCH_RANGE, /**< Launcher range multiplier. */
   SS_TYPE_D_AMMO_CAPACITY, /**< Launcher capacity multiplier. */
   SS_TYPE_D_LAUNCH_RELOAD, /**< Launcher reload rate multiplier. */
   SS_TYPE_P_LAUNCH_DAMAGE_AS_DISABLE, /**< Launcher damage as disable modifier. */

   /* Fighter bays. */
   SS_TYPE_D_FBAY_DAMAGE, /**< Fighter bay fighter damage multiplier. */
   SS_TYPE_D_FBAY_HEALTH, /**< Fighter bay fighter shield/armor multiplier. */
   SS_TYPE_D_FBAY_MOVEMENT, /**< Fighter bay fighter turn/thrust/speed multiplier. */
   SS_TYPE_D_FBAY_CAPACITY, /**< Fighter bay capacity multiplier. */
   SS_TYPE_D_FBAY_RATE,       /**< Launch rate for fighter bays. */
   SS_TYPE_D_FBAY_RELOAD,     /**< Regeneration rate of fighters. */

   /* Speed. */
   SS_TYPE_A_SPEED, /**< Speed modifier. */
   SS_TYPE_D_SPEED_MOD, /**< Speed multiplier. */
   SS_TYPE_A_TURN, /**< Turn modifier (in deg/s). */
   SS_TYPE_D_TURN_MOD, /**< Turn multiplier. */
   SS_TYPE_A_THRUST, /**< Acceleration modifier. */
   SS_TYPE_D_THRUST_MOD, /**< Acceleration multiplier. */
   SS_TYPE_P_REVERSE_THRUST, /**< Reverse acceleration modifier. */
   SS_TYPE_D_TIME_MOD, /**< Time constant multiplier. */
   SS_TYPE_D_TIME_SPEEDUP, /**< Makes the pilot operate at a higher dt. */

   /* Mobility. */
   SS_TYPE_A_FUEL, /**< Fuel modifier. */
   SS_TYPE_A_FUEL_REGEN, /** Fuel regeneration modifier. */
   SS_TYPE_D_JUMP_DELAY, /**< Hyperspace jump multiplier. */
   SS_TYPE_D_LAND_DELAY, /**< Takeoff time multiplier. */
   SS_TYPE_D_JUMP_DISTANCE, /**< Jump radius multiplier. */
   SS_TYPE_B_INSTANT_JUMP, /**< Do not require brake or chargeup to jump. */

   /* Health. */
   SS_TYPE_A_SHIELD, /**< Shield modifier. */
   SS_TYPE_D_SHIELD_MOD, /**< Shield multiplier. */
   SS_TYPE_A_SHIELD_REGEN, /**< Shield regeneration modifier. */
   SS_TYPE_D_SHIELD_REGEN_MOD, /**< Shield regeneration multiplier. */
   SS_TYPE_A_SHIELD_REGEN_MALUS, /**< Flat shield regeneration modifier (not multiplied). */
   SS_TYPE_A_ARMOUR, /**< Armour modifier. */
   SS_TYPE_D_ARMOUR_MOD, /**< Armour multiplier. */
   SS_TYPE_A_ARMOUR_REGEN, /**< Armour regeneration modifier. */
   SS_TYPE_D_ARMOUR_REGEN_MOD, /**< Armour regeneration multiplier. */
   SS_TYPE_A_ARMOUR_REGEN_MALUS, /**< Flat armour regeneration modifier (not multiplied). */
   SS_TYPE_A_ENERGY, /**< Energy modifier. */
   SS_TYPE_D_ENERGY_MOD, /**< Energy multiplier. */
   SS_TYPE_A_ENERGY_REGEN, /**< Energy regeneration modifier. */
   SS_TYPE_D_ENERGY_REGEN_MOD, /**< Energy regeneration multiplier. */
   SS_TYPE_A_ENERGY_REGEN_MALUS, /**< Flat energy regeneration modifier (not multiplied). */
   SS_TYPE_P_ABSORB, /**< Damage absorption. */
   SS_TYPE_D_HEAT_DISSIPATION, /**< Heat dissipation multiplier. */
   SS_TYPE_D_STRESS_DISSIPATION, /**< Stress dissipation multiplier. */
   SS_TYPE_D_COOLDOWN_TIME, /**< Active cooldown time multiplier. */

   /* Cargo. */
   SS_TYPE_I_CARGO, /**< Cargo bonus. */
   SS_TYPE_D_CARGO_MOD, /**< Cargo space multiplier. */
   SS_TYPE_D_CARGO_INERTIA, /**< Carried cargo mass multiplier. */
   SS_TYPE_B_ASTEROID_SCAN, /**< Can gather information from asteroids. */
   SS_TYPE_D_LOOT_MOD, /**< Boarding loot multiplier. */

   /* Radar. */
   SS_TYPE_D_RDR_RANGE, /**< Radar range. */
   SS_TYPE_D_RDR_RANGE_MOD, /**< Radar range modifier. */
   SS_TYPE_D_RDR_JUMP_RANGE, /**< Jump detection range. */
   SS_TYPE_D_RDR_JUMP_RANGE_MOD, /**< Jump detection range modifier. */
   SS_TYPE_D_RDR_ENEMY_RANGE_MOD, /**< Enemy radar range modifier. */

   /* Nebula. */
   SS_TYPE_P_NEBULA_ABSORB_SHIELD, /**< Shield nebula resistance. */
   SS_TYPE_P_NEBULA_ABSORB_ARMOUR, /**< Armour nebula resistance. */

   /*
    * End of list.
    */
   SS_TYPE_SENTINEL /**< Sentinel for end of types. */
} ShipStatsType;

/**
 * @brief Represents relative ship statistics as a linked list.
 *
 * Doubles:
 *  These values are relative so something like -0.15 would be -15%.
 *
 * Absolute and Integers:
 *  These values are just absolute values.
 *
 * Booleans:
 *  Can only be 1.
 */
typedef struct ShipStatList_ {
   struct ShipStatList_ *next; /**< Next pointer. */

   int target;          /**< Whether or not it affects the target. */
   ShipStatsType type;  /**< Type of stat. */
   union {
      double d;         /**< Floating point data. */
      int    i;         /**< Integer data. */
   } d; /**< Stat data. */
} ShipStatList;


/**
 * @brief Represents ship statistics, properties ship can use.
 *
 * Doubles:
 *  These are normalized and centered around 1 so they are in the [0:2]
 *  range, with 1. being default. This value then modulates the stat's base
 *  value.
 *  Example:
 *   0.7 would lower by 30% the base value.
 *   1.2 would increase by 20% the base value.
 *
 * Absolute and Integers:
 *  Absolute values in whatever units it's meant to use.
 *
 * Booleans:
 *  1 or 0 values wher 1 indicates property is set.
 */
typedef struct ShipStats_ {
   /* Core stats. */
   double mass_mod; /**< Mass multiplier. */
   double engine_limit; /**< Engine limit modifier. */
   double engine_limit_rel; /**< Engine limit multiplier. */

   /* Forward weapons. */
   double fwd_damage; /**< Forward damage multiplier. */
   double fwd_firerate; /**< Forward fire rate multiplier. */
   double fwd_range; /**< Forward range multiplier. */
   double fwd_energy; /**< Forward energy usage multiplier. */
   double fwd_heat; /**< Forward heat generation multiplier. */
   double fwd_dam_as_dis; /**< Forward damage as disable modifier. */

   /* Turrets. */
   double tur_damage; /**< Turret damage multiplier. */
   double tur_firerate; /**< Turret fire rate multiplier. */
   double tur_range; /**< Turret range multiplier. */
   double tur_energy; /**< Turret energy usage multiplier. */
   double tur_heat; /**< Turret heat generation multiplier. */
   double tur_dam_as_dis; /**< Turret damage as disable modifier. */

   /* Movement. */
   double speed;              /**< Speed modifier. */
   double turn;               /**< Turn modifier. */
   double thrust;             /**< Thrust modifier. */
   double speed_mod;          /**< Speed multiplier. */
   double turn_mod;           /**< Turn multiplier. */
   double thrust_mod;         /**< Thrust multiplier. */
   double reverse_thrust; /**< Reverse thrust modifier. */

   /* Health. */
   double energy;             /**< Energy modifier. */
   double energy_regen;       /**< Energy regeneration modifier. */
   double energy_mod;         /**< Energy multiplier. */
   double energy_regen_mod;   /**< Energy regeneration multiplier. */
   double energy_regen_malus; /**< Energy usage (flat). */
   double shield;             /**< Shield modifier. */
   double shield_regen;       /**< Shield regeneration modifier. */
   double shield_mod;         /**< Shield multiplier. */
   double shield_regen_mod;   /**< Shield regeneration multiplier. */
   double shield_regen_malus; /**< Shield usage (flat). */
   double armour;             /**< Armour modifier. */
   double armour_regen;       /**< Armour regeneration modifier. */
   double armour_mod;         /**< Armour multiplier. */
   double armour_regen_mod;   /**< Armour regeneration multiplier. */
   double armour_regen_malus; /**< Armour regeneration (flat). */

   /* General */
   double cargo_mod;          /**< Cargo space multiplier. */
   double absorb;             /**< Flat damage absorption. */

   /* Freighter-type. */
   double jump_delay;      /**< Modulates the time that passes during a hyperspace jump. */
   double land_delay;      /**< Modulates the time that passes during landing. */
   double cargo_inertia;   /**< Lowers the effect of cargo mass. */

   /* Stealth. */
   double rdr_range;       /**< Radar range. */
   double rdr_jump_range;  /**< Jump detection range. */
   double rdr_range_mod;   /**< Radar range modifier. */
   double rdr_jump_range_mod; /**< Jump detection range modifier. */
   double rdr_enemy_range_mod; /**< Enemy radar range modifier. */

   /* Military type. */
   double heat_dissipation; /**< Global ship dissipation. */
   double stress_dissipation; /**< Global stress dissipation. */

   /* Launchers. */
   double launch_rate;     /**< Fire rate of launchers. */
   double launch_range;    /**< Range of launchers. */
   double launch_damage;   /**< Damage of launchers. */
   double ammo_capacity;   /**< Capacity of launchers. */
   double launch_reload;   /**< Reload rate of launchers. */
   double launch_dam_as_dis; /**< Damage as disable for launchers. */

   /* Fighter bays. */
   double fbay_damage;     /**< Fighter bay fighter damage (all weapons). */
   double fbay_health;     /**< Fighter bay fighter health (armour and shield). */
   double fbay_movement;   /**< Fighter bay fighter movement (thrust, turn, and speed). */
   double fbay_capacity;   /**< Capacity of fighter bays. */
   double fbay_rate;       /**< Launch rate of fighter bays. */
   double fbay_reload;     /**< Reload rate of fighters. */

   /* Misc. */
   double nebu_absorb_shield; /**< Shield nebula resistance. */
   double nebu_absorb_armour; /**< Armour nebula resistance. */
   int misc_instant_jump;    /**< Do not require brake or chargeup to jump. */
   int misc_asteroid_scan;   /**< Able to scan asteroids. */
   double fuel; /**< Maximum fuel modifier. */
   double fuel_regen; /**< Fuel regeneration modifier. */
   int cargo;                 /**< Maximum cargo modifier. */
   double loot_mod;           /**< Boarding loot reward bonus. */
   double time_mod;           /**< Time dilation modifier. */
   double time_speedup;       /**< Makes the pilot operate at higher speeds. */
   double cooldown_time;      /**< Modifies cooldown time. */
   double jump_distance;      /**< Modifies how far the pilot can jump from the jump point. */
   int turret_conversion; /**< Convert all weapons to turrets. */
} ShipStats;


/*
 * Safety.
 */
int ss_check (void);

/*
 * Loading.
 */
ShipStatList* ss_listFromXML( xmlNodePtr node );
void ss_free( ShipStatList *ll );

/*
 * Manipulation
 */
int ss_statsInit( ShipStats *stats );
int ss_statsMerge( ShipStats *dest, const ShipStats *src );
int ss_statsModSingle( ShipStats *stats, const ShipStatList* list );
int ss_statsModFromList( ShipStats *stats, const ShipStatList* list );

/*
 * Lookup.
 */
const char* ss_nameFromType( ShipStatsType type );
size_t ss_offsetFromType( ShipStatsType type );
ShipStatsType ss_typeFromName( const char *name );
int ss_statsListDesc( const ShipStatList *ll, char *buf, int len, int newline );
int ss_statsDesc(const ShipStats *s, char *buf, int len, int newline,
      int composite);

/*
 * Manipulation.
 */
int ss_statsSet( ShipStats *s, const char *name, double value, int overwrite );
double ss_statsGet( const ShipStats *s, const char *name );
int ss_statsGetLua( lua_State *L, const ShipStats *s, const char *name, int internal );
int ss_statsGetLuaTable( lua_State *L, const ShipStats *s, int internal );


#endif /* SHIPSTATS_H */
