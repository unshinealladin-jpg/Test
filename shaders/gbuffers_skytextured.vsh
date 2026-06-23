#version 120

varying vec4 color;
varying vec2 texCoord;

void main() {
    gl_Position = ftransform();
    texCoord    = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    color       = gl_Color;
}
