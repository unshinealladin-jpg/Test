#version 120

uniform sampler2D texture;
uniform int  entityId;    // ID de l'entité fourni par OptiFine
uniform vec4 entityColor; // Tint (ex: flash rouge lors des dégâts)

varying vec4  color;
varying vec2  texCoord;
varying float v_realDepth;

/* DRAWBUFFERS:1 */
// On n'écrit PAS dans colortex0 : la scène principale reste terrain-seulement.
// Toutes les données ESP vont dans colortex1.

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
    // Application du tint (flash de dégâts etc.)
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
    if (albedo.a < 0.1) discard;

    // Détermination du type ESP
    float isPlayer  = (entityId == 1)      ? 1.0 : 0.0;
    float isEnemy   = isHostile(entityId)  ? 1.0 : 0.0;
    // Tout ce qui n'est ni joueur ni hostile = neutre (animaux, villageois…)
    float isNeutral = (isPlayer < 0.5 && isEnemy < 0.5) ? 1.0 : 0.0;

    // colortex1 :
    //   r = 1.0 si joueur        → glow bleu dans composite
    //   g = 1.0 si hostile       → glow rouge
    //   b = 1.0 si neutre        → glow vert
    //   a = profondeur réelle [0,1] → comparée à la profondeur terrain dans composite1
    gl_FragData[0] = vec4(isPlayer, isEnemy, isNeutral, v_realDepth);

    // Restaure la vraie profondeur dans le depth buffer.
    // Sans ça, le near-plane trick laisserait z=0 partout et casserait
    // le rendu de l'eau et de la main du joueur qui viennent après.
    gl_FragDepth = v_realDepth;
}
