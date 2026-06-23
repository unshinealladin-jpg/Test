#version 120

// Uniforme fourni par OptiFine : ID numérique de l'entité rendue
// Exemples 1.8.9 : 1=Joueur, 54=Zombie, 51=Skeleton, 50=Creeper,
//                  52=Spider, 56=Ghast, 58=Enderman, 64=Wither...
uniform int  entityId;
uniform vec4 entityColor; // tint de l'entité (ex: flash rouge quand touchée)

uniform sampler2D texture;
uniform sampler2D lightmap;

varying vec4  color;
varying vec2  texCoord;
varying vec2  lightCoord;

/* DRAWBUFFERS:01 */

// Retourne true si l'ID correspond à un mob hostile 1.8.9
bool isHostile(int id) {
    return (id == 50 || id == 51 || id == 52 || id == 53 ||
            id == 54 || id == 55 || id == 56 || id == 57 ||
            id == 58 || id == 59 || id == 60 || id == 61 ||
            id == 62 || id == 63 || id == 64 || id == 65 ||
            id == 66 || id == 67 || id == 68);
}

void main() {
    vec4 albedo = texture2D(texture, texCoord) * color;
    if (albedo.a < 0.1) discard;

    // Application du tint entité (flash blanc/rouge lors des dégâts)
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

    vec4 light = texture2D(lightmap, lightCoord);

    // colortex0 : rendu normal de l'entité
    gl_FragData[0] = albedo * light;

    // -------------------------------------------------------
    // colortex1 : masque ESP
    //   r = 1.0 si joueur        (glow bleu)
    //   g = 1.0 si mob hostile   (glow rouge)
    //   b = 1.0 si entité neutre (glow vert)
    //   a = 1.0 : marqueur "pixel entité"
    // -------------------------------------------------------
    float isPlayer  = (entityId == 1)           ? 1.0 : 0.0;
    float isEnemy   = isHostile(entityId)        ? 1.0 : 0.0;
    // Tout ce qui n'est ni joueur ni hostile → neutre
    float isNeutral = (isPlayer < 0.5 && isEnemy < 0.5) ? 1.0 : 0.0;

    gl_FragData[1] = vec4(isPlayer, isEnemy, isNeutral, 1.0);
}
