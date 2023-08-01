#include "lib/sdf.glsl"

uniform vec4 color;
uniform vec2 dimensions;
uniform float dt;

in vec2 pos;
out vec4 color_out;

void main(void) {
   float anim = 1.0 - 0.5*fract(dt/2.0);

   vec2 uv = abs(pos) / anim;
   if (uv.y < uv.x)
      uv.xy = uv.yx;

   float m = 1.0 / (anim*dimensions.x);
   float m3 = m * 3.0;
   float d = sdSegment(uv, vec2(0.2+m, 1.0-m3), vec2(1.0, 1.0) - m3) - 0.5*m;

   float alpha = smoothstep(-m, 0.0, -d);
   float beta = smoothstep(-2.0*m, -m, -d);
   color_out = color * vec4(vec3(alpha), beta);
}
