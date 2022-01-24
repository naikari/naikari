uniform mat4 projection;

uniform vec2 star_xy;
uniform vec2 wh;
uniform vec2 xy;
uniform float scale;

in vec4 vertex;
in float brightness;
in float relspeed;
in vec3 color;

out float brightness_out;
out vec3 c_out;

void main(void) {
   /* Calculate position */
   gl_Position = vertex;
   gl_Position.xy += star_xy * relspeed;

   /* check boundaries */
   gl_Position.xy = mod(gl_Position.xy + wh/2.0, wh) - wh/2.0;

   /* Generate lines. */
   if (length(xy) != 0.0) {
      vec2 v = xy * relspeed;
      gl_Position.xy += mod(float(gl_VertexID), 2.0) * v * scale;
   }

   gl_Position = projection * gl_Position;

   brightness_out = brightness;
   c_out = color;
}
