#version 120

// --- Passe 2 : Blur gaussien VERTICAL + Application du glow ESP ---
//
// Entrées :
//   colortex0  = scène rendue normalement
//   colortex1  = masque ESP (pixels d'entités non-floutés)
//   colortex2  = masque ESP après blur horizontal (composite.fsh)
//
// Le blur vertical est appliqué sur colortex2.
// Le glow final = couleur ESP × intensité du blur gaussien 2D.
// Le pixel de la scène ET le pixel d'entité reçoivent le glow.

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform float viewHeight;

varying vec2 texCoord;

/* DRAWBUFFERS:0 */

const float BLUR_RADIUS = 4.0;

const float GAUSS[9] = float[9](
    0.0162, 0.0540, 0.1216, 0.1946, 0.2270,
    0.1946, 0.1216, 0.0540, 0.0162
);

// Couleurs ESP (RGB)
const vec3 COLOR_PLAYER  = vec3(0.10, 0.55, 1.00); // Bleu vif
const vec3 COLOR_HOSTILE = vec3(1.00, 0.10, 0.10); // Rouge vif
const vec3 COLOR_NEUTRAL = vec3(0.10, 1.00, 0.25); // Vert vif

// Intensité du glow (plus élevé = glow plus lumineux)
const float GLOW_STRENGTH = 2.8;

void main() {
    // --- Blur vertical sur colortex2 ---
    float texelH = BLUR_RADIUS / viewHeight;
    vec3  blurMask = vec3(0.0);

    for (int i = 0; i < 9; i++) {
        float offset = float(i - 4) * texelH;
        vec2  uv     = texCoord + vec2(0.0, offset);
        blurMask    += texture2D(colortex2, uv).rgb * GAUSS[i];
    }

    // blurMask.r = intensité glow joueur
    // blurMask.g = intensité glow hostile
    // blurMask.b = intensité glow neutre

    // --- Couleur de glow composite ---
    vec3 glowColor = blurMask.r * COLOR_PLAYER
                   + blurMask.g * COLOR_HOSTILE
                   + blurMask.b * COLOR_NEUTRAL;

    float glowAlpha = max(blurMask.r, max(blurMask.g, blurMask.b));

    // --- Masque brut (pixel d'entité exact, non flouté) ---
    // Utilisé pour coloriser l'entité elle-même (pas juste le halo)
    vec3 rawMask = texture2D(colortex1, texCoord).rgb;
    float isEntityPixel = max(rawMask.r, max(rawMask.g, rawMask.b));

    vec3 entityDirectColor = rawMask.r * COLOR_PLAYER
                           + rawMask.g * COLOR_HOSTILE
                           + rawMask.b * COLOR_NEUTRAL;

    // --- Scène originale ---
    vec4 scene = texture2D(colortex0, texCoord);

    // --- Composition finale ---
    // 1. Sur les pixels d'entité : teinte légère avec la couleur ESP
    // 2. Partout : ajout du glow additif (halo)
    vec3 finalColor = scene.rgb;

    // Teinte l'entité elle-même (50% couleur ESP, 50% couleur originale)
    if (isEntityPixel > 0.5) {
        finalColor = mix(scene.rgb, entityDirectColor, 0.45);
    }

    // Ajout du halo de glow (additif)
    finalColor += glowColor * glowAlpha * GLOW_STRENGTH;

    gl_FragData[0] = vec4(finalColor, scene.a);
}
