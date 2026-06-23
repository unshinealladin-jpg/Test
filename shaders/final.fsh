#version 120

uniform sampler2D colortex0;

varying vec2 texCoord;

void main() {
    vec4 color = texture2D(colortex0, texCoord);
    // Clamp uniquement — pas de correction gamma (le pipeline Minecraft est déjà en sRGB)
    color.rgb = clamp(color.rgb, 0.0, 1.0);
    gl_FragColor = color;
}
