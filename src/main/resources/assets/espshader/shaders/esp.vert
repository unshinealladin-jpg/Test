#version 120

// Vertex shader ESP - extrude les sommets vers l'extérieur pour créer un outline
uniform float outlineWidth;

void main() {
    // Calcul de la position en clip-space
    vec4 clipPos = gl_ModelViewProjectionMatrix * gl_Vertex;

    // Calcul de la normale en view-space pour l'extrusion
    vec3 viewNormal = normalize(gl_NormalMatrix * gl_Normal);

    // Offset en NDC pour créer l'effet d'outline
    vec2 offset = viewNormal.xy * outlineWidth * clipPos.w * 0.01;
    clipPos.xy += offset;

    gl_Position    = clipPos;
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_FrontColor  = gl_Color;
}
