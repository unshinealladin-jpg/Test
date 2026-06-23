#version 120

uniform sampler2D texture;

varying vec4 color;
varying vec2 texCoord;

/* DRAWBUFFERS:02 */

void main() {
    gl_FragData[0] = texture2D(texture, texCoord) * color;
    gl_FragData[1] = vec4(1.0); // ciel = profondeur far (1.0)
}
