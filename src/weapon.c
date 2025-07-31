/*
 * See Licensing and Copyright notice in naev.h
 */

/**
 * @file weapon.c
 *
 * @brief Handles all the weapons in game.
 *
 * Weapons are what gets created when a pilot shoots.  They are based
 * on the outfit that created them.
 */


/** @cond */
#include <math.h>
#include <stdlib.h>

#include "naev.h"
/** @endcond */

#include "weapon.h"

#include "array.h"
#include "ai.h"
#include "camera.h"
#include "collision.h"
#include "damagetype.h"
#include "explosion.h"
#include "gui.h"
#include "hook.h"
#include "log.h"
#include "nstring.h"
#include "opengl.h"
#include "pilot.h"
#include "player.h"
#include "rng.h"
#include "spfx.h"


#define weapon_isSmart(w)     (w->think != NULL) /**< Checks if the weapon w is smart. */

/* Weapon flags. */
#define WEAPON_FLAG_DESTROYED    1
#define weapon_isFlag(w,f)    ((w)->flags & (f))
#define weapon_setFlag(w,f)   ((w)->flags |= (f))
#define weapon_rmFlag(w,f)    ((w)->flags &= ~(f))


/**
 * @struct Weapon
 *
 * @brief In-game representation of a weapon.
 */
typedef struct Weapon_ {
   unsigned int flags; /**< Weapno flags. */
   Solid *solid; /**< Actually has its own solid :) */
   unsigned int ID; /**< Only used for beam weapons. */

   factionId_t faction; /**< faction of pilot that shot it */
   pilotId_t parent; /**< pilot that shot it */
   pilotId_t target; /**< target to hit, only used by seeking things */
   const Outfit* outfit; /**< related outfit that fired it or whatnot */

   const Outfit* launcher; /**< Launcher that fired, used for ammo */
   double real_vel; /**< Keeps track of the real velocity. */
   double dam_mod; /**< Damage modifier. */
   double dam_as_dis_mod; /**< Damage as disable modifier. */
   double dis_as_dam_mod; /**< Disable as damage modifier. */
   double dam_shield_as_armor_mod; /**< Damage shield as armor modifier. */
   double dam_armor_as_shield_mod; /**< Damage armor as shield modifier. */
   int voice; /**< Weapon's voice. */
   double exp_timer; /**< Explosion timer for beams. */
   double life; /**< Total life. */
   double timer; /**< mainly used to see when the weapon was fired */
   double anim; /**< Used for beam weapon graphics and others. */
   double length; /**< Length (used for beam range). */
   GLfloat r; /**< Unique random value . */
   int sprite; /**< Used for spinning outfits. */
   PilotOutfitSlot *mount; /**< Used for beam weapons. */
   double falloff; /**< Point at which damage falls off. */
   double strength; /**< Calculated with falloff. */
   int sx; /**< Current X sprite to use. */
   int sy; /**< Current Y sprite to use. */
   Trail_spfx *trail; /**< Trail graphic if applicable, else NULL. */

   /* position update and render */
   void (*update)(struct Weapon_*, const double, WeaponLayer); /**< Updates the weapon */
   void (*think)(struct Weapon_*, const double); /**< for the smart missiles */
} Weapon;


/* behind player layer */
static Weapon** wbackLayer = NULL; /**< behind pilots */
/* behind player layer */
static Weapon** wfrontLayer = NULL; /**< in front of pilots, behind player */

/* Graphics. */
static gl_vbo  *weapon_vbo     = NULL; /**< Weapon VBO. */
static GLfloat *weapon_vboData = NULL; /**< Data of weapon VBO. */
static size_t weapon_vboSize   = 0; /**< Size of the VBO. */


/* Internal stuff. */
static unsigned int beam_idgen = 0; /**< Beam identifier generator. */


/*
 * Prototypes
 */
/* Creation. */
static double weapon_aimTurret( const Pilot *parent,
      const Pilot *pilot_target, const Vector2d *pos, const Vector2d *vel, double dir,
      double swivel, double time, double track, double track_max );
static void weapon_createBolt(Weapon *w, const PilotOutfitSlot *slot,
      const double dir, const Vector2d* pos, const Vector2d* vel,
      const Pilot* parent, double time);
static void weapon_createAmmo( Weapon *w, const Outfit* outfit, double T,
      const double dir, const Vector2d* pos, const Vector2d* vel, const Pilot* parent, double time );
static Weapon* weapon_create(const PilotOutfitSlot *slot,
      const double dir, const Vector2d* pos, const Vector2d* vel,
      const Pilot* parent, const pilotId_t target, double time);
/* Updating. */
static void weapon_render( Weapon* w, const double dt );
static void weapons_updateLayer( const double dt, const WeaponLayer layer );
static int weapon_checkPilCollide(Weapon* w, const double dt,
      WeaponLayer layer, Pilot* p, int beam, int canPoly, CollPoly* polygon,
      glTexture* gfx);
static void weapon_update( Weapon* w, const double dt, WeaponLayer layer );
static void weapon_sample_trail( Weapon* w );
/* Destruction. */
static void weapon_destroy( Weapon* w );
static void weapon_free( Weapon* w );
static void weapon_explodeLayer( WeaponLayer layer,
      double x, double y, double radius,
      const Pilot *parent, int mode );
static void weapons_purgeLayer( Weapon** layer );
/* Hitting. */
static int weapon_checkCanHit( const Weapon* w, const Pilot *p );
static void weapon_hit( Weapon* w, Pilot* p, Vector2d* pos );
static void weapon_hitAst( Weapon* w, Asteroid* a, WeaponLayer layer, Vector2d* pos );
static void weapon_hitBeam( Weapon* w, Pilot* p, WeaponLayer layer,
      Vector2d pos[2], const double dt );
static void weapon_hitAstBeam( Weapon* w, Asteroid* a, WeaponLayer layer,
      Vector2d pos[2], const double dt );
/* think */
static void think_seeker( Weapon* w, const double dt );
static void think_beam( Weapon* w, const double dt );
/* externed */
void weapon_minimap( const double res, const double w,
      const double h, const RadarShape shape, double alpha );


/**
 * @brief Initializes the weapon stuff.
 */
void weapon_init (void)
{
   wfrontLayer = array_create(Weapon*);
   wbackLayer  = array_create(Weapon*);
}


/**
 * @brief Draws the minimap weapons (used in player.c).
 *
 *    @param res Minimap resolution.
 *    @param w Width of minimap.
 *    @param h Height of minimap.
 *    @param shape Shape of the minimap.
 *    @param alpha Alpha to draw points at.
 */
void weapon_minimap( const double res, const double w,
      const double h, const RadarShape shape, double alpha )
{
   int i, rc, p;
   double x, y;
   Weapon *wp;
   const glColour *c;
   GLsizei offset;
   Pilot *par;

   /* Get offset. */
   p = 0;
   offset = weapon_vboSize;

   if (shape==RADAR_CIRCLE)
      rc = (int)(w*w);
   else
      rc = 0;

   /* Draw the points for weapons on all layers. */
   for (i=0; i<array_size(wbackLayer); i++) {
      wp = wbackLayer[i];

      /* Make sure is in range. */
      if (!pilot_inRange( player.p, wp->solid->pos.x, wp->solid->pos.y ))
         continue;

      /* Get radar position. */
      x = (wp->solid->pos.x - player.p->solid->pos.x) / res;
      y = (wp->solid->pos.y - player.p->solid->pos.y) / res;

      /* Make sure in range. */
      if (shape==RADAR_RECT && (ABS(x)>w/2. || ABS(y)>h/2.))
         continue;
      if (shape==RADAR_CIRCLE && (((x)*(x)+(y)*(y)) > rc))
         continue;

      /* Choose colour based on if it'll hit player. */
      if ((outfit_isSeeker(wp->outfit) && (wp->target != PLAYER_ID))
            || (wp->faction == FACTION_PLAYER))
         c = &cNeutral;
      else {
         if (wp->target == PLAYER_ID)
            c = &cHostile;
         else {
            par = pilot_get(wp->parent);
            if ((par!=NULL) && pilot_isHostile(par))
               c = &cHostile;
            else
               c = &cNeutral;
         }
      }

      /* Set the colour. */
      weapon_vboData[ offset + 4*p + 0 ] = c->r;
      weapon_vboData[ offset + 4*p + 1 ] = c->g;
      weapon_vboData[ offset + 4*p + 2 ] = c->b;
      weapon_vboData[ offset + 4*p + 3 ] = alpha;

      /* Put the pixel. */
      weapon_vboData[ 2*p + 0 ] = x;
      weapon_vboData[ 2*p + 1 ] = y;

      /* "Add" pixel. */
      p++;
   }
   for (i=0; i<array_size(wfrontLayer); i++) {
      wp = wfrontLayer[i];

      /* Make sure is in range. */
      if (!pilot_inRange( player.p, wp->solid->pos.x, wp->solid->pos.y ))
         continue;

      /* Get radar position. */
      x = (wp->solid->pos.x - player.p->solid->pos.x) / res;
      y = (wp->solid->pos.y - player.p->solid->pos.y) / res;

      /* Make sure in range. */
      if (shape==RADAR_RECT && (ABS(x)>w/2. || ABS(y)>h/2.))
         continue;
      if (shape==RADAR_CIRCLE && (((x)*(x)+(y)*(y)) > rc))
         continue;

      /* Choose colour based on if it'll hit player. */
      if (outfit_isSeeker(wp->outfit) && (wp->target != PLAYER_ID))
         c = &cNeutral;
      else if ((wp->target == PLAYER_ID && wp->target != wp->parent)
            || faction_isPlayerEnemy(wp->faction))
         c = &cHostile;
      else
         c = &cNeutral;

      /* Set the colour. */
      weapon_vboData[ offset + 4*p + 0 ] = c->r;
      weapon_vboData[ offset + 4*p + 1 ] = c->g;
      weapon_vboData[ offset + 4*p + 2 ] = c->b;
      weapon_vboData[ offset + 4*p + 3 ] = alpha;

      /* Put the pixel. */
      weapon_vboData[ 2*p + 0 ] = x;
      weapon_vboData[ 2*p + 1 ] = y;

      /* "Add" pixel. */
      p++;
   }

   /* Only render with something to draw. */
   if (p > 0) {
      /* Upload data changes. */
      gl_vboSubData( weapon_vbo, 0, sizeof(GLfloat) * 2*p, weapon_vboData );
      gl_vboSubData( weapon_vbo, offset * sizeof(GLfloat),
            sizeof(GLfloat) * 4*p, &weapon_vboData[offset] );

      gl_beginSmoothProgram(gl_view_matrix);
      gl_vboActivateAttribOffset( weapon_vbo, shaders.smooth.vertex, 0, 2, GL_FLOAT, 0 );
      gl_vboActivateAttribOffset( weapon_vbo, shaders.smooth.vertex_color, offset * sizeof(GLfloat), 4, GL_FLOAT, 0 );
      glDrawArrays( GL_POINTS, 0, p );
      gl_endSmoothProgram();
   }
}


/**
 * @brief The AI of seeker missiles.
 *
 *    @param w Weapon to do the thinking.
 *    @param dt Current delta tick.
 */
static void think_seeker( Weapon* w, const double dt )
{
   double diff;
   Pilot *p;
   Vector2d v;
   double t, turn_max;
   double ewtrack;
   double opt_angle;

   if (w->target == w->parent)
      return; /* no self shooting */

   p = pilot_get(w->target); /* no null pilot */
   if (p == NULL) {
      w->solid->thrust = 0.;
      w->solid->dir_vel = 0.;
      return;
   }

   ewtrack = pilot_weaponTrack(
         pilot_get(w->parent), p, w->launcher->u.lau.rdr_range,
         w->launcher->u.lau.rdr_range_max);

   /* Smart seekers take into account ship velocity. */
   if (w->outfit->u.amm.ai == AMMO_AI_SMART) {
      /* Calculate time to reach target. */
      vect_cset(&v, p->solid->pos.x - w->solid->pos.x,
            p->solid->pos.y - w->solid->pos.y);
      t = vect_odist(&v) / w->outfit->u.amm.speed;

      /* Calculate target's movement. */
      vect_cset(&v, v.x + t*(p->solid->vel.x-w->solid->vel.x),
            v.y + t*(p->solid->vel.y-w->solid->vel.y));

      /* Get the angle now. */
      opt_angle = VANGLE(v);
   }
   else {
      opt_angle = vect_angle(&w->solid->pos, &p->solid->pos);
   }

   /* Set turn. */
   diff = angle_diff(w->solid->dir, opt_angle);
   turn_max = w->outfit->u.amm.turn * ewtrack;
   w->solid->dir_vel = CLAMP(-turn_max, turn_max,
         10 * diff * w->outfit->u.amm.turn);
   w->solid->dir_dest = opt_angle;

   /* Limit speed here */
   w->real_vel = MIN(w->outfit->u.amm.speed,
         w->real_vel + w->outfit->u.amm.thrust*dt);
   vect_pset(&w->solid->vel, w->real_vel, w->solid->dir);
}


/**
 * @brief The pseudo-ai of the beam weapons.
 *
 *    @param w Weapon to do the thinking.
 *    @param dt Current delta tick.
 */
static void think_beam( Weapon* w, const double dt )
{
   Pilot *p, *t;
   AsteroidAnchor *field;
   Asteroid *ast;
   double opt_angle;
   double diff, mod;
   Vector2d v;

   /* Get pilot, if pilot is dead beam is destroyed. */
   p = pilot_get(w->parent);
   if (p == NULL) {
      w->timer = -1.; /* Hack to make it get destroyed next update. */
      return;
   }

   /* Handle energy consumption. */
   if ((w->outfit->type == OUTFIT_TYPE_TURRET_BEAM)
         || p->stats.turret_conversion)
      mod = p->stats.tur_energy;
   else
      mod = p->stats.fwd_energy;
   mod *= p->stats.bem_energy;
   p->energy -= mod * dt*w->outfit->u.bem.energy;
   pilot_heatAddSlotTime( p, w->mount, dt );
   if (p->energy < 0.) {
      p->energy = 0.;
      w->timer = -1;
      return;
   }

   /* Use mount position. */
   pilot_getMount( p, w->mount, &v );
   w->solid->pos.x = p->solid->pos.x + v.x;
   w->solid->pos.y = p->solid->pos.y + v.y;

   /* Handle aiming. */
   t = (w->target != w->parent) ? pilot_get(w->target) : NULL;

   opt_angle = p->solid->dir;
   if (t == NULL) {
      /* Move toward targeted asteroid, if any. */
      if (p->nav_asteroid >= 0) {
         field = &cur_system->asteroids[p->nav_anchor];
         ast = &field->asteroids[p->nav_asteroid];

         opt_angle = vect_angle(&w->solid->pos, &ast->pos);
      }
   }
   else
      opt_angle = vect_angle(&w->solid->pos, &t->solid->pos);

   diff = angle_diff(w->solid->dir, opt_angle);
   mod = p->stats.bem_turn;
   w->solid->dir_vel = CLAMP(
      mod * -w->outfit->u.bem.turn, mod * w->outfit->u.bem.turn,
      10 * diff * mod * w->outfit->u.bem.turn);
   w->solid->dir_dest = opt_angle;

   /* Calculate bounds. */
   if ((w->outfit->type != OUTFIT_TYPE_TURRET_BEAM)
         && !p->stats.turret_conversion) {
      /* Cap rotational velocity depending on its direction. */
      if (w->solid->dir_vel < 0.)
         w->solid->dir_dest = p->solid->dir - w->outfit->u.bem.swivel;
      else if (w->solid->dir_vel > 0.)
         w->solid->dir_dest = p->solid->dir + w->outfit->u.bem.swivel;

      /* If bounds have already been exceeded, force the beam within
       * bounds. */
      diff = angle_diff(w->solid->dir, p->solid->dir);
      if (FABS(diff) > w->outfit->u.bem.swivel) {
         if (diff > 0.)
            w->solid->dir = p->solid->dir - w->outfit->u.bem.swivel;
         else
            w->solid->dir = p->solid->dir + w->outfit->u.bem.swivel;
      }
   }
}


/**
 * @brief Updates all the weapon layers.
 *
 *    @param dt Current delta tick.
 */
void weapons_update( const double dt )
{
   /* When updating, just mark weapons for deletion. */
   weapons_updateLayer(dt,WEAPON_LAYER_BG);
   weapons_updateLayer(dt,WEAPON_LAYER_FG);

   /* Actually purge and remove weapons. */
   weapons_purgeLayer( wbackLayer );
   weapons_purgeLayer( wfrontLayer );
}


/**
 * @brief Updates all the weapons in the layer.
 *
 *    @param dt Current delta tick.
 *    @param layer Layer to update.
 */
static void weapons_updateLayer( const double dt, const WeaponLayer layer )
{
   Weapon **wlayer;
   Weapon *w;
   int i;
   int spfx;
   int s;
   Pilot *p;

   /* Choose layer. */
   switch (layer) {
      case WEAPON_LAYER_BG:
         wlayer = wbackLayer;
         break;
      case WEAPON_LAYER_FG:
         wlayer = wfrontLayer;
         break;

      default:
         WARN(_("Unknown weapon layer!"));
         return;
   }

   for (i=0; i<array_size(wlayer); i++) {
      w = wlayer[i];

      /* Ignore destroyed wapons. */
      if (weapon_isFlag(w, WEAPON_FLAG_DESTROYED))
         continue;

      /* Handle types. */
      switch (w->outfit->type) {

         /* most missiles behave the same */
         case OUTFIT_TYPE_AMMO:

            w->timer -= dt;
            if (w->timer < 0.) {
               spfx = -1;
               /* See if we need armour death sprite. */
               if (outfit_isProp(w->outfit, OUTFIT_PROP_WEAP_BLOWUP_ARMOUR))
                  spfx = outfit_spfxArmour(w->outfit);
               /* See if we need shield death sprite. */
               else if (outfit_isProp(w->outfit, OUTFIT_PROP_WEAP_BLOWUP_SHIELD))
                  spfx = outfit_spfxShield(w->outfit);
               /* Add death sprite if needed. */
               if (spfx != -1) {
                  spfx_add( spfx, w->solid->pos.x, w->solid->pos.y,
                        w->solid->vel.x, w->solid->vel.y,
                        SPFX_LAYER_MIDDLE ); /* presume middle. */
                  /* Add sound if explodes and has it. */
                  s = outfit_soundHit(w->outfit);
                  if (s != -1)
                     w->voice = sound_playPos(s,
                           w->solid->pos.x,
                           w->solid->pos.y,
                           w->solid->vel.x,
                           w->solid->vel.y);
               }
               weapon_destroy(w);
               break;
            }
            break;

         case OUTFIT_TYPE_BOLT:
         case OUTFIT_TYPE_TURRET_BOLT:
            w->timer -= dt;
            if (w->timer < 0.) {
               spfx = -1;
               /* See if we need armour death sprite. */
               if (outfit_isProp(w->outfit, OUTFIT_PROP_WEAP_BLOWUP_ARMOUR))
                  spfx = outfit_spfxArmour(w->outfit);
               /* See if we need shield death sprite. */
               else if (outfit_isProp(w->outfit, OUTFIT_PROP_WEAP_BLOWUP_SHIELD))
                  spfx = outfit_spfxShield(w->outfit);
               /* Add death sprite if needed. */
               if (spfx != -1) {
                  spfx_add( spfx, w->solid->pos.x, w->solid->pos.y,
                        w->solid->vel.x, w->solid->vel.y,
                        SPFX_LAYER_MIDDLE ); /* presume middle. */
                  /* Add sound if explodes and has it. */
                  s = outfit_soundHit(w->outfit);
                  if (s != -1)
                     w->voice = sound_playPos(s,
                           w->solid->pos.x,
                           w->solid->pos.y,
                           w->solid->vel.x,
                           w->solid->vel.y);
               }
               weapon_destroy(w);
               break;
            }
            else if (w->timer < w->falloff)
               w->strength = w->timer / w->falloff;
            break;

         /* Beam weapons handled a part. */
         case OUTFIT_TYPE_BEAM:
         case OUTFIT_TYPE_TURRET_BEAM:
            /* If the parent pilot is dead, destroy the beam to prevent
             * memory access bugs. */
            p = pilot_get(w->parent);
            if (p == NULL) {
               weapon_destroy(w);
               break;
            }

            /* Beams don't have inherent accuracy, so we use the
             * heatAccuracyMod to modulate duration. */
            w->timer -= dt / (1.-pilot_heatAccuracyMod(w->mount->heat_T));
            if (w->timer < 0.
                  || (w->outfit->u.bem.min_duration > 0.
                     && w->mount->stimer < 0.)) {
               pilot_stopBeam(p, w->mount);
               weapon_destroy(w);
               break;
            }
            /* We use the explosion timer to tell when we have to create explosions. */
            w->exp_timer -= dt;
            if (w->exp_timer < 0.) {
               if (w->exp_timer < -1.)
                  w->exp_timer = 0.100;
               else
                  w->exp_timer = -1.;
            }
            break;
         default:
            WARN(_("Weapon of type '%s' has no update implemented yet!"),
                  w->outfit->name);
            break;
      }

      /* Only increment if weapon wasn't destroyed. */
      if (!weapon_isFlag(w, WEAPON_FLAG_DESTROYED))
         weapon_update(w,dt,layer);
   }
}


/**
 * @brief Purges weapons marked for deletion.
 *
 *    @param layer Layer to purge weapons from.
 */
static void weapons_purgeLayer( Weapon** layer )
{
   int i;
   for (i=0; i<array_size(layer); i++) {
      if (weapon_isFlag(layer[i],WEAPON_FLAG_DESTROYED)) {
         weapon_free(layer[i]);
         array_erase( &layer, &layer[i], &layer[i+1] );
         i--;
      }
   }
}


/**
 * @brief Renders all the weapons in a layer.
 *
 *    @param layer Layer to render.
 *    @param dt Current delta tick.
 */
void weapons_render( const WeaponLayer layer, const double dt )
{
   Weapon** wlayer;
   int i;

   switch (layer) {
      case WEAPON_LAYER_BG:
         wlayer = wbackLayer;
         break;
      case WEAPON_LAYER_FG:
         wlayer = wfrontLayer;
         break;

      default:
         WARN(_("Unknown weapon layer!"));
         return;
   }

   for (i=0; i<array_size(wlayer); i++)
      weapon_render( wlayer[i], dt );
}


static void weapon_renderBeam( Weapon* w, const double dt ) {
   double x, y, z;
   gl_Matrix4 projection;

   /* Animation. */
   w->anim += dt;

   /* Load GLSL program */
   glUseProgram(shaders.beam.program);

   /* Zoom. */
   z = cam_getZoom();

   /* Position. */
   gl_gameToScreenCoords( &x, &y, w->solid->pos.x, w->solid->pos.y );

   projection = gl_view_matrix;
   gl_Matrix4_Translate(&projection, x, y, 0.);
   gl_Matrix4_Rotate2d(&projection, w->solid->dir);
   gl_Matrix4_Scale(&projection, w->length*z,
         w->outfit->u.bem.width * z, 1);
   gl_Matrix4_Translate(&projection, 0., -0.5, 0.);

   /* Set the vertex. */
   glEnableVertexAttribArray( shaders.beam.vertex );
   gl_vboActivateAttribOffset( gl_squareVBO, shaders.beam.vertex,
         0, 2, GL_FLOAT, 0 );

   /* Set shader uniforms. */
   gl_Matrix4_Uniform(shaders.beam.projection, projection);
   gl_uniformColor(shaders.beam.color, &w->outfit->u.bem.colour);
   glUniform2f(shaders.beam.dimensions, w->length, w->outfit->u.bem.width);
   glUniform1f(shaders.beam.dt, w->anim);
   glUniform1f(shaders.beam.r, w->r);

   /* Set the subroutine. */
   if (gl_has( OPENGL_SUBROUTINES ))
      glUniformSubroutinesuiv( GL_FRAGMENT_SHADER, 1, &w->outfit->u.bem.shader );

   /* Draw. */
   glDrawArrays( GL_TRIANGLE_STRIP, 0, 4 );

   /* Clear state. */
   glDisableVertexAttribArray( shaders.beam.vertex );
   glUseProgram(0);

   /* anything failed? */
   gl_checkErr();
}


/**
 * @brief Renders an individual weapon.
 *
 *    @param w Weapon to render.
 *    @param dt Current delta tick.
 */
static void weapon_render( Weapon* w, const double dt )
{
   glTexture *gfx;
   glColour c = { .r=1., .g=1., .b=1. };

   /* Don't render destroyed weapons. */
   if (weapon_isFlag(w,WEAPON_FLAG_DESTROYED))
      return;

   switch (w->outfit->type) {
      /* Weapons that use sprites. */
      case OUTFIT_TYPE_AMMO:
      case OUTFIT_TYPE_BOLT:
      case OUTFIT_TYPE_TURRET_BOLT:
         gfx = outfit_gfx(w->outfit);

         /* Alpha based on strength. */
         c.a = w->strength;

         /* Outfit spins around. */
         if (outfit_isProp(w->outfit, OUTFIT_PROP_WEAP_SPIN)) {
            /* Check timer. */
            w->anim -= dt;
            if (w->anim < 0.) {
               w->anim = outfit_spin(w->outfit);

               /* Increment sprite. */
               w->sprite++;
               if (w->sprite >= gfx->sx*gfx->sy)
                  w->sprite = 0;
            }

            /* Render. */
            if (outfit_isBolt(w->outfit) && w->outfit->u.blt.gfx_end)
               gl_blitSpriteInterpolate( gfx, w->outfit->u.blt.gfx_end,
                     w->timer / w->life,
                     w->solid->pos.x, w->solid->pos.y,
                     w->sprite % (int)gfx->sx, w->sprite / (int)gfx->sx, &c );
            else
               gl_blitSprite( gfx, w->solid->pos.x, w->solid->pos.y,
                     w->sprite % (int)gfx->sx, w->sprite / (int)gfx->sx, &c );
         }
         /* Outfit faces direction. */
         else {
            if (outfit_isBolt(w->outfit) && w->outfit->u.blt.gfx_end)
               gl_blitSpriteInterpolate( gfx, w->outfit->u.blt.gfx_end,
                     w->timer / w->life,
                     w->solid->pos.x, w->solid->pos.y, w->sx, w->sy, &c );
            else
               gl_blitSprite( gfx, w->solid->pos.x, w->solid->pos.y, w->sx, w->sy, &c );
         }
         break;

      /* Beam weapons. */
      case OUTFIT_TYPE_BEAM:
      case OUTFIT_TYPE_TURRET_BEAM:
         weapon_renderBeam(w, dt);
         break;

      default:
         WARN(_("Weapon of type '%s' has no render implemented yet!"),
               w->outfit->name);
         break;
   }
}


/**
 * @brief Checks to see if the weapon can hit the pilot.
 *
 *    @param w Weapon to check if hits pilot.
 *    @param p Pilot to check if is hit by weapon.
 *    @return 1 if can be hit, 0 if can't.
 */
static int weapon_checkCanHit( const Weapon* w, const Pilot *p )
{
   Pilot *parent;
   pilotId_t leader_id;

   /* Get some data. */
   parent = pilot_get(w->parent);
   leader_id = 0;
   if (parent != NULL)
      leader_id = parent->parent;

   /* Can't hit invincible stuff. */
   if (pilot_isFlag(p, PILOT_INVINCIBLE))
      return 0;

   /* Can't hit hidden stuff. */
   if (pilot_isFlag(p, PILOT_HIDE))
      return 0;

   /* Can never hit same faction. */
   if (p->faction == w->faction)
      return 0;

   /* Must not be landing nor taking off. */
   if (pilot_isFlag(p, PILOT_LANDING)
         || pilot_isFlag(p, PILOT_TAKEOFF))
      return 0;

   /* Go "through" dead pilots. */
   if (pilot_isFlag(p, PILOT_DEAD))
      return 0;

   /* Player can not hit special pilots. */
   if (((w->faction == FACTION_PLAYER) || (leader_id == PLAYER_ID))
         && pilot_isFlag(p, PILOT_INVINC_PLAYER))
      return 0;

   /* Always hit parent's target. */
   if ((parent != NULL) && (parent->target == p->id))
      return 1;

   /* Player behaves differently. */
   if ((w->faction == FACTION_PLAYER) || (leader_id == PLAYER_ID)) {
      /* Always hit hostiles. */
      if (pilot_isHostile(p))
         return 1;

      /* Miss rest; can be neutral/ally. */
      else
         return 0;
   }

   /* Let hostiles hit player. */
   if (((p->faction == FACTION_PLAYER) || (p->parent == PLAYER_ID))
         && (parent != NULL) && pilot_isHostile(parent))
      return 1;

   /* Hit enemies. */
   if (areEnemies(w->faction, p->faction))
      return 1;

   return 0;
}


/**
 * @brief Checks for collision between a weapon and a pilot.
 *
 *    @param w Weapon to check collision for.
 *    @param dt Current delta tick.
 *    @param layer Layer to which the weapon belongs.
 *    @param p Pilot to check collision with.
 *    @param beam Whether the weapon is a beam.
 *    @param canPoly Whether the weapon can do polygon collision.
 *    @param polygon The weapon's collision polygon if applicable.
 *    @param gfx The weapon's texture.
 *    @return Whether or not the weapon is to be destroyed.
 */
static int weapon_checkPilCollide(Weapon* w, const double dt,
      WeaponLayer layer, Pilot* p, int beam, int canPoly, CollPoly* polygon,
      glTexture* gfx)
{
   int psx, psy;
   int k;
   int usePoly;
   Vector2d crash[2];
   int coll;

   /* Cannot collide with self. */
   if (w->parent == p->id)
      return 0;

   /* Skip targets that the weapon cannot hit. */
   if (!weapon_checkCanHit(w, p))
      return 0;

   psx = p->tsx;
   psy = p->tsy;

   /* See if the ship has a collision polygon. */
   usePoly = canPoly;
   if (array_size(p->ship->polygon) == 0)
      usePoly = 0;

   /* Beam weapons have special collisions. */
   if (beam) {
      /* Check for collision. */
      if (usePoly) {
         k = p->ship->gfx_space->sx * psy + psx;
         coll = CollideLinePolygon(&w->solid->pos, w->solid->dir,
               w->length, &p->ship->polygon[k],
               &p->solid->pos, crash);
      }
      else {
         coll = CollideLineSprite(&w->solid->pos, w->solid->dir,
               w->length, p->ship->gfx_space, psx, psy,
               &p->solid->pos, crash);
      }
      if (coll) {
         weapon_hitBeam(w, p, layer, crash, dt);
         return 0;
      }
   }
   /* Smart weapons only collide with their target. */
   else if (weapon_isSmart(w)) {
      if (p->id == w->target) {
         if (usePoly) {
            k = p->ship->gfx_space->sx * psy + psx;
            coll = CollidePolygon(&p->ship->polygon[k], &p->solid->pos,
                  polygon, &w->solid->pos, crash);
         }
         else {
            coll = CollideSprite(gfx, w->sx, w->sy, &w->solid->pos,
                  p->ship->gfx_space, psx, psy, &p->solid->pos, crash);
         }
         if (coll) {
            weapon_hit(w, p, crash);
            return 1;
         }
      }
   }
   /* Unguided weapons hit any valid pilot. */
   else {
      if (usePoly) {
         k = p->ship->gfx_space->sx * psy + psx;
         coll = CollidePolygon(&p->ship->polygon[k], &p->solid->pos,
               polygon, &w->solid->pos, crash);
      }
      else {
         coll = CollideSprite(gfx, w->sx, w->sy, &w->solid->pos,
               p->ship->gfx_space, psx, psy, &p->solid->pos, crash);
      }

      if (coll) {
         weapon_hit(w, p, crash);
         return 1;
      }
   }

   return 0;
}


/**
 * @brief Updates an individual weapon.
 *
 *    @param w Weapon to update.
 *    @param dt Current delta tick.
 *    @param layer Layer to which the weapon belongs.
 */
static void weapon_update( Weapon* w, const double dt, WeaponLayer layer )
{
   int i, j, b, n;
   int canPoly;
   glTexture *gfx;
   CollPoly *plg, *polygon;
   Vector2d crash[2];
   Pilot *p;
   Pilot *parent;
   AsteroidAnchor *ast;
   Asteroid *a;
   AsteroidType *at;
   Pilot * const *pilot_stack;
   double x, y;

   canPoly = 1;
   gfx = NULL;
   polygon = NULL;
   parent = NULL;
   pilot_stack = pilot_getAll();

   /* Get the sprite direction to speed up calculations. */
   b = outfit_isBeam(w->outfit);
   if (!b) {
      gfx = outfit_gfx(w->outfit);
      gl_getSpriteFromDir( &w->sx, &w->sy, gfx, w->solid->dir );
      n = gfx->sx * w->sy + w->sx;
      plg = outfit_plg(w->outfit);
      polygon = &plg[n];

      /* See if the outfit has a collision polygon. */
      if (outfit_isBolt(w->outfit)) {
         if (array_size(w->outfit->u.blt.polygon) == 0)
            canPoly = 0;
      }
      else if (outfit_isAmmo(w->outfit)) {
         if (array_size(w->outfit->u.amm.polygon) == 0)
            canPoly = 0;
      }
   }
   else {
      parent = pilot_get(w->parent);
      if (parent != NULL) {
         /* Beams need to update their properties online. */
         if (w->outfit->type == OUTFIT_TYPE_BEAM) {
            w->dam_mod = parent->stats.fwd_damage;
            w->dam_as_dis_mod = parent->stats.fwd_dam_as_dis;
            w->dis_as_dam_mod = parent->stats.fwd_dis_as_dam;
            w->dam_shield_as_armor_mod = parent->stats.fwd_dam_shield_as_armor;
            w->dam_armor_as_shield_mod = parent->stats.fwd_dam_armor_as_shield;
         }
         else {
            w->dam_mod = parent->stats.tur_damage;
            w->dam_as_dis_mod = parent->stats.tur_dam_as_dis;
            w->dis_as_dam_mod = parent->stats.tur_dis_as_dam;
            w->dam_shield_as_armor_mod = parent->stats.tur_dam_shield_as_armor;
            w->dam_armor_as_shield_mod = parent->stats.tur_dam_armor_as_shield;
         }
         w->dam_as_dis_mod = CLAMP(0., 1., w->dam_as_dis_mod);
         w->dis_as_dam_mod = CLAMP(0., 1., w->dis_as_dam_mod);
         w->dam_shield_as_armor_mod = CLAMP(0., 1., w->dam_shield_as_armor_mod);
         w->dam_armor_as_shield_mod = CLAMP(0., 1., w->dam_armor_as_shield_mod);
      }
   }

   gl_gameToScreenCoords(&x, &y, w->solid->pos.x, w->solid->pos.y);
   if (!b && ((x < 0) || (x > SCREEN_W) || (y < 0) || (y > SCREEN_H))
         && (w->parent != PLAYER_ID) && (w->faction != FACTION_PLAYER)
         && ((w->parent == 0) || ((parent = pilot_get(w->parent)) == NULL)
            || (parent->parent != PLAYER_ID))) {
      /* If the weapon isn't visible to the player, only check for
       * collisions with its specific target, and the target of its
       * parent. This offers performance benefits at the cost of
       * simplifying combat the player isn't involved in. */
      p = pilot_get(w->target);
      if (p != NULL) {
         if (weapon_checkPilCollide(w, dt, layer, p, b, canPoly, polygon, gfx))
            return;
      }
      if (parent != NULL) {
         p = pilot_get(parent->target);
         if (p != NULL) {
            if (weapon_checkPilCollide(
                  w, dt, layer, p, b, canPoly, polygon, gfx))
               return;
         }
      }
   }
   else {
      for (i=0; i<array_size(pilot_stack); i++) {
         p = pilot_stack[i];
         if (weapon_checkPilCollide(w, dt, layer, p, b, canPoly, polygon, gfx))
            return;
      }
   }

   /* Collide with asteroids*/
   if (outfit_isAmmo(w->outfit)) {
      for (i=0; i<array_size(cur_system->asteroids); i++) {
         ast = &cur_system->asteroids[i];
         for (j=0; j<ast->nb; j++) {
            a = &ast->asteroids[j];
            at = space_getType ( a->type );
            if ( ((a->appearing == ASTEROID_VISIBLE)||(a->appearing == ASTEROID_EXPLODING)) &&
                  CollideSprite( gfx, w->sx, w->sy, &w->solid->pos,
                        at->gfxs[a->gfxID], 0, 0, &a->pos,
                        &crash[0] ) ) {
               weapon_hitAst( w, a, layer, &crash[0] );
               return; /* Weapon is destroyed. */
            }
         }
      }
   }
   else if (outfit_isBolt(w->outfit)) {
      for (i=0; i<array_size(cur_system->asteroids); i++) {
         ast = &cur_system->asteroids[i];
         for (j=0; j<ast->nb; j++) {
            a = &ast->asteroids[j];
            at = space_getType ( a->type );
            if ( ((a->appearing == ASTEROID_VISIBLE)||(a->appearing == ASTEROID_EXPLODING)) &&
                  CollideSprite( gfx, w->sx, w->sy, &w->solid->pos,
                        at->gfxs[a->gfxID], 0, 0, &a->pos,
                        &crash[0] ) ) {
               weapon_hitAst( w, a, layer, &crash[0] );
               return; /* Weapon is destroyed. */
            }
         }
      }
   }
   else if (b) { /* Beam */
      for (i=0; i<array_size(cur_system->asteroids); i++) {
         ast = &cur_system->asteroids[i];
         for (j=0; j<ast->nb; j++) {
            a = &ast->asteroids[j];
            at = space_getType ( a->type );
            if (((a->appearing == ASTEROID_VISIBLE)
                     || (a->appearing == ASTEROID_EXPLODING))
                  && CollideLineSprite(&w->solid->pos, w->solid->dir,
                        w->length, at->gfxs[a->gfxID], 0, 0, &a->pos, crash)) {
               weapon_hitAstBeam(w, a, layer, crash, dt);
               /* No return because beam can still think, it's not
                * destroyed like the other weapons.*/
            }
         }
      }
   }

   /* smart weapons also get to think their next move */
   if (weapon_isSmart(w))
      (*w->think)(w,dt);

   /* Update the solid position. */
   (*w->solid->update)(w->solid, dt);

   /* Update the sound. */
   sound_updatePos(w->voice, w->solid->pos.x, w->solid->pos.y,
         w->solid->vel.x, w->solid->vel.y);

   /* Update the trail. */
   if (w->trail != NULL)
      weapon_sample_trail( w );
}


/**
 * @brief Updates the animated trail for a weapon.
 */
static void weapon_sample_trail( Weapon* w )
{
   double a, dx, dy;
   TrailMode mode;

   /* Compute the engine offset. */
   a  = w->solid->dir;
   dx = w->outfit->u.amm.trail_x_offset * cos(a);
   dy = w->outfit->u.amm.trail_x_offset * sin(a);

   /* Set the colour. */
   if (w->solid->thrust > 0)
      mode = MODE_AFTERBURN;
   else if (w->solid->dir_vel != 0.)
      mode = MODE_GLOW;
   else
      mode = MODE_IDLE;

   spfx_trail_sample( w->trail, w->solid->pos.x + dx, w->solid->pos.y + dy*M_SQRT1_2, mode, 0 );
}


/**
 * @brief Informs the AI if needed that it's been hit.
 *
 *    @param p Pilot being hit.
 *    @param shooter Pilot that shot.
 *    @param dmg Damage done to p.
 */
static void weapon_hitAI( Pilot *p, Pilot *shooter, double dmg )
{
   int i;
   double d;
   Pilot * const *pilot_stack;

   /* Must be a valid shooter. */
   if (shooter == NULL)
      return;

   /* Must not be disabled. */
   if (pilot_isDisabled(p))
      return;

   /* Player is handled differently. */
   if ((shooter->faction == FACTION_PLAYER)
         || (shooter->parent == PLAYER_ID)) {
      pilot_stack = pilot_getAll();

      /* Increment damage done to by player. */
      p->player_damage += dmg / (p->shield_max + p->armour_max);

      /* If damage is over threshold, inform pilot or if is targeted. */
      if ((p->player_damage > PILOT_HOSTILE_THRESHOLD) ||
            (shooter->target==p->id)) {
         /* Inform attacked. */
         ai_attacked( p, shooter->id, dmg );

         /* Trigger a pseudo-distress that incurs no faction loss. */
         for (i=0; i<array_size(pilot_stack); i++) {
            /* Skip if unsuitable. */
            if ((pilot_stack[i]->ai == NULL) || (pilot_stack[i]->id == p->id) ||
                  (pilot_isFlag(pilot_stack[i], PILOT_DEAD)) ||
                  (pilot_isFlag(pilot_stack[i], PILOT_DELETE)))
               continue;

            /* Pilots within 1/4 of their viewing range will immediately
             * notice hostile actions. */
            d = vect_dist2( &p->solid->pos, &pilot_stack[i]->solid->pos );
            if (d > pilot_stack[i]->rdr_range*cur_system->rdr_range_mod / 4)
               continue;

            /* Send AI the distress signal. */
            ai_getDistress( pilot_stack[i], p, shooter );
         }

         /* Set as hostile. */
         pilot_setHostile(p);
      }
   }
   /* Otherwise just inform of being attacked. */
   else
      ai_attacked( p, shooter->id, dmg );
}


/**
 * @brief Weapon hit the pilot.
 *
 *    @param w Weapon involved in the collision.
 *    @param p Pilot that got hit.
 *    @param pos Position of the hit.
 */
static void weapon_hit( Weapon* w, Pilot* p, Vector2d* pos )
{
   Pilot *parent;
   int s, spfx;
   double damage;
   double disable;
   double dmg_shield;
   double dmg_armor;
   WeaponLayer spfx_layer;
   Damage dmg;
   const Damage *odmg;

   /* Get general details. */
   odmg = outfit_damage(w->outfit);
   parent = pilot_get(w->parent);
   damage = w->dam_mod * w->strength * odmg->damage;
   disable = w->dam_mod * w->strength * odmg->disable;
   dmg_shield = odmg->shield_pct;
   dmg_armor = odmg->armor_pct;

   dmg.type = odmg->type;
   dmg.penetration = odmg->penetration;
   dmg.damage = MAX(0.,
         damage*(1.-w->dam_as_dis_mod) + disable*w->dis_as_dam_mod);
   dmg.disable = MAX(0.,
         disable*(1.-w->dis_as_dam_mod) + damage*w->dam_as_dis_mod);
   dmg.shield_pct = MAX(0.,
         dmg_shield*(1.-w->dam_shield_as_armor_mod)
            + dmg_armor*w->dam_armor_as_shield_mod);
   dmg.armor_pct = MAX(0.,
         dmg_armor*(1.-w->dam_armor_as_shield_mod)
            + dmg_shield*w->dam_shield_as_armor_mod);
   dmg.knockback_pct = odmg->knockback_pct;
   dmg.recoil_pct = odmg->recoil_pct;

   /* Play sound if they have it. */
   s = outfit_soundHit(w->outfit);
   if (s != -1)
      w->voice = sound_playPos( s,
            w->solid->pos.x,
            w->solid->pos.y,
            w->solid->vel.x,
            w->solid->vel.y);

   /* Have pilot take damage and get real damage done. */
   damage = pilot_hit( p, w->solid, w->parent, &dmg, 1 );

   /* Get the layer. */
   spfx_layer = (p==player.p) ? SPFX_LAYER_FRONT : SPFX_LAYER_MIDDLE;
   /* Choose spfx. */
   if (p->shield > 0.)
      spfx = outfit_spfxShield(w->outfit);
   else
      spfx = outfit_spfxArmour(w->outfit);
   /* Add sprite, layer depends on whether player shot or not. */
   spfx_add( spfx, pos->x, pos->y,
         VX(p->solid->vel), VY(p->solid->vel), spfx_layer );

   /* Inform AI that it's been hit. */
   weapon_hitAI( p, parent, damage );

   /* no need for the weapon particle anymore */
   weapon_destroy(w);
}

/**
 * @brief Weapon hit an asteroid.
 *
 *    @param w Weapon involved in the collision.
 *    @param a Asteroid that got hit.
 *    @param layer Layer to which the weapon belongs.
 *    @param pos Position of the hit.
 */
static void weapon_hitAst( Weapon* w, Asteroid* a, WeaponLayer layer, Vector2d* pos )
{
   int s, spfx;
   double damage;
   double disable;
   double dmg_shield;
   double dmg_armor;
   Damage dmg;
   const Damage *odmg;

   /* Get general details. */
   odmg = outfit_damage(w->outfit);
   damage = w->dam_mod * w->strength * odmg->damage;
   disable = w->dam_mod * w->strength * odmg->disable;
   dmg_shield = odmg->shield_pct;
   dmg_armor = odmg->armor_pct;

   dmg.type = odmg->type;
   dmg.penetration = odmg->penetration;
   dmg.damage = MAX(0.,
         damage*(1.-w->dam_as_dis_mod) + disable*w->dis_as_dam_mod);
   dmg.disable = MAX(0.,
         disable*(1.-w->dis_as_dam_mod) + damage*w->dam_as_dis_mod);
   dmg.shield_pct = MAX(0.,
         dmg_shield*(1.-w->dam_shield_as_armor_mod)
            + dmg_armor*w->dam_armor_as_shield_mod);
   dmg.armor_pct = MAX(0.,
         dmg_armor*(1.-w->dam_armor_as_shield_mod)
            + dmg_shield*w->dam_shield_as_armor_mod);
   dmg.knockback_pct = odmg->knockback_pct;
   dmg.recoil_pct = odmg->recoil_pct;

   /* Play sound if they have it. */
   s = outfit_soundHit(w->outfit);
   if (s != -1)
      w->voice = sound_playPos( s,
            w->solid->pos.x,
            w->solid->pos.y,
            w->solid->vel.x,
            w->solid->vel.y);

   /* Add the spfx */
   spfx = outfit_spfxArmour(w->outfit);
   spfx_add( spfx, pos->x, pos->y,VX(a->vel), VY(a->vel), layer );

   weapon_destroy(w);

   if (a->appearing != ASTEROID_EXPLODING)
      asteroid_hit( a, &dmg );
}


/**
 * @brief Weapon hit the pilot.
 *
 *    @param w Weapon involved in the collision.
 *    @param p Pilot that got hit.
 *    @param layer Layer to which the weapon belongs.
 *    @param pos Position of the hit.
 *    @param dt Current delta tick.
 */
static void weapon_hitBeam( Weapon* w, Pilot* p, WeaponLayer layer,
      Vector2d pos[2], const double dt )
{
   (void) layer;
   Pilot *parent;
   int spfx;
   WeaponLayer spfx_layer;
   double damage;
   double disable;
   double dmg_shield;
   double dmg_armor;
   Damage dmg;
   const Damage *odmg;
   HookParam hparam[2];
   HookParam ghparam[4];

   /* Get general details. */
   odmg = outfit_damage(w->outfit);
   parent = pilot_get(w->parent);
   damage = w->dam_mod * w->strength * odmg->damage * dt ;
   disable = w->dam_mod * w->strength * odmg->disable * dt;
   dmg_shield = odmg->shield_pct;
   dmg_armor = odmg->armor_pct;

   dmg.type = odmg->type;
   dmg.penetration = odmg->penetration;
   dmg.damage = MAX(0.,
         damage*(1.-w->dam_as_dis_mod) + disable*w->dis_as_dam_mod);
   dmg.disable = MAX(0.,
         disable*(1.-w->dis_as_dam_mod) + damage*w->dam_as_dis_mod);
   dmg.shield_pct = MAX(0.,
         dmg_shield*(1.-w->dam_shield_as_armor_mod)
            + dmg_armor*w->dam_armor_as_shield_mod);
   dmg.armor_pct = MAX(0.,
         dmg_armor*(1.-w->dam_armor_as_shield_mod)
            + dmg_shield*w->dam_shield_as_armor_mod);
   dmg.knockback_pct = odmg->knockback_pct;
   dmg.recoil_pct = odmg->recoil_pct;

   /* Have pilot take damage and get real damage done. */
   damage = pilot_hit( p, w->solid, w->parent, &dmg, 1 );

   /* Add sprite, layer depends on whether player shot or not. */
   if (w->exp_timer == -1.) {
      /* Get the layer. */
      spfx_layer = (p==player.p) ? SPFX_LAYER_FRONT : SPFX_LAYER_MIDDLE;

      /* Choose spfx. */
      if (p->shield > 0.)
         spfx = outfit_spfxShield(w->outfit);
      else
         spfx = outfit_spfxArmour(w->outfit);

      /* Add graphic. */
      spfx_add( spfx, pos[0].x, pos[0].y,
            VX(p->solid->vel), VY(p->solid->vel), spfx_layer );
      spfx_add( spfx, pos[1].x, pos[1].y,
            VX(p->solid->vel), VY(p->solid->vel), spfx_layer );
      w->exp_timer = -2;

      /* Inform AI that it's been hit, to not saturate ai Lua with messages. */
      weapon_hitAI( p, parent, damage );
   }
   else {
      /* Even if we don't inform the AI, run the attacked hook,
       * otherwise we'll have weird broken cases in Lua code that
       * expects all damage to count. */
      ghparam[0].type = HOOK_PARAM_PILOT;
      ghparam[0].u.lp = p->id;
      if (parent != NULL) {
         hparam[0].type = HOOK_PARAM_PILOT;
         hparam[0].u.lp = parent->id;
         ghparam[1].type = HOOK_PARAM_PILOT;
         ghparam[1].u.lp = parent->id;
      }
      else {
         hparam[0].type = HOOK_PARAM_NIL;
         ghparam[1].type = HOOK_PARAM_NIL;
      }
      hparam[1].type = HOOK_PARAM_NUMBER;
      hparam[1].u.num = damage;
      ghparam[2].type = HOOK_PARAM_NUMBER;
      ghparam[2].u.num = damage;
      ghparam[3].type = HOOK_PARAM_SENTINEL;

      pilot_runHookParam(p, PILOT_HOOK_ATTACKED, hparam, 2);
      hooks_runParam("attacked", ghparam);
   }
}


/**
 * @brief Weapon hit an asteroid.
 *
 *    @param w Weapon involved in the collision.
 *    @param a Asteroid that got hit.
 *    @param layer Layer to which the weapon belongs.
 *    @param pos Position of the hit.
 *    @param dt Current delta tick.
 */
static void weapon_hitAstBeam( Weapon* w, Asteroid* a, WeaponLayer layer,
      Vector2d pos[2], const double dt )
{
   (void) layer;
   int spfx;
   double damage;
   double disable;
   double dmg_shield;
   double dmg_armor;
   Damage dmg;
   const Damage *odmg;

   /* Get general details. */
   odmg = outfit_damage(w->outfit);
   damage = w->dam_mod * w->strength * odmg->damage * dt ;
   disable = w->dam_mod * w->strength * odmg->disable * dt;
   dmg_shield = odmg->shield_pct;
   dmg_armor = odmg->armor_pct;

   dmg.type = odmg->type;
   dmg.penetration = odmg->penetration;
   dmg.damage = MAX(0.,
         damage*(1.-w->dam_as_dis_mod) + disable*w->dis_as_dam_mod);
   dmg.disable = MAX(0.,
         disable*(1.-w->dis_as_dam_mod) + damage*w->dam_as_dis_mod);
   dmg.shield_pct = MAX(0.,
         dmg_shield*(1.-w->dam_shield_as_armor_mod)
            + dmg_armor*w->dam_armor_as_shield_mod);
   dmg.armor_pct = MAX(0.,
         dmg_armor*(1.-w->dam_armor_as_shield_mod)
            + dmg_shield*w->dam_shield_as_armor_mod);
   dmg.knockback_pct = odmg->knockback_pct;
   dmg.recoil_pct = odmg->recoil_pct;

   asteroid_hit( a, &dmg );

   /* Add sprite. */
   if (w->exp_timer == -1.) {
      spfx = outfit_spfxArmour(w->outfit);

      /* Add graphic. */
      spfx_add( spfx, pos[0].x, pos[0].y,
            VX(a->vel), VY(a->vel), SPFX_LAYER_MIDDLE );
      spfx_add( spfx, pos[1].x, pos[1].y,
            VX(a->vel), VY(a->vel), SPFX_LAYER_MIDDLE );
      w->exp_timer = -2;
   }
}


/**
 * @brief Gets the aim position of a turret weapon.
 *
 *    @param parent Parent of the weapon.
 *    @param pilot_target Target of the weapon.
 *    @param pos Position of the turret.
 *    @param vel Velocity of the turret.
 *    @param dir Direction facing parent ship and turret.
 *    @param swivel Maximum angle between weapon and straight ahead.
 *    @param time Expected flight time.
 *    @param track Radar optimal range.
 *    @param track_max Radar max range.
 */
static double weapon_aimTurret(const Pilot *parent, const Pilot *pilot_target,
      const Vector2d *pos, const Vector2d *vel, double dir, double swivel,
      double time, double track, double track_max)
{
   AsteroidAnchor *field;
   Asteroid *ast;
   Vector2d *target_pos;
   Vector2d *target_vel;
   double rdir, adir, lead;
   double rx, ry, x, y, t;
   double off;

   if (pilot_target != NULL) {
      target_pos = &pilot_target->solid->pos;
      target_vel = &pilot_target->solid->vel;
   }
   else {
      if (parent->nav_asteroid < 0)
         return dir;

      field = &cur_system->asteroids[parent->nav_anchor];
      ast = &field->asteroids[parent->nav_asteroid];
      target_pos = &ast->pos;
      target_vel = &ast->vel;
   }

   /* Get the vector : shooter -> target */
   rx = target_pos->x - pos->x;
   ry = target_pos->y - pos->y;

   /* Try to predict where the enemy will be. */
   t = time;
   if (t == INFINITY)  /*Postprocess (t = INFINITY means target is not hittable)*/
      t = 0.;

   /* Position is calculated on where it should be */
   x = (target_pos->x + target_vel->x*t) - (pos->x + vel->x*t);
   y = (target_pos->y + target_vel->y*t) - (pos->y + vel->y*t);

   /* Store the accurate aiming direction. */
   adir = ANGLE(x, y);

   /* Apply weapon tracking inaccuracy (pilots only, not asteroids). */
   if (pilot_target != NULL) {
      /* Lead angle is determined from ewarfare. */
      lead = pilot_weaponTrack(parent, pilot_target, track, track_max);
      x = lead * x + (1.-lead) * rx;
      y = lead * y + (1.-lead) * ry;
   }
   rdir = ANGLE(x, y);

   /* Apply turret conversion if applicable. */
   if (parent->stats.turret_conversion)
      swivel = M_PI;

   /* Calculate bounds. */
   off = angle_diff(rdir, dir);
   if (FABS(off) > swivel) {
      if (off > 0.)
         rdir = dir - swivel;
      else
         rdir = dir + swivel;
   }

   /* If manual aiming is closer to accurate than auto-aiming, use the
    * manual aiming direction. */
   if (FABS(angle_diff(rdir, adir)) > FABS(angle_diff(dir, adir)))
      rdir = dir;

   return rdir;
}



/**
 * @brief Creates the bolt specific properties of a weapon.
 *
 *    @param w Weapon to create bolt specific properties of.
 *    @param slot Outfit slot which spawned the weapon.
 *    @param dir Direction the shooter is facing.
 *    @param pos Position of the shooter.
 *    @param vel Velocity of the shooter.
 *    @param parent Shooter.
 *    @param time Expected flight time.
 */
static void weapon_createBolt(Weapon *w, const PilotOutfitSlot *slot,
      const double dir, const Vector2d* pos, const Vector2d* vel,
      const Pilot* parent, double time)
{
   Vector2d v;
   double mass, rdir;
   double range;
   double speed;
   double spread;
   Pilot *pilot_target;
   double acc;
   glTexture *gfx;
   double absorb;
   double damage_shield, damage_armor, recoil;
   double dam_mod;

   /* Only difference is the direction of fire */
   if ((w->parent!=w->target) && (w->target != 0)) /* Must have valid target */
      pilot_target = pilot_get(w->target);
   else /* fire straight or at asteroid */
      pilot_target = NULL;

   rdir = weapon_aimTurret(
      parent, pilot_target, pos, vel, dir, w->outfit->u.blt.swivel,
      time, w->outfit->u.blt.rdr_range, w->outfit->u.blt.rdr_range_max);

   /* Calculate accuracy. */
   acc =  HEAT_WORST_ACCURACY * pilot_heatAccuracyMod(slot->heat_T);

   /* Stat modifiers. */
   range = w->outfit->u.blt.range * parent->stats.blt_range;
   speed = w->outfit->u.blt.speed * parent->stats.blt_speed;
   spread = w->outfit->u.blt.spread;
   spread += parent->stats.blt_spread * M_PI / 180.;
   w->dam_mod *= parent->stats.blt_damage;
   w->dam_mod *= (slot->charge+w->outfit->u.blt.delay) / w->outfit->u.blt.delay;
   w->dam_as_dis_mod = parent->stats.blt_dam_as_dis;
   w->dis_as_dam_mod = parent->stats.blt_dis_as_dam;
   w->dam_shield_as_armor_mod = parent->stats.blt_dam_shield_as_armor;
   w->dam_armor_as_shield_mod = parent->stats.blt_dam_armor_as_shield;
   if ((w->outfit->type == OUTFIT_TYPE_TURRET_BOLT)
         || parent->stats.turret_conversion) {
      range *= parent->stats.tur_range;
      speed *= parent->stats.tur_speed;
      spread += parent->stats.tur_spread * M_PI / 180.;
      w->dam_mod *= parent->stats.tur_damage;
      w->dam_as_dis_mod += parent->stats.tur_dam_as_dis;
      w->dis_as_dam_mod += parent->stats.tur_dis_as_dam;
      w->dam_shield_as_armor_mod += parent->stats.tur_dam_shield_as_armor;
      w->dam_armor_as_shield_mod += parent->stats.tur_dam_armor_as_shield;
   }
   else {
      range *= parent->stats.fwd_range;
      speed *= parent->stats.fwd_speed;
      spread += parent->stats.fwd_spread * M_PI / 180.;
      w->dam_mod *= parent->stats.fwd_damage;
      w->dam_as_dis_mod += parent->stats.fwd_dam_as_dis;
      w->dis_as_dam_mod += parent->stats.fwd_dis_as_dam;
      w->dam_shield_as_armor_mod += parent->stats.fwd_dam_shield_as_armor;
      w->dam_armor_as_shield_mod += parent->stats.fwd_dam_armor_as_shield;
   }
   spread = CLAMP(0., 2. * M_PI, spread);
   w->dam_as_dis_mod = CLAMP(0., 1., w->dam_as_dis_mod);
   w->dis_as_dam_mod = CLAMP(0., 1., w->dis_as_dam_mod);
   w->dam_shield_as_armor_mod = CLAMP(0., 1., w->dam_shield_as_armor_mod);
   w->dam_armor_as_shield_mod = CLAMP(0., 1., w->dam_armor_as_shield_mod);

   /* Calculate accuracy loss from spread. */
   rdir += (RNGF()-0.5) * spread;

   /* Calculate heat-based accuracy loss. */
   rdir += RNG_2SIGMA() * acc;

   if (rdir < 0.)
      rdir += 2.*M_PI;
   else if (rdir >= 2.*M_PI)
      rdir -= 2.*M_PI;

   mass = 1; /* Lasers are presumed to have unitary mass */
   v = *vel;
   vect_cadd(&v, speed * cos(rdir), speed * sin(rdir));
   w->timer = range / speed;
   w->falloff = w->timer - w->outfit->u.blt.falloff / speed;
   w->solid = solid_create(mass, rdir, pos, &v, SOLID_UPDATE_EULER);
   w->voice = sound_playPos(
      slot->charge>0. ? w->outfit->u.blt.sound_charged : w->outfit->u.blt.sound,
      w->solid->pos.x, w->solid->pos.y,
      w->solid->vel.x, w->solid->vel.y);

   /* Apply recoil as applicable. */
   absorb = 1. - CLAMP(0., 1.,
         parent->dmg_absorb - w->outfit->u.blt.dmg.penetration);
   dtype_calcDamage(&damage_shield, &damage_armor, NULL, &recoil, absorb,
         &w->outfit->u.blt.dmg, &parent->stats);
   dam_mod = ((damage_shield+damage_armor)
         / ((parent->shield_max+parent->armour_max)/2.));
   vect_cadd(
      &parent->solid->vel,
      recoil * (-w->solid->vel.x * (dam_mod/9. + mass/parent->solid->mass/6.)),
      recoil * (-w->solid->vel.y * (dam_mod/9. + mass/parent->solid->mass/6.)));

   /* Set facing direction. */
   gfx = outfit_gfx(w->outfit);
   gl_getSpriteFromDir(&w->sx, &w->sy, gfx, w->solid->dir);
}


/**
 * @brief Creates the ammo specific properties of a weapon.
 *
 *    @param w Weapon to create ammo specific properties of.
 *    @param launcher Outfit which spawned the weapon.
 *    @param T temperature of the shooter.
 *    @param dir Direction the shooter is facing.
 *    @param pos Position of the shooter.
 *    @param vel Velocity of the shooter.
 *    @param parent Shooter.
 *    @param time Expected flight time.
 */
static void weapon_createAmmo( Weapon *w, const Outfit* launcher, double T,
      const double dir, const Vector2d* pos, const Vector2d* vel, const Pilot* parent, double time )
{
   (void) T;
   Vector2d v;
   double mass, rdir;
   double duration;
   double speed;
   double spread;
   Pilot *pilot_target;
   glTexture *gfx;
   double absorb;
   double damage_shield, damage_armor, recoil;
   double dam_mod;

   /* Aim forward by default. */   
   rdir = dir;

   pilot_target = NULL;
   if (w->outfit->type == OUTFIT_TYPE_AMMO) {
      if ((parent->id != w->target) && (w->target != 0))
         pilot_target = pilot_get(w->target);

      if ((pilot_target != NULL) || (parent->nav_asteroid >= 0)) {
         if (launcher->type == OUTFIT_TYPE_TURRET_LAUNCHER)
            rdir = weapon_aimTurret(parent, pilot_target, pos, vel, dir, M_PI,
                  time, launcher->u.lau.rdr_range,
                  launcher->u.lau.rdr_range_max);
         else
            rdir = weapon_aimTurret(parent, pilot_target, pos, vel, dir,
                  launcher->u.lau.swivel, time, launcher->u.lau.rdr_range,
                  launcher->u.lau.rdr_range_max);
      }
   }

   /* Stat modifiers. */
   /* Because ammo modulates its range by duration, any boost in speed
    * has to be accompanied by a decrease in duration to avoid speed
    * increases incidentally boosting range. */
   duration = w->outfit->u.amm.duration * parent->stats.launch_range;
   duration /= parent->stats.launch_speed;
   speed = w->outfit->u.amm.speed * parent->stats.launch_speed;
   spread = launcher->u.lau.spread;
   spread += parent->stats.launch_spread * M_PI / 180.;
   w->dam_mod *= parent->stats.launch_damage;
   w->dam_as_dis_mod = parent->stats.launch_dam_as_dis;
   w->dis_as_dam_mod = parent->stats.launch_dis_as_dam;
   w->dam_shield_as_armor_mod = parent->stats.launch_dam_shield_as_armor;
   w->dam_armor_as_shield_mod = parent->stats.launch_dam_armor_as_shield;
   if ((launcher->type == OUTFIT_TYPE_TURRET_LAUNCHER)
         || parent->stats.turret_conversion) {
      duration *= parent->stats.tur_range;
      duration /= parent->stats.tur_speed;
      speed *= parent->stats.tur_speed;
      spread += parent->stats.tur_spread * M_PI / 180.;
      w->dam_mod *= parent->stats.tur_damage;
      w->dam_as_dis_mod += parent->stats.tur_dam_as_dis;
      w->dis_as_dam_mod += parent->stats.tur_dis_as_dam;
      w->dam_shield_as_armor_mod += parent->stats.tur_dam_shield_as_armor;
      w->dam_armor_as_shield_mod += parent->stats.tur_dam_armor_as_shield;
   }
   else {
      duration *= parent->stats.fwd_range;
      duration /= parent->stats.fwd_speed;
      speed *= parent->stats.fwd_speed;
      spread += parent->stats.fwd_spread * M_PI / 180.;
      w->dam_mod *= parent->stats.fwd_damage;
      w->dam_as_dis_mod += parent->stats.fwd_dam_as_dis;
      w->dis_as_dam_mod += parent->stats.fwd_dis_as_dam;
      w->dam_shield_as_armor_mod += parent->stats.fwd_dam_shield_as_armor;
      w->dam_armor_as_shield_mod += parent->stats.fwd_dam_armor_as_shield;
   }
   spread = CLAMP(0., 2. * M_PI, spread);
   w->dam_as_dis_mod = CLAMP(0., 1., w->dam_as_dis_mod);
   w->dis_as_dam_mod = CLAMP(0., 1., w->dis_as_dam_mod);
   w->dam_shield_as_armor_mod = CLAMP(0., 1., w->dam_shield_as_armor_mod);
   w->dam_armor_as_shield_mod = CLAMP(0., 1., w->dam_armor_as_shield_mod);

   /* Calculate accuracy loss from spread. */
   rdir += (RNGF()-0.5) * spread;

   if (rdir < 0.)
      rdir += 2.*M_PI;
   else if (rdir >= 2.*M_PI)
      rdir -= 2.*M_PI;

   /* Start out at max speed. */
   v = *vel;
   vect_cadd(&v, cos(rdir) * w->outfit->u.amm.speed,
         sin(rdir) * w->outfit->u.amm.speed);
   w->real_vel = VMOD(v);

   /* Set up ammo details. */
   mass = w->outfit->mass;
   w->timer = duration;
   w->solid = solid_create(mass, rdir, pos, &v, SOLID_UPDATE_RK4);
   if (w->outfit->u.amm.thrust != 0.) {
      w->solid->thrust = w->outfit->u.amm.thrust * mass;
      w->solid->speed_max = w->outfit->u.amm.speed; /* Limit speed, we only care if it has thrust. */
   }

   /* Apply recoil as applicable. */
   absorb = 1. - CLAMP(0., 1.,
         parent->dmg_absorb - w->outfit->u.amm.dmg.penetration);
   dtype_calcDamage(&damage_shield, &damage_armor, NULL, &recoil, absorb,
         &w->outfit->u.amm.dmg, &parent->stats);
   dam_mod = ((damage_shield+damage_armor)
         / ((parent->shield_max+parent->armour_max)/2.));
   vect_cadd(
      &parent->solid->vel,
      recoil * (-w->solid->vel.x * (dam_mod/9. + mass/parent->solid->mass/6.)),
      recoil * (-w->solid->vel.y * (dam_mod/9. + mass/parent->solid->mass/6.)));

   /* Handle seekers. */
   if (w->outfit->u.amm.ai != AMMO_AI_UNGUIDED) {
      w->think = think_seeker; /* AI is the same atm. */

      /* If they are seeking a pilot, increment lockon counter. */
      if (pilot_target == NULL)
         pilot_target = pilot_get(w->target);
      if (pilot_target != NULL)
         pilot_target->lockons++;
   }

   /* Play sound. */
   w->voice    = sound_playPos(w->outfit->u.amm.sound,
         w->solid->pos.x,
         w->solid->pos.y,
         w->solid->vel.x,
         w->solid->vel.y);

   /* Set facing direction. */
   gfx = outfit_gfx( w->outfit );
   gl_getSpriteFromDir( &w->sx, &w->sy, gfx, w->solid->dir );

   /* Set up trails. */
   if (w->outfit->u.amm.trail_spec != NULL)
      w->trail = spfx_trail_create(w->outfit->u.amm.trail_spec);
}


/**
 * @brief Creates a new weapon.
 *
 *    @param slot Outfit slot which spawned the weapon.
 *    @param dir Direction the shooter is facing.
 *    @param pos Position of the shooter.
 *    @param vel Velocity of the shooter.
 *    @param parent Shooter.
 *    @param target Target ID of the shooter.
 *    @param time Expected flight time.
 *    @return A pointer to the newly created weapon.
 */
static Weapon* weapon_create(const PilotOutfitSlot *slot,
      const double dir, const Vector2d* pos, const Vector2d* vel,
      const Pilot* parent, const pilotId_t target, double time)
{
   double mass, rdir;
   Pilot *pilot_target;
   AsteroidAnchor *field;
   Asteroid *ast;

   Weapon* w;

   /* Create basic features */
   w = calloc(1, sizeof(Weapon));
   w->dam_mod = 1.;
   w->dam_as_dis_mod = 0.;
   w->dis_as_dam_mod = 0.;
   w->dam_shield_as_armor_mod = 0.;
   w->dam_armor_as_shield_mod = 0.;
   w->faction = parent->faction; /* non-changeable */
   w->parent = parent->id; /* non-changeable */
   w->target = target; /* non-changeable */
   if (outfit_isLauncher(slot->outfit)) {
      w->outfit = slot->outfit->u.lau.ammo; /* non-changeable */
      w->launcher = slot->outfit; /* non-changeable */
   }
   else
      w->outfit = slot->outfit; /* non-changeable */
   w->update = weapon_update;
   w->strength = 1.;

   /* Inform the target. */
   pilot_target = pilot_get(target);
   if (pilot_target != NULL)
      pilot_target->projectiles++;

   switch (slot->outfit->type) {

      /* Bolts treated together */
      case OUTFIT_TYPE_BOLT:
      case OUTFIT_TYPE_TURRET_BOLT:
         weapon_createBolt(w, slot, dir, pos, vel, parent, time);
         break;

      /* Beam weapons are treated together. */
      case OUTFIT_TYPE_BEAM:
      case OUTFIT_TYPE_TURRET_BEAM:
         rdir = dir;
         if ((slot->outfit->type == OUTFIT_TYPE_TURRET_BEAM)
               || parent->stats.turret_conversion) {
            pilot_target = pilot_get(target);
            if ((w->parent != w->target) && (pilot_target != NULL))
               rdir = vect_angle(pos, &pilot_target->solid->pos);
            else if (parent->nav_asteroid >= 0) {
               field = &cur_system->asteroids[parent->nav_anchor];
               ast = &field->asteroids[parent->nav_asteroid];
               rdir = vect_angle(pos, &ast->pos);
            }
         }

         if (rdir < 0.)
            rdir += 2.*M_PI;
         else if (rdir >= 2.*M_PI)
            rdir -= 2.*M_PI;
         mass = 1.; /**< Needs a mass. */
         w->r = RNGF(); /* Set unique value. */
         w->solid = solid_create(mass, rdir, pos, vel, SOLID_UPDATE_EULER);
         w->think = think_beam;
         w->voice = sound_playPos(w->outfit->u.bem.sound,
               w->solid->pos.x,
               w->solid->pos.y,
               w->solid->vel.x,
               w->solid->vel.y);

         w->dam_mod *= parent->stats.bem_damage;
         w->timer = slot->outfit->u.bem.duration * parent->stats.bem_duration;
         w->length = slot->outfit->u.bem.range * parent->stats.bem_range;
         w->dam_as_dis_mod = parent->stats.bem_dam_as_dis;
         w->dis_as_dam_mod = parent->stats.bem_dis_as_dam;
         w->dam_shield_as_armor_mod = parent->stats.bem_dam_shield_as_armor;
         w->dam_armor_as_shield_mod = parent->stats.bem_dam_armor_as_shield;
         if ((slot->outfit->type == OUTFIT_TYPE_TURRET_BEAM)
               || parent->stats.turret_conversion) {
            w->dam_mod *= parent->stats.tur_damage;
            w->length *= parent->stats.tur_range;
            w->dam_as_dis_mod += parent->stats.tur_dam_as_dis;
            w->dis_as_dam_mod += parent->stats.tur_dis_as_dam;
            w->dam_shield_as_armor_mod += parent->stats.tur_dam_shield_as_armor;
            w->dam_armor_as_shield_mod += parent->stats.tur_dam_armor_as_shield;
         }
         else {
            w->dam_mod *= parent->stats.fwd_damage;
            w->length *= parent->stats.fwd_range;
            w->dam_as_dis_mod += parent->stats.fwd_dam_as_dis;
            w->dis_as_dam_mod += parent->stats.fwd_dis_as_dam;
            w->dam_shield_as_armor_mod += parent->stats.fwd_dam_shield_as_armor;
            w->dam_armor_as_shield_mod += parent->stats.fwd_dam_armor_as_shield;
         }
         w->dam_as_dis_mod = CLAMP(0., 1., w->dam_as_dis_mod);
         w->dis_as_dam_mod = CLAMP(0., 1., w->dis_as_dam_mod);
         w->dam_shield_as_armor_mod = CLAMP(0., 1., w->dam_shield_as_armor_mod);
         w->dam_armor_as_shield_mod = CLAMP(0., 1., w->dam_armor_as_shield_mod);

         break;

      /* Treat seekers together. */
      case OUTFIT_TYPE_LAUNCHER:
      case OUTFIT_TYPE_TURRET_LAUNCHER:
         weapon_createAmmo(w, slot->outfit, slot->heat_T, dir, pos, vel, parent, time);
         break;

      /* just dump it where the player is */
      default:
         WARN(_("Weapon of type '%s' has no create implemented yet!"),
               slot->outfit->name);
         w->solid = solid_create( 1., dir, pos, vel, SOLID_UPDATE_EULER );
         break;
   }

   /* Set life to timer. */
   w->life = w->timer;

   return w;
}


/**
 * @brief Creates a new weapon.
 *
 *    @param slot Outfit slot which spawns the weapon.
 *    @param dir Direction of the shooter.
 *    @param pos Position of the shooter.
 *    @param vel Velocity of the shooter.
 *    @param parent Pilot ID of the shooter.
 *    @param target Target ID that is getting shot.
 *    @param time Expected flight time.
 */
void weapon_add(const PilotOutfitSlot *slot, const double dir,
      const Vector2d* pos, const Vector2d* vel,
      const Pilot *parent, pilotId_t target, double time)
{
   WeaponLayer layer;
   Weapon *w, **m;
   GLsizei size;
   size_t bufsize;
   int salvo;
   int i;

   if (!outfit_isBolt(slot->outfit) &&
         !outfit_isLauncher(slot->outfit)) {
      ERR(_("Trying to create a Weapon from a non-Weapon type Outfit"));
      return;
   }

   salvo = 1;
   if (outfit_isBolt(slot->outfit)) {
      salvo = slot->outfit->u.blt.salvo + parent->stats.blt_salvo;
      if ((slot->outfit->type == OUTFIT_TYPE_TURRET_BOLT)
            || parent->stats.turret_conversion) {
         salvo += parent->stats.tur_salvo;
      }
      else {
         salvo += parent->stats.fwd_salvo;
      }
   }
   else if (outfit_isLauncher(slot->outfit)) {
      salvo = slot->outfit->u.lau.salvo + parent->stats.launch_salvo;
      if ((slot->outfit->type == OUTFIT_TYPE_TURRET_BOLT)
            || parent->stats.turret_conversion) {
         salvo += parent->stats.tur_salvo;
      }
      else {
         salvo += parent->stats.fwd_salvo;
      }
   }

   layer = (parent->id==PLAYER_ID) ? WEAPON_LAYER_FG : WEAPON_LAYER_BG;

   for (i=0; i<salvo; i++) {
      w = weapon_create(slot, dir, pos, vel, parent, target, time);

      /* set the proper layer */
      switch (layer) {
         case WEAPON_LAYER_BG:
            m = &array_grow(&wbackLayer);
            break;
         case WEAPON_LAYER_FG:
            m = &array_grow(&wfrontLayer);
            break;

         default:
            WARN(_("Unknown weapon layer!"));
            return;
      }
      *m = w;

      /* Grow the vertex stuff if needed. */
      bufsize = array_reserved(wfrontLayer) + array_reserved(wbackLayer);
      if (bufsize != weapon_vboSize) {
         weapon_vboSize = bufsize;
         size = sizeof(GLfloat) * (2+4) * weapon_vboSize;
         weapon_vboData = realloc( weapon_vboData, size );
         if (weapon_vbo == NULL)
            weapon_vbo = gl_vboCreateStream( size, NULL );
         gl_vboData( weapon_vbo, size, weapon_vboData );
      }
   }
}


/**
 * @brief Starts a beam weapon.
 *
 *    @param slot Outfit slot which spawns the weapon.
 *    @param dir Direction of the shooter.
 *    @param pos Position of the shooter.
 *    @param vel Velocity of the shooter.
 *    @param parent Pilot shooter.
 *    @param target Target ID that is getting shot.
 *    @param mount Mount on the ship.
 *    @return The identifier of the beam weapon.
 *
 * @sa beam_end
 */
unsigned int beam_start(const PilotOutfitSlot *slot,
      const double dir, const Vector2d* pos, const Vector2d* vel,
      const Pilot *parent, const pilotId_t target,
      PilotOutfitSlot *mount)
{
   WeaponLayer layer;
   Weapon *w, **m;
   GLsizei size;
   size_t bufsize;

   if (!outfit_isBeam(slot->outfit)) {
      ERR(_("Trying to create a Beam Weapon from a non-beam outfit."));
      return -1;
   }

   layer = (parent->id==PLAYER_ID) ? WEAPON_LAYER_FG : WEAPON_LAYER_BG;
   w = weapon_create(slot, dir, pos, vel, parent, target, 0.);
   w->ID = ++beam_idgen;
   w->mount = mount;
   w->exp_timer = 0.;

   /* set the proper layer */
   switch (layer) {
      case WEAPON_LAYER_BG:
         m = &array_grow(&wbackLayer);
         break;
      case WEAPON_LAYER_FG:
         m = &array_grow(&wfrontLayer);
         break;

      default:
         ERR(_("Invalid WEAPON_LAYER specified"));
         return -1;
   }
   *m = w;

   /* Grow the vertex stuff if needed. */
   bufsize = array_reserved(wfrontLayer) + array_reserved(wbackLayer);
   if (bufsize != weapon_vboSize) {
      weapon_vboSize = bufsize;
      size = sizeof(GLfloat) * (2+4) * weapon_vboSize;
      weapon_vboData = realloc( weapon_vboData, size );
      if (weapon_vbo == NULL)
         weapon_vbo = gl_vboCreateStream( size, NULL );
      gl_vboData( weapon_vbo, size, weapon_vboData );
   }

   /* Think so we start out aiming in the corect direction. */
   think_beam(w, 0);

   return w->ID;
}


/**
 * @brief Ends a beam weapon.
 *
 *    @param parent ID of the parent of the beam.
 *    @param beam ID of the beam to destroy.
 */
void beam_end(const pilotId_t parent, unsigned int beam)
{
   int i;
   WeaponLayer layer;
   Weapon **curLayer;

   layer = (parent==PLAYER_ID) ? WEAPON_LAYER_FG : WEAPON_LAYER_BG;

   /* set the proper layer */
   switch (layer) {
      case WEAPON_LAYER_BG:
         curLayer = wbackLayer;
         break;
      case WEAPON_LAYER_FG:
         curLayer = wfrontLayer;
         break;

      default:
         ERR(_("Invalid WEAPON_LAYER specified"));
         return;
   }

#if DEBUGGING
   if (beam==0) {
      WARN(_("Trying to remove beam with ID 0!"));
      return;
   }
#endif /* DEBUGGING */

   /* Now try to destroy the beam. */
   for (i=0; i<array_size(curLayer); i++) {
      if (curLayer[i]->ID == beam) { /* Found it. */
         weapon_destroy(curLayer[i]);
         break;
      }
   }
}


/**
 * @brief Destroys a weapon.
 *
 *    @param w Weapon to destroy.
 */
static void weapon_destroy( Weapon* w )
{
   /* Just mark for removal. */
   weapon_setFlag( w, WEAPON_FLAG_DESTROYED );
}


/**
 * @brief Frees the weapon.
 *
 *    @param w Weapon to free.
 */
static void weapon_free( Weapon* w )
{
   Pilot *pilot_target;
   Weapon *heir;
   Weapon *test_heir;
   double heir_dist;
   double test_heir_dist;
   char *sname;
   char *test_heir_sname;
   double x, y;
   Vector2d camera_pos;
   int i;

   pilot_target = pilot_get( w->target );

   /* Decrement target lockons if needed */
   if (pilot_target != NULL) {
      pilot_target->projectiles--;
      if (outfit_isSeeker(w->outfit))
         pilot_target->lockons--;
      }

   /* Stop playing sound if beam weapon. */
   if (outfit_isBeam(w->outfit)) {
      if ((w->voice > 0) && sound_playing(w->voice)) {
         /* Attempt to pass on the voice to another beam which plays the
          * same sound effect. If there is no other beam that can take
          * this beam's voice, stop the voice. This avoids the weirdness
          * that can occur if one beam turning off causes all beams to
          * be silent. */
         gl_screenToGameCoords(&x, &y, SCREEN_W / 2., SCREEN_H / 2.);
         vect_cset(&camera_pos, x, y);

         heir = NULL;

         heir_dist = INFINITY;
         sname = sound_name(w->outfit->u.bem.sound);
         if (sname != NULL) {
            for (i=0; i<array_size(wfrontLayer)+array_size(wbackLayer); i++) {
               if (i < array_size(wfrontLayer))
                  test_heir = wfrontLayer[i];
               else
                  test_heir = wbackLayer[i-array_size(wfrontLayer)];

               if (test_heir->voice <= 0)
                  continue;

               test_heir_sname = sound_name(test_heir->outfit->u.bem.sound);
               if (test_heir_sname == NULL)
                  continue;

               if (strcmp(sname, test_heir_sname) != 0)
                  continue;

               if (sound_playing(test_heir->voice))
                  continue;

               test_heir_dist = vect_dist2(&camera_pos, &test_heir->solid->pos);

               if (heir == NULL) {
                  heir = test_heir;
                  heir_dist = test_heir_dist;
                  continue;
               }

               if (test_heir_dist < heir_dist) {
                  heir = test_heir;
                  heir_dist = test_heir_dist;
               }
            }
         }
         if (heir != NULL)
            heir->voice = w->voice;
         else
            sound_stop(w->voice);
      }
      sound_playPos(w->outfit->u.bem.sound_off,
            w->solid->pos.x,
            w->solid->pos.y,
            w->solid->vel.x,
            w->solid->vel.y);
   }

   /* Free the solid. */
   solid_free(w->solid);

   /* Free the trail, if any. */
   spfx_trail_remove(w->trail);

#ifdef DEBUGGING
   memset(w, 0, sizeof(Weapon));
#endif /* DEBUGGING */

   free(w);
}

/**
 * @brief Clears all the weapons, does NOT free the layers.
 */
void weapon_clear (void)
{
   int i;
   /* Don't forget to stop the sounds. */
   for (i=0; i < array_size(wbackLayer); i++) {
      sound_stop(wbackLayer[i]->voice);
      weapon_free(wbackLayer[i]);
   }
   array_erase( &wbackLayer, array_begin(wbackLayer), array_end(wbackLayer) );
   for (i=0; i < array_size(wfrontLayer); i++) {
      sound_stop(wfrontLayer[i]->voice);
      weapon_free(wfrontLayer[i]);
   }
   array_erase( &wfrontLayer, array_begin(wfrontLayer), array_end(wfrontLayer) );
}

/**
 * @brief Destroys all the weapons and frees it all.
 */
void weapon_exit (void)
{
   weapon_clear();

   /* Destroy front layer. */
   array_free(wbackLayer);

   /* Destroy back layer. */
   array_free(wfrontLayer);

   /* Destroy VBO. */
   free( weapon_vboData );
   weapon_vboData = NULL;
   gl_vboDestroy( weapon_vbo );
   weapon_vbo = NULL;
}


/**
 * @brief Clears possible exploded weapons.
 */
void weapon_explode( double x, double y, double radius,
      int dtype, double damage,
      const Pilot *parent, int mode )
{
   (void)dtype;
   (void)damage;
   weapon_explodeLayer( WEAPON_LAYER_FG, x, y, radius, parent, mode );
   weapon_explodeLayer( WEAPON_LAYER_BG, x, y, radius, parent, mode );
}


/**
 * @brief Explodes all the things on a layer.
 */
static void weapon_explodeLayer( WeaponLayer layer,
      double x, double y, double radius,
      const Pilot *parent, int mode )
{
   (void)parent;
   int i;
   Weapon **curLayer;
   double dist, rad2;

   /* set the proper layer */
   switch (layer) {
      case WEAPON_LAYER_BG:
         curLayer = wbackLayer;
         break;
      case WEAPON_LAYER_FG:
         curLayer = wfrontLayer;
         break;

      default:
         ERR(_("Invalid WEAPON_LAYER specified"));
         return;
   }

   rad2 = radius*radius;

   /* Now try to destroy the weapons affected. */
   for (i=0; i<array_size(curLayer); i++) {
      if (((mode & EXPL_MODE_MISSILE) && outfit_isAmmo(curLayer[i]->outfit)) ||
            ((mode & EXPL_MODE_BOLT) && outfit_isBolt(curLayer[i]->outfit))) {

         dist = pow2(curLayer[i]->solid->pos.x - x) +
               pow2(curLayer[i]->solid->pos.y - y);

         if (dist < rad2)
            weapon_destroy(curLayer[i]);
      }
   }
}


