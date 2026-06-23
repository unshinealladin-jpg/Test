#version 120

// --- Composite : contour ESP autour des entités ---
//
// Entrées :
//   colortex0 = scène complète (terrain + entités déjà teintées par gbuffers_entities)
//   colortex1 = masque ESP (r=joueur, g=hostile, b=neutre)
//
// Le masque a été écrit avec le near-plane trick, donc il couvre les
// entités même derrière les murs. On détecte les bords du masque pour
// tracer un contour net autour de chaque entité.

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texCoord;

/* DRAWBUFFERS:0 */

// ---- Couleurs ESP (identiques à gbuffers_entities) ----
const vec3 COLOR_PLAYER  = vec3(0.20, 0.70, 1.00); // Bleu vif
const vec3 COLOR_HOSTILE = vec3(1.00, 0.20, 0.20); // Rouge vif
const vec3 COLOR_NEUTRAL = vec3(0.20, 1.00, 0.35); // Vert vif

const float OUTLINE_WIDTH = 2.0; // épaisseur du contour en pixels

void main() {
    vec3 scene = texture2D(colortex0, texCoord).rgb;

    vec3  centerMask = texture2D(colortex1, texCoord).rgb;
    float centerSum  = centerMask.r + centerMask.g + centerMask.b;

    float texW = OUTLINE_WIDTH / viewWidth;
    float texH = OUTLINE_WIDTH / viewHeight;

    // Échantillonnage des 8 voisins pour la détection de bord
    vec3 dominant = vec3(0.0); // type dominant trouvé chez un voisin
    float neighborSum = 0.0;

    vec2 dirs[8];
    dirs[0] = vec2( texW,  0.0);
    dirs[1] = vec2(-texW,  0.0);
    dirs[2] = vec2(  0.0,  texH);
    dirs[3] = vec2(  0.0, -texH);
    dirs[4] = vec2( texW,  texH);
    dirs[5] = vec2(-texW,  texH);
    dirs[6] = vec2( texW, -texH);
    dirs[7] = vec2(-texW, -texH);

    for (int i = 0; i < 8; i++) {
        vec3  m = texture2D(colortex1, texCoord + dirs[i]).rgb;
        float s = m.r + m.g + m.b;
        if (s > neighborSum) {
            neighborSum = s;
            dominant    = m;
        }
    }

    vec3 finalColor = scene;

    // Contour : pixel hors entité mais adjacent à une entité
    if (centerSum < 0.5 && neighborSum > 0.5) {
        vec3 outlineColor = dominant.r * COLOR_PLAYER
                          + dominant.g * COLOR_HOSTILE
                          + dominant.b * COLOR_NEUTRAL;
        finalColor = outlineColor;
    }

    gl_FragData[0] = vec4(clamp(finalColor, 0.0, 1.0), 1.0);
}
