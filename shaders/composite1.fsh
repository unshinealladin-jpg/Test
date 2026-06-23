#version 120

// --- Passe composite 2/2 : Blur vertical + ESP through-wall + Contour joueurs ---
//
// Entrées :
//   colortex0  = scène terrain/eau/main (sans entités)
//   colortex1  = données entités (r=joueur, g=hostile, b=neutre, a=profondeur réelle)
//   colortex2  = profondeur terrain (r = gl_FragCoord.z)
//   colortex3  = masque entités après blur horizontal

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform float viewWidth;
uniform float viewHeight;

varying vec2 texCoord;

/* DRAWBUFFERS:0 */

// ---- Paramètres du blur de glow ----
const float BLUR_RADIUS = 6.0;
const float GAUSS[9] = float[9](
    0.0162, 0.0540, 0.1216, 0.1946, 0.2270,
    0.1946, 0.1216, 0.0540, 0.0162
);

// ---- Couleurs ESP ----
const vec3 COLOR_PLAYER  = vec3(0.10, 0.55, 1.00); // Bleu
const vec3 COLOR_HOSTILE = vec3(1.00, 0.10, 0.10); // Rouge
const vec3 COLOR_NEUTRAL = vec3(0.10, 1.00, 0.25); // Vert

// Couleur du contour joueur (blanc-bleu très vif pour le voir à travers les murs)
const vec3 COLOR_OUTLINE = vec3(0.20, 0.80, 1.00);

// ---- Paramètres réglables ----
const float GLOW_STRENGTH      = 2.5;
const float VISIBLE_TINT       = 0.45;
const float GHOST_OPACITY      = 0.30; // fill ghost derrière les murs
const float OUTLINE_OPACITY    = 1.00; // contour toujours plein
const float OUTLINE_WIDTH      = 2.0;  // épaisseur du contour en pixels
const float DEPTH_BIAS         = 0.002;

void main() {

    float texW = OUTLINE_WIDTH / viewWidth;
    float texH = OUTLINE_WIDTH / viewHeight;

    // ---- Blur vertical (glow) ----
    float texelH  = BLUR_RADIUS / viewHeight;
    vec3  glowMask = vec3(0.0);
    for (int i = 0; i < 9; i++) {
        float off = float(i - 4) * texelH;
        glowMask += texture2D(colortex3, texCoord + vec2(0.0, off)).rgb * GAUSS[i];
    }

    // ---- Scène principale ----
    vec4 scene = texture2D(colortex0, texCoord);

    // ---- Données ESP pixel courant ----
    vec4  entityData  = texture2D(colortex1, texCoord);
    float maskSum     = entityData.r + entityData.g + entityData.b;
    bool  hasEntity   = (maskSum > 0.01);
    float entityDepth = entityData.a;

    // ---- Profondeur terrain pixel courant ----
    float terrainDepth = texture2D(colortex2, texCoord).r;
    if (terrainDepth < 0.001) terrainDepth = 1.0; // ciel = far

    // ---- Détection de contour JOUEUR ----
    // Un pixel est un bord joueur si :
    //   - il n'est PAS lui-même un pixel joueur (entityData.r < 0.5)
    //   - au moins un de ses 8 voisins EST un pixel joueur
    // Le contour est dessiné MÊME à travers les murs (grâce au near-plane trick,
    // colortex1 contient tous les pixels joueur y compris derrière les blocs).

    float isPlayerPixel = entityData.r;

    float maxNeighborPlayer = 0.0;
    float neighborEntityDepth = 0.0; // profondeur du pixel joueur voisin le plus proche
    float neighborTerrainDepth = 1.0;

    // 8 voisins en croix + diagonales
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
        vec2  uv          = texCoord + dirs[i];
        vec4  neighborESP = texture2D(colortex1, uv);
        float neighborP   = neighborESP.r;

        if (neighborP > maxNeighborPlayer) {
            maxNeighborPlayer    = neighborP;
            neighborEntityDepth  = neighborESP.a;
            neighborTerrainDepth = texture2D(colortex2, uv).r;
            if (neighborTerrainDepth < 0.001) neighborTerrainDepth = 1.0;
        }
    }

    // Ce pixel est-il un contour joueur ?
    bool isOutline = (isPlayerPixel < 0.5 && maxNeighborPlayer > 0.5);

    // Le joueur voisin est-il derrière un mur ?
    bool outlineBehindWall = isOutline &&
                             (neighborEntityDepth > neighborTerrainDepth + DEPTH_BIAS);

    // ---- Couleurs ESP ----
    vec3 espColor = entityData.r * COLOR_PLAYER
                  + entityData.g * COLOR_HOSTILE
                  + entityData.b * COLOR_NEUTRAL;

    vec3 glowColor = glowMask.r * COLOR_PLAYER
                   + glowMask.g * COLOR_HOSTILE
                   + glowMask.b * COLOR_NEUTRAL;
    float glowIntensity = max(glowMask.r, max(glowMask.g, glowMask.b));

    // ---- Composition finale ----
    vec3 finalColor = scene.rgb;

    if (isOutline) {
        // --- Contour joueur ---
        if (outlineBehindWall) {
            // Contour à travers un mur : plein et très vif
            finalColor = mix(scene.rgb, COLOR_OUTLINE, OUTLINE_OPACITY);
        } else {
            // Contour sur entité visible : plein
            finalColor = mix(scene.rgb, COLOR_OUTLINE, OUTLINE_OPACITY);
        }
    } else if (hasEntity) {
        // --- Fill de l'entité ---
        bool behindWall = (entityDepth > terrainDepth + DEPTH_BIAS);

        if (behindWall) {
            // Ghost semi-transparent derrière le mur
            finalColor = mix(scene.rgb, espColor, GHOST_OPACITY);
        } else {
            // Silhouette colorée (entité visible)
            finalColor = mix(scene.rgb, espColor, VISIBLE_TINT);
        }
    }

    // Glow additif (saigne autour des coins même si l'entité est cachée)
    finalColor += glowColor * glowIntensity * GLOW_STRENGTH;

    gl_FragData[0] = vec4(finalColor, scene.a);
}
