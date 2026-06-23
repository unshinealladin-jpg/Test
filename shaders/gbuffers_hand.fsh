#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec2 texCoord;
varying vec2 lightCoord;

/* DRAWBUFFERS:0 */
// Main du joueur dans colortex0 ; pas d'ESP sur la main.

void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
    if (albedo.a < 0.1) discard;
    vec4 light = texture2D(lightmap, lightCoord);
    gl_FragData[0] = albedo * light;
}
