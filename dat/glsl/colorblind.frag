// Colorblindness Simulator
//
// This colorblindness simulator is used for testing Naikari's
// colorblind accessibility. It can simulate all types of colorblindness
// with the most accessibility needs: protanopia ("red-blind"),
// deuteranopia ("green-blind"), tritanopia ("blue-blind"), rod
// monochromacy, and blue cone monochromacy. Made using help from this
// article:
// https://ixora.io/projects/colorblindness/color-blindness-simulation-research/
//
// Simulations for anomalous trichromacy (protanomaly, deuteranomaly,
// and tritanomaly) are included here as well, but they are likely
// inaccurate. Taken from this page:
// https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html

#define ROD_MONOCHROMACY 0
#define CONE_MONOCHROMACY 1
#define PROTANOPIA 2
#define DEUTERANOPIA 3
#define TRITANOPIA 4
#define PROTANOMALY 5
#define DEUTERANOMALY 6
#define TRITANOMALY 7

#define COLORBLIND_MODE ROD_MONOCHROMACY

uniform sampler2D MainTex;
uniform int mode = ROD_MONOCHROMACY;
in vec4 VaryingTexCoord;
out vec4 color_out;

void main (void)
{
   float l, m, s;
   float L, M, S;

   color_out = texture(MainTex, VaryingTexCoord.st);

   // Convert to LMS
   L = 0.31399022f*color_out.r + 0.63951294f*color_out.g + 0.04649755f*color_out.b;
   M = 0.15537241f*color_out.r + 0.75789446f*color_out.g + 0.08670142f*color_out.b;
   S = 0.01775239f*color_out.r + 0.10944209f*color_out.g + 0.87256922f*color_out.b;

   // Simulate color blindness
   if (mode == CONE_MONOCHROMACY) {
      // Blue Cone Monochromat (high light conditions): only brightness can
      // be detected, with blues greatly increased and reds nearly invisible
      // (0.001% population)
      // Note: This looks different from what many colorblindness simulators
      // show because this simulation assumes high light conditions. In low
      // light conditions, a blue cone monochromat can see a limited range of
      // color because both rods and cones are active. However, as we expect
      // a player to be looking at a lit screen, this simulation of high
      // light conditions is more useful.
      l = 0.01775f*L + 0.10945f*M + 0.87262f*S;
      m = 0.01775f*L + 0.10945f*M + 0.87262f*S;
      s = 0.01775f*L + 0.10945f*M + 0.87262f*S;
   }
   else if (mode == ROD_MONOCHROMACY) {
      // Rod Monochromat (Achromatopsia): only brightness can be detected
      // (0.003% population)
      l = 0.212656f*L + 0.715158f*M + 0.072186f*S;
      m = 0.212656f*L + 0.715158f*M + 0.072186f*S;
      s = 0.212656f*L + 0.715158f*M + 0.072186f*S;
   }
   else if (mode == PROTANOPIA) {
      // Protanopia: reds are greatly reduced (1% men)
      l = 0.0f*L + 1.05118294f*M + -0.05116099f*S;
      m = 0.0f*L + 1.0f*M + 0.0f*S;
      s = 0.0f*L + 0.0f*M + 1.0f*S;
   }
   else if (mode == DEUTERANOPIA) {
      // Deuteranopia: greens are greatly reduced (1% men)
      l = 1.0f*L + 0.0f*M + 0.0f*S;
      m = 0.9513092*L + 0.0f*M + 0.04866992f*S;
      s = 0.0f*L + 0.0f*M + 1.0f*S;
   }
   else if (mode == TRITANOPIA) {
      // Tritanopia: blues are greatly reduced (0.003% population)
      l = 1.0f*L + 0.0f*M + 0.0f*S;
      m = 0.0f*L + 1.0f*M + 0.0f*S;
      s = -0.86744736*L + 1.86727089f*M + 0.0f*S;
   }
   else if (mode == PROTANOMALY) {
      // Protanomaly (moderate severity): reds are green-shifted
      l = 0.458064f*L + 0.679578f*M + -0.137642f*S;
      m = 0.092785f*L + 0.846313f*M + 0.060902f*S;
      s = -0.007494f*L + -0.016807f*M + 1.024301f*S;
   }
   else if (mode == DEUTERANOMALY) {
      // Deuteranomaly (moderate severity): greens are red-shifted
      l = 0.547494f*L + 0.607765f*M + -0.155259f*S;
      m = 0.181692f*L + 0.781742f*M + 0.036566f*S;
      s = -0.010410f*L + 0.027275f*M + 0.983136f*S;
   }
   else if (mode == TRITANOMALY) {
      // Tritanomaly (moderate severity): blues are yellow-shifted
      l = 1.017277f*L + 0.027029f*M + -0.044306f*S;
      m = -0.006113f*L + 0.958479f*M + 0.047634f*S;
      s = 0.006379f*L + 0.248708f*M + 0.744913f*S;
   }
   else {
      // Invalid colorblindness type
      l = 0.212656f*L + 0.715158f*M + 0.072186f*S;
      m = 0.0f*L + 0.0f*M + 0.0f*S;
      s = 0.212656f*L + 0.715158f*M + 0.072186f*S;
   }

   // Convert to RGB
   color_out.r = 5.47221206f*l + -4.6419601f*m + 0.16963708f*s;
   color_out.g = -1.1252419f*l + 2.29317094f*m + -0.1678952f*s;
   color_out.b = 0.02980165f*l + -0.19318073f*m + 1.16364789f*s;
}
