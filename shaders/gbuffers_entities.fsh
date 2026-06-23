#version 120

uniform sampler2D texture;
uniform int  entityId;    // ID de l'entité fourni par OptiFine
uniform vec4 entityColor; // Tint (ex: flash rouge lors des dégâts)

varying vec4 color;
varying vec2 texCoord;

/* DRAWBUFFERS:01 */
// colortex0 = scène : on y peint l'entité teintée (visible à travers les murs)
// colortex1 = masque ESP pour le contour dessiné dans composite

// ---- Couleurs ESP ----
const vec3 COLOR_PLAYER  = vec3(0.10, 0.55, 1.00); // Bleu
const vec3 COLOR_HOSTILE = vec3(1.00, 0.10, 0.10); // Rouge
const vec3 COLOR_NEUTRAL = vec3(0.10, 1.00, 0.25); // Vert

// Intensité de la teinte appliquée au corps de l'entité (0 = couleur réelle, 1 = couleur ESP pleine)
const float BODY_TINT = 0.55;

// IDs mobs hostiles Minecraft 1.8.9
bool isHostile(int id) {
    return (id == 50 || // Creeper
            id == 51 || // Skeleton
            id == 52 || // Spider
            id == 53 || // Giant
            id == 54 || // Zombie
            id == 55 || // Slime
            id == 56 || // Ghast
            id == 57 || // ZombiePigman
            id == 58 || // Enderman
            id == 59 || // CaveSpider
            id == 60 || // Silverfish
            id == 61 || // Blaze
            id == 62 || // MagmaCube
            id == 63 || // EnderDragon
            id == 64 || // Wither
            id == 66 || // Witch
            id == 67 || // Endermite
            id == 68);  // Guardian
}

void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
    if (albedo.a < 0.1) discard;

    // Type d'entité
    float isPlayer  = (entityId == 1)      ? 1.0 : 0.0;
    float isEnemy   = isHostile(entityId)  ? 1.0 : 0.0;
    float isNeutral = (isPlayer < 0.5 && isEnemy < 0.5) ? 1.0 : 0.0;

    vec3 espColor = isPlayer  * COLOR_PLAYER
                  + isEnemy   * COLOR_HOSTILE
                  + isNeutral * COLOR_NEUTRAL;

    // colortex0 : corps de l'entité teinté (gardant un peu de texture pour rester lisible)
    vec3 body = mix(albedo.rgb, espColor, BODY_TINT);
    gl_FragData[0] = vec4(body, albedo.a);

    // colortex1 : masque pour le contour (r=joueur, g=hostile, b=neutre)
    gl_FragData[1] = vec4(isPlayer, isEnemy, isNeutral, 1.0);

    // PAS de gl_FragDepth : on laisse la profondeur au plan proche
    // pour que l'entité reste visible à travers les murs.
}
