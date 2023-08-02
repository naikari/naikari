#include "lib/sdf.glsl"

uniform vec4 color;
uniform vec2 dimensions;

in vec2 pos;
out vec4 color_out;

void main(void) {
   vec2 uv = pos * dimensions;
   float distance_percent = sdBox(uv, dimensions - vec2(2.0));

   // color_percent is 1 within the shape, 0 within the outline, and a
   // value in between 0 and 1 where the shape transitions into the
   // outline. Within the outline, alpha_percent decreases from 1 to 0
   // as distance from the shape increases.
   float color_percent = smoothstep(-1.0,  0.0, -distance_percent);
   float alpha_percent = smoothstep(-2.0, -1.0, -distance_percent);
   color_out = color * vec4(vec3(color_percent), alpha_percent);
}
