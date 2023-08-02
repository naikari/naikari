#include "lib/sdf.glsl"

uniform vec4 color;
uniform vec2 dimensions;

// Position relative to the center of the shaded area as a percentage
// (range [-1,1]).
in vec2 pos;
out vec4 color_out;

void main(void) {
   const float outline_thickness = 1.0;
   const vec2 outline_buffer = vec2(2.0 * outline_thickness);

   // Convert percentage position to absolute pixel position relative
   // to the center of the shaded area.
   vec2 abs_pos = pos * dimensions;

   // Get distance from box dimensions.
   float distance = sdBox(abs_pos, dimensions - outline_buffer);

   float color_percent;
   float alpha_percent;
   if (outline_thickness > 0.0) {
      // color_percent is 1 within the shape, 0 within the outline, and
      // a value in between 0 and 1 where the shape transitions into the
      // outline. Within the outline, alpha_percent decreases from 1 to
      // 0 as distance from the shape increases.
      color_percent = smoothstep(-1.0, 0.0, -distance);
      alpha_percent = smoothstep(-1.0 - outline_thickness, -1.0, -distance);
   }
   else {
      // With no outline, color_percent is always 1.0 and alpha_percent
      // is just on or off depending on whether we're in the shape.
      color_percent = 1.0;
      if (distance <= 0.0)
         alpha_percent = 1.0;
      else
         alpha_percent = 0.0;
   }
   color_out = color * vec4(vec3(color_percent), alpha_percent);
}
