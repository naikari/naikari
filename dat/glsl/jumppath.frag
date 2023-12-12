#include "lib/sdf.glsl"

uniform vec4 colour;
uniform vec2 dimensions;
uniform float paramf; // Radius
uniform int parami; // Whether segment drawn is reachable (enough fuel)
uniform float dt; // Animation delta tick

// Position relative to the center of the shaded area as a percentage
// (range [-1,1]).
in vec2 pos;
out vec4 colour_out;

void main(void) {
   // Convert percentage position to absolute pixel position relative
   // to the center of the shaded area.
   vec2 abs_pos = pos * dimensions;

   // Get distance from box dimensions.
   float distance = sdBox(abs_pos, dimensions - vec2(1.0));

   if (parami != 0) {
      vec2 abs_pos_anim = abs_pos;
      abs_pos_anim.y = abs(abs_pos_anim.y);
      abs_pos_anim.x -= dt * dimensions.y * 0.8;
      abs_pos_anim.x = mod(-abs_pos_anim.x, dimensions.y*1.5) - 0.25*dimensions.y;
      float anim_dist = -0.2*abs(abs_pos_anim.x-0.5*abs_pos_anim.y) + 2.0/3.0;
      distance = max(distance, anim_dist);
   }

   // alpha_percent is 1 within the shape, 0 outside of the shape, and
   // a value in between 0 and 1 where the shape transitions into the
   // edge.
   float alpha_percent = smoothstep(-1.0, 0.0, -distance);

   colour_out = colour;
   colour_out.a *= alpha_percent;
   colour_out.a *= smoothstep(dimensions.x, dimensions.x-paramf, length(abs_pos));
}
