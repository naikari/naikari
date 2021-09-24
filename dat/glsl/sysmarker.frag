#include "lib/sdf.glsl"

uniform vec4 color;
uniform vec2 dimensions;
uniform int parami;

in vec2 pos;
out vec4 color_out;

void main(void) {
   const vec2 b1 = vec2(1.0, 0.65);
   const vec2 b2 = vec2(0.9, 0.6);
   float m = 1.0 / dimensions.x;

   color_out = color;
   float d;
   if (parami==1) {
      const vec2 b = b2;
      const vec2 o = vec2(0.2, 0.0);
      vec2 opos = pos + o;
      d = sdRhombus(pos, b);
      d = max(-sdRhombus(pos*2.0, b), d);
      d = min(d, sdRhombus(pos*4.0, b));
   }
   else {
      const vec2 b = b1;
      const vec2 c = vec2(-0.35, 0.0);
      vec2 cpos = pos + c;
      d = sdEgg(pos, b - 2.0*m);
      d = max(-sdCircle(cpos, 0.5), d);
      d = min(sdCircle(cpos, 0.2), d);
   }

   float alpha = smoothstep(-m, m, -d);
   float beta = smoothstep(-2.0*m, -m, -d);
   color_out = color * vec4(vec3(alpha), beta);
}

