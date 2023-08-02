#include "lib/sdf.glsl"

uniform vec4 color;
uniform vec2 dimensions;
uniform float dt;

in vec2 pos;
out vec4 color_out;

void main(void) {
   // Animation size multiplier goes from 1 to 0.5, then wraps back to
   // 1, as time progresses.
   float anim_size_mult = 1.0 - 0.5*fract(dt/2.0);

   vec2 uv = abs(pos) / anim_size_mult;
   if (uv.y < uv.x)
      uv.xy = uv.yx;

   float m = 1.0 / (anim_size_mult*dimensions.x);
   float m3 = m * 3.0;
   float d = sdSegment(uv, vec2(0.2+m, 1.0-m3), vec2(1.0, 1.0) - m3) - 0.5*m;

   float alpha = smoothstep(-m, 0.0, -d);
   float beta = smoothstep(-2.0*m, -m, -d);
   color_out = color * vec4(vec3(alpha), beta);
}
