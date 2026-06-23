#version 120

varying vec4  color;
varying vec2  texCoord;
varying vec2  lightCoord;
varying float v_realDepth; // profondeur NDC réelle de l'entité, mappée en [0,1]

void main() {
    vec4 pos = ftransform();

    // Sauvegarde de la vraie profondeur NDC → [0,1] pour le depth buffer
    v_realDepth = pos.z / pos.w * 0.5 + 0.5;

    // -------------------------------------------------------
    // TRICK THROUGH-WALL :
    // On ramène tous les sommets au plan proche (NDC z = -1)
    // → le depth test passe TOUJOURS, même si l'entité est
    //   derrière un bloc opaque.
    // La vraie profondeur est sauvegardée dans v_realDepth et
    // restaurée via gl_FragDepth dans le fragment shader.
    // -------------------------------------------------------
    pos.z = -pos.w;
    gl_Position = pos;

    texCoord   = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    color      = gl_Color;
}
