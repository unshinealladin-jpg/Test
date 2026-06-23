#version 120

uniform sampler2D colortex0;

varying vec2 texCoord;

void main() {
    vec4 color = texture2D(colortex0, texCoord);
    // Légère correction gamma pour compenser la surbrillance du glow additif
    color.rgb = pow(clamp(color.rgb, 0.0, 1.0), vec3(1.0 / 2.2));
    gl_FragColor = color;
}
