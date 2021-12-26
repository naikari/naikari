in float brightness_out;
in vec3 c_out;
out vec4 color_out;

void main(void) {
   color_out = vec4(c_out, brightness_out);
}
