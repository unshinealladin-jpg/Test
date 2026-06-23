#version 120

varying vec4 color;

/* DRAWBUFFERS:02 */

void main() {
    gl_FragData[0] = color;
    // Ciel = profondeur infinie → on stocke 1.0 dans colortex2
    // Ainsi les entités devant le ciel sont toujours détectées "visibles"
    gl_FragData[1] = vec4(1.0);
}
