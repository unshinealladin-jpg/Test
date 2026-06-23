#version 120

// --- Passe finale : sortie à l'écran ---
// Légère correction gamma pour compenser la surbrillance du glow.

uniform sampler2D colortex0;

varying vec2 texCoord;

const float GAMMA = 1.0 / 2.2;

void main() {
    vec4 color = texture2D(colortex0, texCoord);

    // Correction gamma (optionnel — commenter si les couleurs semblent trop sombres)
    color.rgb = pow(clamp(color.rgb, 0.0, 1.0), vec3(GAMMA));

    gl_FragColor = color;
}
