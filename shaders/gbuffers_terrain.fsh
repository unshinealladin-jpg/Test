#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec2 texCoord;
varying vec2 lightCoord;

/* DRAWBUFFERS:02 */

void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
    if (albedo.a < 0.1) discard;

    vec4 light = texture2D(lightmap, lightCoord);

    // colortex0 : couleur du terrain (scène sans entités)
    gl_FragData[0] = albedo * light;

    // colortex2 : profondeur du terrain stockée en valeur [0,1]
    // Utilisée dans composite1 pour distinguer entité visible vs derrière un mur
    gl_FragData[1] = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);
}
