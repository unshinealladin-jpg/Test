#version 120

// --- Passe composite 1/2 : Blur gaussien HORIZONTAL du masque ESP ---
//
// Entrée  : colortex1.rgb (masque entités : r=joueur, g=hostile, b=neutre)
// Sortie  : colortex3     (masque après blur horizontal)
//
// Le blur vertical et la composition finale se font dans composite1.fsh.

uniform sampler2D colortex1;
uniform float viewWidth;

varying vec2 texCoord;

/* DRAWBUFFERS:3 */

// Rayon du glow en pixels
// Augmenter pour un halo plus large (plus visible à grande distance)
const float BLUR_RADIUS = 6.0;

// Poids gaussien pour 9 échantillons séparables
const float GAUSS[9] = float[9](
    0.0162, 0.0540, 0.1216, 0.1946, 0.2270,
    0.1946, 0.1216, 0.0540, 0.0162
);

void main() {
    float texelW = BLUR_RADIUS / viewWidth;
    vec3  result = vec3(0.0);

    for (int i = 0; i < 9; i++) {
        float offset = float(i - 4) * texelW;
        vec2  uv = texCoord + vec2(offset, 0.0);
        result  += texture2D(colortex1, uv).rgb * GAUSS[i];
    }

    gl_FragData[0] = vec4(result, 1.0);
}
