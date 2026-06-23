#version 120

// --- Passe composite 2/2 : Blur vertical + Application ESP through-wall ---
//
// Entrées :
//   colortex0  = scène terrain/eau/main (PAS d'entités)
//   colortex1  = données entités (r=joueur, g=hostile, b=neutre, a=profondeur réelle)
//   colortex2  = profondeur du terrain (r = gl_FragCoord.z de la passe terrain)
//   colortex3  = masque entités après blur horizontal (composite.fsh)
//
// Logique through-wall :
//   entityDepth  = profondeur réelle de l'entité (stockée dans colortex1.a)
//   terrainDepth = profondeur du terrain à ce pixel (colortex2.r)
//
//   Si entityDepth > terrainDepth + seuil  → entité DERRIÈRE un mur  → ghost semi-transparent
//   Sinon                                  → entité VISIBLE normalement → silhouette colorée

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform float viewHeight;

varying vec2 texCoord;

/* DRAWBUFFERS:0 */

const float BLUR_RADIUS = 6.0;

const float GAUSS[9] = float[9](
    0.0162, 0.0540, 0.1216, 0.1946, 0.2270,
    0.1946, 0.1216, 0.0540, 0.0162
);

// ---- Couleurs ESP ----
const vec3 COLOR_PLAYER  = vec3(0.10, 0.55, 1.00); // Bleu
const vec3 COLOR_HOSTILE = vec3(1.00, 0.10, 0.10); // Rouge
const vec3 COLOR_NEUTRAL = vec3(0.10, 1.00, 0.25); // Vert

// ---- Paramètres réglables ----
const float GLOW_STRENGTH       = 3.0;  // Intensité du halo lumineux
const float VISIBLE_TINT        = 0.50; // Mix ESP sur entité visible  (0=transparent 1=plein)
const float GHOST_OPACITY       = 0.40; // Opacité de l'entité derrière un mur
const float DEPTH_BIAS          = 0.002; // Seuil pour éviter le z-fighting

void main() {
    // --- Blur vertical sur colortex3 (h-blurred mask) ---
    float texelH  = BLUR_RADIUS / viewHeight;
    vec3  glowMask = vec3(0.0);

    for (int i = 0; i < 9; i++) {
        float offset = float(i - 4) * texelH;
        glowMask += texture2D(colortex3, texCoord + vec2(0.0, offset)).rgb * GAUSS[i];
    }

    // --- Scène principale (terrain + eau + main, sans entités) ---
    vec4 scene = texture2D(colortex0, texCoord);

    // --- Données ESP de l'entité à ce pixel ---
    vec4  entityData  = texture2D(colortex1, texCoord);
    float maskSum     = entityData.r + entityData.g + entityData.b;
    bool  hasEntity   = (maskSum > 0.01);
    float entityDepth = entityData.a; // profondeur réelle [0,1]

    // --- Profondeur du terrain à ce pixel ---
    float terrainDepth = texture2D(colortex2, texCoord).r;
    // Pixel ciel (non écrit par le terrain) → traité comme far plane
    if (terrainDepth < 0.001) terrainDepth = 1.0;

    // --- Couleur ESP pour ce pixel ---
    vec3 espColor = entityData.r * COLOR_PLAYER
                  + entityData.g * COLOR_HOSTILE
                  + entityData.b * COLOR_NEUTRAL;

    // --- Couleur du glow (basée sur le masque flouté) ---
    vec3  glowColor     = glowMask.r * COLOR_PLAYER
                        + glowMask.g * COLOR_HOSTILE
                        + glowMask.b * COLOR_NEUTRAL;
    float glowIntensity = max(glowMask.r, max(glowMask.g, glowMask.b));

    // --- Composition finale ---
    vec3 finalColor = scene.rgb;

    if (hasEntity) {
        bool behindWall = (entityDepth > terrainDepth + DEPTH_BIAS);

        if (behindWall) {
            // Entité DERRIÈRE un mur : ghost semi-transparent coloré
            // Le terrain (mur) reste visible en dessous
            finalColor = mix(scene.rgb, espColor, GHOST_OPACITY);
        } else {
            // Entité VISIBLE : silhouette teintée avec la couleur ESP
            finalColor = mix(scene.rgb, espColor, VISIBLE_TINT);
        }
    }

    // Halo de glow additif (visible même autour des entités partiellement cachées)
    finalColor += glowColor * glowIntensity * GLOW_STRENGTH;

    gl_FragData[0] = vec4(finalColor, scene.a);
}
