uniform vec4 color;

in vec2 pos;
out vec4 color_out;

void main(void) {
   color_out = color;
   
   float dist = length(pos);
   color_out.a *= exp( 1.0 / (dist+1.0) - 0.5) - 1.0;
}

