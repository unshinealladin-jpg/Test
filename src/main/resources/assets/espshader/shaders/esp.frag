#version 120

// Fragment shader ESP - colorise l'entité avec la couleur ESP choisie
uniform vec4  espColor;     // Couleur RGBA de l'ESP (définie par le mod Java)
uniform bool  fillMode;     // true = remplissage plein, false = outline uniquement
uniform sampler2D texture;

void main() {
    vec4 texSample = texture2D(texture, gl_TexCoord[0].st);

    // Ignore les pixels transparents (évite les artefacts sur les modèles)
    if (texSample.a < 0.1) discard;

    if (fillMode) {
        // Mode remplissage : couleur ESP semi-transparente
        gl_FragColor = vec4(espColor.rgb, espColor.a * 0.35);
    } else {
        // Mode outline : couleur ESP pleine
        gl_FragColor = vec4(espColor.rgb, espColor.a);
    }
}
