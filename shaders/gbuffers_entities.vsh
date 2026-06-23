#version 120

// --- ESP wallhack : near-plane trick ---
// On force gl_Position.z au plan proche (-w) → tous les fragments de
// l'entité passent toujours le depth test, donc l'entité est dessinée
// PAR-DESSUS le terrain (visible à travers les murs).
//
// On ne touche PAS à gl_FragDepth dans le fragment shader : la profondeur
// reste au plan proche, ce qui garde l'entité visible à travers les blocs.

varying vec4 color;
varying vec2 texCoord;

void main() {
    vec4 pos = ftransform();

    // Wallhack : aplatit la profondeur au plan proche (NDC z = -1)
    pos.z = -pos.w;

    gl_Position = pos;
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    color       = gl_Color;
}
