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
   SS_TYPE_I_SLOTS_UTILITY, /**< Bonus utility slots. */
   SS_TYPE_I_SLOTS_STRUCTURAL, /**< Bonus structural slots. */

   /* Forward weapons. */
   SS_TYPE_D_FORWARD_DAMAGE, /**< Forward damage multiplier. */
   SS_TYPE_D_FORWARD_FIRERATE, /**< Forward fire rate multiplier. */
   SS_TYPE_D_FORWARD_RANGE, /**< Forward range multiplier. */
   SS_TYPE_D_FORWARD_SPEED, /**< Forward bolt speed multiplier. */
   SS_TYPE_I_FORWARD_SALVO, /**< Forward bolt salvo modifier. */
   SS_TYPE_A_FORWARD_SPREAD, /**< Forward bolt spread modifier. */
   SS_TYPE_D_FORWARD_ENERGY, /**< Forward energy usage multiplier. */
   SS_TYPE_D_FORWARD_HEAT, /**< Forward heat generation multiplier. */
   SS_TYPE_P_FORWARD_DAMAGE_AS_DISABLE, /**< Forward damage as disable modifier. */
   SS_TYPE_P_FORWARD_DISABLE_AS_DAMAGE, /**< Forward disable as damage modifier. */
   SS_TYPE_P_FORWARD_DAMAGE_SHIELD_AS_ARMOR, /**< Forward damage shield to armor modifier. */
   SS_TYPE_P_FORWARD_DAMAGE_ARMOR_AS_SHIELD, /**< Forward damage shield to armor modifier. */

   /* Turrets. */
   SS_TYPE_B_TURRET_CONVERSION, /**< Convert all weapons to turrets. */
   SS_TYPE_D_TURRET_DAMAGE, /**< Turret damage multiplier. */
   SS_TYPE_D_TURRET_FIRERATE, /**< Turret fire rate multiplier. */
   SS_TYPE_D_TURRET_RANGE, /**< Turret range multiplier. */
   SS_TYPE_D_TURRET_SPEED, /**< Turret bolt speed multiplier. */
   SS_TYPE_I_TURRET_SALVO, /**< Turret bolt salvo modifier. */
   SS_TYPE_A_TURRET_SPREAD, /**< Turret bolt spread modifier. */
   SS_TYPE_D_TURRET_ENERGY, /**< Turret energy usage multiplier. */
   SS_TYPE_D_TURRET_HEAT, /**< Turret heat generation multiplier. */
   SS_TYPE_P_TURRET_DAMAGE_AS_DISABLE, /**< Turret damage as disable modifier. */
   SS_TYPE_P_TURRET_DISABLE_AS_DAMAGE, /**< Turret disable as damage modifier. */
   SS_TYPE_P_TURRET_DAMAGE_SHIELD_AS_ARMOR, /**< Turret damage shield to armor modifier. */
   SS_TYPE_P_TURRET_DAMAGE_ARMOR_AS_SHIELD, /**< Turret damage shield to armor modifier. */

   /* Bolt weapons. */
   SS_TYPE_A_BOLT_CHARGE, /**< Bolt charge modifier. */
   SS_TYPE_D_BOLT_CHARGE_MOD, /**< Bolt charge multiplier. */
   SS_TYPE_D_BOLT_DAMAGE, /**< Bolt damage multiplier. */
   SS_TYPE_D_BOLT_FIRERATE, /**< Bolt fire rate multiplier. */
   SS_TYPE_D_BOLT_RANGE, /**< Bolt range multiplier. */
   SS_TYPE_D_BOLT_SPEED, /**< Bolt speed multiplier. */
   SS_TYPE_I_BOLT_SALVO, /**< Bolt salvo modifier. */
   SS_TYPE_A_BOLT_SPREAD, /**< Bolt spread modifier. */
   SS_TYPE_D_BOLT_ENERGY, /**< Bolt energy usage multiplier. */
   SS_TYPE_D_BOLT_HEAT, /**< Bolt heat generation multiplier. */
   SS_TYPE_P_BOLT_DAMAGE_AS_DISABLE, /**< Bolt damage as disable modifier. */
   SS_TYPE_P_BOLT_DISABLE_AS_DAMAGE, /**< Bolt disable as damage modifier. */
   SS_TYPE_P_BOLT_DAMAGE_SHIELD_AS_ARMOR, /**< Bolt damage shield to armor modifier. */
   SS_TYPE_P_BOLT_DAMAGE_ARMOR_AS_SHIELD, /**< Bolt damage shield to armor modifier. */

   /* Beams. */
   SS_TYPE_D_BEAM_DAMAGE, /**< Beam damage multiplier. */
   SS_TYPE_D_BEAM_DURATION, /**< Beam duration multiplier. */
   SS_TYPE_D_BEAM_COOLDOWN, /**< Beam cooldown multiplier. */
   SS_TYPE_D_BEAM_RANGE, /**< Beam range multiplier. */
   SS_TYPE_D_BEAM_TURN, /**< Beam turn rate multiplier. */
   SS_TYPE_D_BEAM_ENERGY, /**< Beam energy usage multiplier. */
   SS_TYPE_D_BEAM_HEAT, /**< Beam heat generation multiplier. */
   SS_TYPE_P_BEAM_DAMAGE_AS_DISABLE, /**< Beam damage as disable modifier. */
   SS_TYPE_P_BEAM_DISABLE_AS_DAMAGE, /**< Beam disable as damage modifier. */
   SS_TYPE_P_BEAM_DAMAGE_SHIELD_AS_ARMOR, /**< Beam damage shield to armor modifier. */
   SS_TYPE_P_BEAM_DAMAGE_ARMOR_AS_SHIELD, /**< Beam damage armor to shield modifier. */

   /* Launchers. */
   SS_TYPE_D_LAUNCH_DAMAGE, /**< Launcher damage multiplier. */
   SS_TYPE_D_LAUNCH_RATE, /**< Launcher fire rate multiplier. */
   SS_TYPE_D_LAUNCH_RANGE, /**< Launcher range multiplier. */
   SS_TYPE_D_LAUNCH_SPEED, /**< Launcher speed multiplier. */
   SS_TYPE_I_LAUNCH_SALVO, /**< Launcher salvo modifier. */
   SS_TYPE_A_LAUNCH_SPREAD, /**< Launcher spread modifier. */
   SS_TYPE_D_AMMO_CAPACITY, /**< Launcher capacity multiplier. */
   SS_TYPE_D_LAUNCH_RELOAD, /**< Launcher reload rate multiplier. */
   SS_TYPE_P_LAUNCH_DAMAGE_AS_DISABLE, /**< Launcher damage as disable modifier. */
   SS_TYPE_P_LAUNCH_DISABLE_AS_DAMAGE, /**< Launcher disable as damage modifier. */
   SS_TYPE_P_LAUNCH_DAMAGE_SHIELD_AS_ARMOR, /**< Launcher damage shield to armor modifier. */
   SS_TYPE_P_LAUNCH_DAMAGE_ARMOR_AS_SHIELD, /**< Launcher damage shield to armor modifier. */

   /* Fighter bays. */
   SS_TYPE_D_FBAY_CAPACITY, /**< Fighter bay capacity multiplier. */
   SS_TYPE_D_FBAY_RATE, /**< Fighter bay launch rate multiplier. */
   SS_TYPE_D_FBAY_RELOAD, /**< Fighter bay reload rate multiplier. */
   SS_TYPE_D_FBAY_DAMAGE, /**< Fighter bay fighter damage multiplier. */
   SS_TYPE_D_FBAY_HEALTH, /**< Fighter bay fighter shield/armor multiplier. */
   SS_TYPE_D_FBAY_MOVEMENT, /**< Fighter bay fighter turn/thrust/speed multiplier. */

   /* Speed. */
   SS_TYPE_A_SPEED, /**< Speed modifier. */
   SS_TYPE_D_SPEED_MOD, /**< Speed multiplier. */
   SS_TYPE_A_TURN, /**< Turn modifier. */
   SS_TYPE_D_TURN_MOD, /**< Turn multiplier. */
   SS_TYPE_A_THRUST, /**< Acceleration modifier. */
   SS_TYPE_D_THRUST_MOD, /**< Acceleration multiplier. */
   SS_TYPE_P_REVERSE_THRUST, /**< Reverse acceleration modifier. */
   SS_TYPE_D_TIME_MOD, /**< Time constant multiplier. */
   SS_TYPE_D_TIME_SPEEDUP, /**< Time dilation multiplier. */

   /* Mobility. */
   SS_TYPE_A_FUEL, /**< Fuel modifier. */
   SS_TYPE_A_FUEL_REGEN, /** Fuel regeneration modifier. */
   SS_TYPE_D_JUMP_DELAY, /**< Jump time multiplier. */
   SS_TYPE_D_LAND_DELAY, /**< Takeoff time multiplier. */
   SS_TYPE_D_JUMP_DISTANCE, /**< Jump radius multiplier. */
   SS_TYPE_B_INSTANT_JUMP, /**< Instant jump. */

   /* Health. */
   SS_TYPE_A_SHIELD, /**< Shield modifier. */
   SS_TYPE_D_SHIELD_MOD, /**< Shield multiplier. */
   SS_TYPE_A_SHIELD_REGEN, /**< Shield regeneration modifier. */
   SS_TYPE_D_SHIELD_REGEN_MOD, /**< Shield regeneration multiplier. */
   SS_TYPE_A_SHIELD_REGEN_MALUS, /**< Shield regeneration inverse modifier. */
   SS_TYPE_P_SHIELD_DYNAMO, /**< Shield dynamo modifier. */
   SS_TYPE_A_ARMOUR, /**< Armor modifier. */
   SS_TYPE_D_ARMOUR_MOD, /**< Armor multiplier. */
   SS_TYPE_A_ARMOUR_REGEN, /**< Armor regeneration modifier. */
   SS_TYPE_D_ARMOUR_REGEN_MOD, /**< Armor regeneration multiplier. */
   SS_TYPE_A_ARMOUR_REGEN_MALUS, /**< Armor regeneration inverse modifier. */
   SS_TYPE_P_ARMOUR_DYNAMO, /**< Armor dynamo modifier. */
   SS_TYPE_A_ENERGY, /**< Energy modifier. */
   SS_TYPE_D_ENERGY_MOD, /**< Energy multiplier. */
   SS_TYPE_A_ENERGY_REGEN, /**< Energy regeneration modifier. */
   SS_TYPE_D_ENERGY_REGEN_MOD, /**< Energy regeneration multiplier. */
   SS_TYPE_A_ENERGY_REGEN_MALUS, /**< Energy regeneration inverse modifier. */
   SS_TYPE_P_ABSORB, /**< Absorb modifier. */
   SS_TYPE_P_ABSORB_DYNAMO, /**< Absorb dynamo modifier. */
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
   int utility_slots; /**< Bonus utility slots. */
   int structure_slots; /**< Bonus structural slots. */

   /* Forward weapons. */
   double fwd_damage; /**< Forward damage multiplier. */
   double fwd_firerate; /**< Forward fire rate multiplier. */
   double fwd_range; /**< Forward range multiplier. */
   double fwd_speed; /**< Forward bolt speed multiplier. */
   int fwd_salvo; /**< Forward bolt salvo modifier. */
   double fwd_spread; /**< Forward bolt spread modifier. */
   double fwd_energy; /**< Forward energy usage multiplier. */
   double fwd_heat; /**< Forward heat generation multiplier. */
   double fwd_dam_as_dis; /**< Forward damage as disable modifier. */
   double fwd_dis_as_dam; /**< Forward disable as damage modifier. */
   double fwd_dam_shield_as_armor; /**< Forward damage shield to armor modifier. */
   double fwd_dam_armor_as_shield; /**< Forward damage armor to shield modifier. */

   /* Turrets. */
   double tur_damage; /**< Turret damage multiplier. */
   double tur_firerate; /**< Turret fire rate multiplier. */
   double tur_range; /**< Turret range multiplier. */
   double tur_speed; /**< Turret bolt speed multiplier. */
   int tur_salvo; /**< Turret bolt salvo modifier. */
   double tur_spread; /**< Turret bolt spread modifier. */
   double tur_energy; /**< Turret energy usage multiplier. */
   double tur_heat; /**< Turret heat generation multiplier. */
   double tur_dam_as_dis; /**< Turret damage as disable modifier. */
   double tur_dis_as_dam; /**< Turret disable as damage modifier. */
   double tur_dam_shield_as_armor; /**< Turret damage shield to armor modifier. */
   double tur_dam_armor_as_shield; /**< Turret damage armor to shield modifier. */

   /* Bolt weapons. */
   double blt_charge; /**< Bolt charge modifier. */
   double blt_charge_mod; /**< Bolt charge multiplier. */
   double blt_damage; /**< Bolt damage multiplier. */
   double blt_firerate; /**< Bolt fire rate multiplier. */
   double blt_range; /**< Bolt range multiplier. */
   double blt_speed; /**< Bolt speed multiplier. */
   int blt_salvo; /**< Bolt salvo modifier. */
   double blt_spread; /**< Bolt spread modifier. */
   double blt_energy; /**< Bolt energy usage multiplier. */
   double blt_heat; /**< Bolt heat generation multiplier. */
   double blt_dam_as_dis; /**< Bolt damage as disable modifier. */
   double blt_dis_as_dam; /**< Bolt disable as damage modifier. */
   double blt_dam_shield_as_armor; /**< Bolt damage shield to armor modifier. */
   double blt_dam_armor_as_shield; /**< Bolt damage armor to shield modifier. */

   /* Beams. */
   double bem_damage; /**< Beam damage multiplier. */
   double bem_duration; /**< Beam duration multiplier. */
   double bem_cooldown; /**< Beam cooldown multiplier. */
   double bem_range; /**< Beam range multiplier. */
   double bem_turn; /**< Beam turn rate multiplier. */
   double bem_energy; /**< Beam energy usage multiplier. */
   double bem_heat; /**< Beam heat generation multiplier. */
   double bem_dam_as_dis; /**< Beam damage as disable modifier. */
   double bem_dis_as_dam; /**< Beam disable as damage modifier. */
   double bem_dam_shield_as_armor; /**< Beam damage shield to armor modifier. */
   double bem_dam_armor_as_shield; /**< Beam damage armor to shield modifier. */

   /* Launchers. */
   double launch_damage; /**< Launcher damage multiplier. */
   double launch_rate; /**< Launcher fire rate multiplier. */
   double launch_range; /**< Launcher range multiplier. */
   double launch_speed; /**< Launcher rocket speed multiplier. */
   int launch_salvo; /**< Launcher salvo modifier. */
   double launch_spread; /**< Launcher spread modifier. */
   double ammo_capacity; /**< Launcher ammo capacity multiplier. */
   double launch_reload; /**< Launcher reload rate multiplier. */
   double launch_dam_as_dis; /**< Launcher damage as disable modifier. */
   double launch_dis_as_dam; /**< Launcher disable as damage modifier. */
   double launch_dam_shield_as_armor; /**< Launcher damage shield to armor modifier. */
   double launch_dam_armor_as_shield; /**< Launcher damage armor to shield modifier. */

   /* Fighter bays. */
   double fbay_capacity; /**< Fighter bay fighter turn/thrust/speed multiplier. */
   double fbay_rate; /**< Fighter bay launch rate multiplier. */
   double fbay_reload; /**< Fighter bay reload rate multiplier. */
   double fbay_damage; /**< Fighter bay fighter damage multiplier. */
   double fbay_health; /**< Fighter bay fighter health multiplier. */
   double fbay_movement; /**< Fighter bay fighter shield/armor multiplier. */

   /* Speed. */
   double speed; /**< Speed modifier. */
   double speed_mod; /**< Speed multiplier. */
   double turn; /**< Turn modifier. */
   double turn_mod; /**< Turn multiplier. */
   double thrust; /**< Acceleration modifier. */
   double thrust_mod; /**< Acceleration multiplier. */
   double reverse_thrust; /**< Reverse thrust modifier. */
   double time_mod; /**< Time constant multiplier. */
   double time_speedup; /**< Time dilation multiplier. */

   /* Mobility. */
   double fuel; /**< Fuel modifier. */
   double fuel_regen; /**< Fuel regeneration modifier. */
   double jump_delay; /**< Jump time multiplier. */
   double land_delay; /**< Takeoff time multiplier. */
   double jump_distance; /**< Jump radius multiplier. */
   int misc_instant_jump; /**< Instant jump. */

   /* Health. */
   double shield; /**< Shield modifier. */
   double shield_mod; /**< Shield multiplier. */
   double shield_regen; /**< Shield regeneration modifier. */
   double shield_regen_mod; /**< Shield regeneration multiplier. */
   double shield_regen_malus; /**< Shield regeneration inverse modifier. */
   double shield_dynamo; /**< Shield dynamo modifier. */
   double armour; /**< Armor modifier. */
   double armour_mod; /**< Armor multiplier. */
   double armour_regen; /**< Armor regeneration modifier. */
   double armour_regen_mod; /**< Armor regeneration multiplier. */
   double armour_regen_malus; /**< Armor regeneration inverse modifier. */
   double armour_dynamo; /**< Armor dynamo modifier. */
   double energy; /**< Energy modifier. */
   double energy_mod; /**< Energy multiplier. */
   double energy_regen; /**< Energy regeneration modifier. */
   double energy_regen_mod; /**< Energy regeneration multiplier. */
   double energy_regen_malus; /**< Energy regeneration inverse modifier. */
   double absorb; /**< Absorb modifier. */
   double absorb_dynamo; /**< Absorb dynamo modifier. */
   double heat_dissipation; /**< Heat dissipation multiplier. */
   double stress_dissipation; /**< Stress dissipation multiplier. */
   double cooldown_time; /**< Active cooldown time multiplier. */

   /* General */
   double cargo_mod;          /**< Cargo space multiplier. */

   /* Freighter-type. */
   double cargo_inertia;   /**< Lowers the effect of cargo mass. */

   /* Stealth. */
   double rdr_range;       /**< Radar range. */
   double rdr_jump_range;  /**< Jump detection range. */
   double rdr_range_mod;   /**< Radar range modifier. */
   double rdr_jump_range_mod; /**< Jump detection range modifier. */
   double rdr_enemy_range_mod; /**< Enemy radar range modifier. */

   /* Misc. */
   double nebu_absorb_shield; /**< Shield nebula resistance. */
   double nebu_absorb_armour; /**< Armour nebula resistance. */
   int misc_asteroid_scan;   /**< Able to scan asteroids. */
   int cargo;                 /**< Maximum cargo modifier. */
   double loot_mod;           /**< Boarding loot reward bonus. */
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
