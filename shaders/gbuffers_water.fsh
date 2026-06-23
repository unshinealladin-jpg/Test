#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec2 texCoord;
varying vec2 lightCoord;

/* DRAWBUFFERS:0 */
// Eau dans colortex0 uniquement ; colortex2 (profondeur terrain) inchangée.

void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
    vec4 light  = texture2D(lightmap, lightCoord);
    gl_FragData[0] = albedo * light;
}
