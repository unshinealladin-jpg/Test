#version 120

varying vec4  color;
varying vec2  texCoord;
varying vec2  lightCoord;
varying float eyeDepth; // profondeur en espace œil (pour usage futur)

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightCoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    color       = gl_Color;
    eyeDepth    = -(gl_ModelViewMatrix * gl_Vertex).z;
}
