#version 120

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4 color;
varying vec2 texCoord;
varying vec2 lightCoord;

/* DRAWBUFFERS:01 */

void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
    if (albedo.a < 0.1) discard;

    vec4 light = texture2D(lightmap, lightCoord);

    // colortex0 : couleur normale du terrain
    gl_FragData[0] = albedo * light;

    // colortex1 : terrain → pas d'entité, masque à zéro
    gl_FragData[1] = vec4(0.0);
}
